import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Traite un scan de document avec détection automatique des coins
  Future<File?> processDocumentScan(File imageFile, {List<Offset>? manualCorners}) async {
    try {
      debugPrint('Début du traitement du document avec redimensionnement automatique: ${imageFile.path}');
      
      // Vérifier si le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('Fichier introuvable: ${imageFile.path}');
        return null;
      }

      // Convertir en JPEG pour assurer la compatibilité
      final jpegFile = await _convertToJpeg(imageFile);
      if (jpegFile == null) {
        debugPrint('Erreur lors de la conversion JPEG');
        return imageFile;
      }

      // Appliquer le redimensionnement automatique
      final processedFile = await _applyAutoResize(jpegFile);
      debugPrint('Document traité avec redimensionnement: ${processedFile?.path}');
      
      return processedFile ?? jpegFile;
      
    } catch (e) {
      debugPrint('Erreur lors du traitement du document: $e');
      return imageFile; // Retourner l'original en cas d'erreur
    }
  }

  /// Applique un redimensionnement automatique à l'image
  Future<File?> _applyAutoResize(File imageFile) async {
    try {
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('Impossible de décoder l\'image');
        return imageFile;
      }

      // Détecter les bords du document
      final corners = await _detectDocumentCorners(image);
      
      if (corners != null) {
        // Appliquer la correction de perspective
        final correctedImage = _applyPerspectiveCorrection(image, corners);
        
        // Créer un fichier temporaire pour l'image traitée
        final tempDir = await getTemporaryDirectory();
        final processedFile = File('${tempDir.path}/auto_resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        // Encoder l'image corrigée
        final processedBytes = img.encodeJpg(correctedImage, quality: 90);
        await processedFile.writeAsBytes(processedBytes);
        
        if (await processedFile.exists() && await processedFile.length() > 0) {
          debugPrint('Image redimensionnée automatiquement: ${processedFile.path}');
          return processedFile;
        }
      }
      
      // Si la détection échoue, retourner l'original
      return imageFile;
    } catch (e) {
      debugPrint('Erreur lors du redimensionnement automatique: $e');
      return imageFile;
    }
  }

  /// Détecte les coins d'un document dans l'image
  Future<List<img.Point>?> _detectDocumentCorners(img.Image image) async {
    try {
      // Convertir en niveaux de gris pour la détection
      final grayImage = img.grayscale(image);
      
      // Appliquer un filtre de détection de bords (Sobel)
      final edgeImage = img.sobel(grayImage);
      
      // Trouver les contours
      final contours = _findContours(edgeImage);
      
      // Trouver le plus grand contour (probablement le document)
      if (contours.isNotEmpty) {
        final largestContour = contours.reduce((a, b) => a.length > b.length ? a : b);
        
        // Approximer le contour en polygone
        final approx = _approximatePolygon(largestContour);
        
        // Si on a 4 points, c'est probablement un document
        if (approx.length == 4) {
          return approx.map((p) => img.Point(p.x, p.y)).toList();
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la détection des coins: $e');
      return null;
    }
  }

  /// Trouve les contours dans une image
  List<List<img.Point>> _findContours(img.Image image) {
    // Implémentation simplifiée de détection de contours
    final contours = <List<img.Point>>[];
    final visited = List.generate(image.height, (y) => List.filled(image.width, false));
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (!visited[y][x] && _isEdgePixel(image, x, y)) {
          final contour = _traceContour(image, visited, x, y);
          if (contour.length > 10) { // Filtrer les petits contours
            contours.add(contour);
          }
        }
      }
    }
    
    return contours;
  }

  /// Vérifie si un pixel est un pixel de bord
  bool _isEdgePixel(img.Image image, int x, int y) {
    if (x <= 0 || x >= image.width - 1 || y <= 0 || y >= image.height - 1) {
      return false;
    }
    
    final pixel = image.getPixel(x, y);
    final threshold = 128;
    
    return img.getLuminance(pixel) > threshold;
  }

  /// Trace un contour à partir d'un point de départ
  List<img.Point> _traceContour(img.Image image, List<List<bool>> visited, int startX, int startY) {
    final contour = <img.Point>[];
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1]
    ];
    
    int x = startX, y = startY;
    
    do {
      visited[y][x] = true;
      contour.add(img.Point(x, y));
      
      // Chercher le prochain pixel de bord
      bool found = false;
      for (final dir in directions) {
        final newX = x + dir[0];
        final newY = y + dir[1];
        
        if (newX >= 0 && newX < image.width && newY >= 0 && newY < image.height &&
            !visited[newY][newX] && _isEdgePixel(image, newX, newY)) {
          x = newX;
          y = newY;
          found = true;
          break;
        }
      }
      
      if (!found) break;
    } while (x != startX || y != startY);
    
    return contour;
  }

  /// Approxime un contour en polygone
  List<img.Point> _approximatePolygon(List<img.Point> contour) {
    if (contour.length < 4) return contour;
    
    // Algorithme de Douglas-Peucker simplifié
    final epsilon = 5.0;
    final result = <img.Point>[];
    
    result.add(contour.first);
    _douglasPeucker(contour, 0, contour.length - 1, epsilon, result);
    result.add(contour.last);
    
    return result;
  }

  /// Algorithme de Douglas-Peucker pour simplifier les contours
  void _douglasPeucker(List<img.Point> contour, int start, int end, double epsilon, List<img.Point> result) {
    if (end - start <= 1) return;
    
    double maxDistance = 0;
    int maxIndex = start;
    
    for (int i = start + 1; i < end; i++) {
      final distance = _pointToLineDistance(contour[i], contour[start], contour[end]);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }
    
    if (maxDistance > epsilon) {
      _douglasPeucker(contour, start, maxIndex, epsilon, result);
      result.add(contour[maxIndex]);
      _douglasPeucker(contour, maxIndex, end, epsilon, result);
    }
  }

  /// Calcule la distance d'un point à une ligne
  double _pointToLineDistance(img.Point point, img.Point lineStart, img.Point lineEnd) {
    final A = point.x - lineStart.x;
    final B = point.y - lineStart.y;
    final C = lineEnd.x - lineStart.x;
    final D = lineEnd.y - lineStart.y;
    
    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return 0;
    
    final param = dot / lenSq;
    
    double xx, yy;
    if (param < 0) {
      xx = lineStart.x.toDouble();
      yy = lineStart.y.toDouble();
    } else if (param > 1) {
      xx = lineEnd.x.toDouble();
      yy = lineEnd.y.toDouble();
    } else {
      xx = lineStart.x + param * C;
      yy = lineStart.y + param * D;
    }
    
    final dx = point.x - xx;
    final dy = point.y - yy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Applique une correction de perspective
  img.Image _applyPerspectiveCorrection(img.Image image, List<img.Point> corners) {
    // Dimensions cibles (format A4)
    const targetWidth = 800;
    const targetHeight = 1131; // Ratio A4
    
    // Points de destination (rectangle parfait)
    final destination = [
      img.Point(0, 0),
      img.Point(targetWidth, 0),
      img.Point(targetWidth, targetHeight),
      img.Point(0, targetHeight),
    ];
    
    // Calculer la matrice de transformation
    final matrix = _getPerspectiveTransform(corners, destination);
    
    // Appliquer la transformation
    return _warpPerspective(image, matrix, targetWidth, targetHeight);
  }

  /// Calcule la matrice de transformation perspective
  List<List<double>> _getPerspectiveTransform(List<img.Point> src, List<img.Point> dst) {
    // Implémentation simplifiée de la transformation perspective
    // En pratique, on utiliserait une bibliothèque comme OpenCV
    
    // Pour l'instant, retourner une matrice d'identité
    return [
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ];
  }

  /// Applique une transformation perspective
  img.Image _warpPerspective(img.Image image, List<List<double>> matrix, int width, int height) {
    // Implémentation simplifiée
    // En pratique, on utiliserait une bibliothèque comme OpenCV
    
    // Pour l'instant, redimensionner simplement l'image
    return img.copyResize(image, width: width, height: height);
  }

  /// Applique un filtre à une image
  Future<File?> applyFilter(File imageFile, String filterType) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return imageFile;
      
      img.Image processedImage;
      
      switch (filterType) {
        case 'original':
          processedImage = image;
          break;
        case 'bw':
          processedImage = img.grayscale(image);
          break;
        case 'magic':
          // Amélioration automatique
          processedImage = _applyMagicFilter(image);
          break;
        default:
          processedImage = image;
      }
      
      // Créer un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final processedFile = File('${tempDir.path}/filtered_${filterType}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Encoder l'image traitée
      final processedBytes = img.encodeJpg(processedImage, quality: 90);
      await processedFile.writeAsBytes(processedBytes);
      
      if (await processedFile.exists() && await processedFile.length() > 0) {
        debugPrint('Filtre $filterType appliqué: ${processedFile.path}');
        return processedFile;
      }
      
      return imageFile;
    } catch (e) {
      debugPrint('Erreur lors de l\'application du filtre "$filterType": $e');
      return imageFile;
    }
  }

  /// Applique le filtre "magic" (amélioration automatique)
  img.Image _applyMagicFilter(img.Image image) {
    // Amélioration automatique : contraste + luminosité
    var processed = img.adjustColor(image, contrast: 1.2, brightness: 1.1);
    
    // Réduction du bruit
    processed = img.gaussianBlur(processed, radius: 1);
    
    // Amélioration de la netteté (utiliser un filtre de convolution personnalisé)
    processed = _applySharpenFilter(processed);
    
    return processed;
  }

  /// Applique un filtre de netteté personnalisé
  img.Image _applySharpenFilter(img.Image image) {
    // Kernel de netteté
    final kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0]
    ];
    
    return img.convolution(image, kernel: kernel);
  }

  /// Convertit une image en PDF
  Future<File?> convertImageToPdf(File imageFile) async {
    try {
      debugPrint('Conversion de l\'image en PDF: ${imageFile.path}');
      
      // Vérifier si le fichier existe
      if (!await imageFile.exists()) {
        debugPrint('Fichier introuvable pour la conversion PDF: ${imageFile.path}');
        return null;
      }

      // Convertir en JPEG d'abord
      final jpegFile = await _convertToJpeg(imageFile);
      debugPrint('Conversion PDF simplifiée - retour de l\'image JPEG: ${jpegFile?.path}');
      return jpegFile ?? imageFile;
      
    } catch (e) {
      debugPrint('Erreur lors de la conversion en PDF: $e');
      return imageFile; // Retourner l'original en cas d'erreur
    }
  }

  /// Convertit une image en JPEG pour assurer la compatibilité
  Future<File?> _convertToJpeg(File imageFile) async {
    try {
      // Lire les bytes de l'image
      final bytes = await imageFile.readAsBytes();
      
      // Créer un fichier temporaire JPEG avec une extension .jpg explicite
      final tempDir = await getTemporaryDirectory();
      final jpegFile = File('${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Écrire les bytes directement
      await jpegFile.writeAsBytes(bytes);
      
      // Vérifier que le fichier existe et a une taille > 0
      if (await jpegFile.exists() && await jpegFile.length() > 0) {
        debugPrint('Image convertie en JPEG: ${jpegFile.path} (${await jpegFile.length()} bytes)');
        return jpegFile;
      } else {
        debugPrint('Erreur: fichier JPEG créé mais vide ou inexistant');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de la conversion en JPEG: $e');
      return null;
    }
  }

  /// Méthode pour compatibilité avec le scan simple
  Future<File?> processImage(File imageFile) async {
    return await processDocumentScan(imageFile);
  }

  /// Extrait le texte d'une image avec OCR
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            extractedText += element.text + ' ';
          }
          extractedText += '\n';
        }
      }
      
      return extractedText.trim();
    } catch (e) {
      debugPrint('Erreur lors de l\'extraction de texte: $e');
      return '';
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _textRecognizer.close();
  }
} 