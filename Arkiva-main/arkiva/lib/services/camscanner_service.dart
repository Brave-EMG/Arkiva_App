import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Point pour les coordonnées
class ScanPoint {
  final int x;
  final int y;
  
  ScanPoint(this.x, this.y);
}

/// Rectangle pour la détection
class ScanRectangle {
  final int x;
  final int y;
  final int width;
  final int height;
  
  ScanRectangle(this.x, this.y, this.width, this.height);
}

/// Résultat du scan CamScanner
class CamScannerResult {
  final File originalImage;
  final File processedImage;
  final String ocrText;
  final ScanQuality quality;
  final ScanRectangle? detectedBounds;
  final DateTime timestamp;

  CamScannerResult({
    required this.originalImage,
    required this.processedImage,
    required this.ocrText,
    required this.quality,
    this.detectedBounds,
    required this.timestamp,
  });
}

/// Qualité du scan
enum ScanQuality {
  excellent,
  good,
  fair,
  poor,
}

/// Service CamScanner exact
class CamScannerService {
  static final CamScannerService _instance = CamScannerService._internal();
  factory CamScannerService() => _instance;
  CamScannerService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Processus CamScanner complet
  Future<CamScannerResult> processDocumentScan(File originalImage) async {
    try {
      // 1. Détecter automatiquement les bordures
      final detectedBounds = await _detectDocumentBounds(originalImage);
      
      // 2. Redimensionner automatiquement selon les bordures
      final resizedImage = await _resizeDocument(originalImage, detectedBounds);
      
      // 3. Améliorer le texte (comme CamScanner)
      final enhancedImage = await _enhanceText(resizedImage);
      
      // 4. OCR pour évaluer la qualité
      final ocrText = await _performOCR(enhancedImage);
      
      // 5. Évaluer la qualité
      final quality = _assessQuality(enhancedImage, ocrText);
      
      return CamScannerResult(
        originalImage: originalImage,
        processedImage: enhancedImage,
        ocrText: ocrText,
        quality: quality,
        detectedBounds: detectedBounds,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur CamScanner: $e');
      rethrow;
    }
  }

  /// Détection automatique des bordures du document
  Future<ScanRectangle?> _detectDocumentBounds(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Détection des bords avec algorithme CamScanner
      final edges = _detectEdges(image);
      if (edges.isEmpty) return null;

      // Trouver le plus grand rectangle (document)
      ScanRectangle? bestDocument;
      double maxArea = 0;

      for (final edge in edges) {
        final area = edge.width * edge.height;
        if (area > maxArea && _isValidDocument(edge, image)) {
          maxArea = area.toDouble();
          bestDocument = edge;
        }
      }

      return bestDocument;
    } catch (e) {
      debugPrint('Erreur détection bordures: $e');
      return null;
    }
  }

  /// Détection des bords CamScanner
  List<ScanRectangle> _detectEdges(img.Image image) {
    final edges = <ScanRectangle>[];
    final width = image.width;
    final height = image.height;

    // Algorithme de détection de bords CamScanner
    for (int y = 5; y < height - 5; y++) {
      for (int x = 5; x < width - 5; x++) {
        // Calcul du gradient CamScanner
        final gradient = _calculateGradient(image, x, y);
        
        if (gradient > 0.15) { // Seuil CamScanner
          // Créer un rectangle de détection
          final rectSize = 50;
          final rectX = (x - rectSize ~/ 2).clamp(0, width - rectSize);
          final rectY = (y - rectSize ~/ 2).clamp(0, height - rectSize);
          
          edges.add(ScanRectangle(rectX, rectY, rectSize, rectSize));
        }
      }
    }

    // Fusionner les rectangles proches
    return _mergeRectangles(edges);
  }

  /// Calcul du gradient CamScanner
  double _calculateGradient(img.Image image, int x, int y) {
    final center = image.getPixel(x, y);
    
    // Voisins pour calcul du gradient
    final neighbors = [
      image.getPixel(x - 2, y),
      image.getPixel(x + 2, y),
      image.getPixel(x, y - 2),
      image.getPixel(x, y + 2),
    ];
    
    double gradient = 0;
    for (final neighbor in neighbors) {
      gradient += (center.r - neighbor.r).abs() +
                  (center.g - neighbor.g).abs() +
                  (center.b - neighbor.b).abs();
    }
    
    return gradient / (neighbors.length * 255);
  }

  /// Fusion des rectangles
  List<ScanRectangle> _mergeRectangles(List<ScanRectangle> rectangles) {
    if (rectangles.isEmpty) return [];
    
    final merged = <ScanRectangle>[];
    final used = <bool>[];
    for (int i = 0; i < rectangles.length; i++) {
      used.add(false);
    }
    
    for (int i = 0; i < rectangles.length; i++) {
      if (used[i]) continue;
      
      ScanRectangle current = rectangles[i];
      used[i] = true;
      
      for (int j = i + 1; j < rectangles.length; j++) {
        if (used[j]) continue;
        
        final other = rectangles[j];
        final distance = _calculateDistance(current, other);
        
        if (distance < 100) { // Seuil de fusion CamScanner
          current = _mergeTwoRectangles(current, other);
          used[j] = true;
        }
      }
      
      merged.add(current);
    }
    
    return merged;
  }

  /// Calcul de distance entre rectangles
  double _calculateDistance(ScanRectangle r1, ScanRectangle r2) {
    final center1X = r1.x + r1.width ~/ 2;
    final center1Y = r1.y + r1.height ~/ 2;
    final center2X = r2.x + r2.width ~/ 2;
    final center2Y = r2.y + r2.height ~/ 2;
    
    return ((center1X - center2X) * (center1X - center2X) + 
            (center1Y - center2Y) * (center1Y - center2Y)).toDouble();
  }

  /// Fusion de deux rectangles
  ScanRectangle _mergeTwoRectangles(ScanRectangle r1, ScanRectangle r2) {
    final minX = r1.x < r2.x ? r1.x : r2.x;
    final minY = r1.y < r2.y ? r1.y : r2.y;
    final maxX = (r1.x + r1.width) > (r2.x + r2.width) ? 
                  (r1.x + r1.width) : (r2.x + r2.width);
    final maxY = (r1.y + r1.height) > (r2.y + r2.height) ? 
                  (r1.y + r1.height) : (r2.y + r2.height);
    
    return ScanRectangle(minX, minY, maxX - minX, maxY - minY);
  }

  /// Validation du document
  bool _isValidDocument(ScanRectangle rect, img.Image image) {
    final ratio = rect.width / rect.height;
    
    // Critères CamScanner
    if (ratio < 0.5 || ratio > 2.0) {
      return false;
    }
    
    // Taille minimale
    final minArea = image.width * image.height * 0.05; // 5% de l'image
    final area = rect.width * rect.height;
    
    return area >= minArea;
  }

  /// Redimensionnement automatique selon les bordures
  Future<File> _resizeDocument(File originalImage, ScanRectangle? bounds) async {
    try {
      final bytes = await originalImage.readAsBytes();
      img.Image image = img.decodeImage(bytes)!;

      if (bounds != null) {
        // Découper selon les bordures détectées
        image = img.copyCrop(
          image,
          x: bounds.x,
          y: bounds.y,
          width: bounds.width,
          height: bounds.height,
        );
      }

      // Redimensionner au format A4 (ratio 1.414)
      final targetWidth = 800;
      final targetHeight = (targetWidth / 1.414).round();
      
      image = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      // Sauvegarder
      final tempDir = await getTemporaryDirectory();
      final resizedPath = '${tempDir.path}/camscanner_resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final resizedBytes = img.encodeJpg(image, quality: 95);
      final resizedFile = File(resizedPath);
      await resizedFile.writeAsBytes(resizedBytes);

      return resizedFile;
    } catch (e) {
      debugPrint('Erreur redimensionnement: $e');
      return originalImage;
    }
  }

  /// Amélioration du texte (comme CamScanner)
  Future<File> _enhanceText(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image image = img.decodeImage(bytes)!;

      // Pipeline d'amélioration CamScanner
      image = _enhanceContrast(image);
      image = _reduceNoise(image);
      image = _sharpenText(image);
      image = _optimizeForOCR(image);

      // Sauvegarder
      final tempDir = await getTemporaryDirectory();
      final enhancedPath = '${tempDir.path}/camscanner_enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final enhancedBytes = img.encodeJpg(image, quality: 95);
      final enhancedFile = File(enhancedPath);
      await enhancedFile.writeAsBytes(enhancedBytes);

      return enhancedFile;
    } catch (e) {
      debugPrint('Erreur amélioration texte: $e');
      return imageFile;
    }
  }

  /// Amélioration du contraste (texte ressorti)
  img.Image _enhanceContrast(img.Image image) {
    return img.adjustColor(image, 
      contrast: 1.4,    // Contraste fort pour ressortir le texte
      brightness: 1.1,  // Légèrement plus lumineux
      saturation: 1.2,  // Garder les couleurs
    );
  }

  /// Réduction de bruit
  img.Image _reduceNoise(img.Image image) {
    // Pour l'instant, retourner l'image sans modification
    return image;
  }

  /// Amélioration de la netteté du texte
  img.Image _sharpenText(img.Image image) {
    // Pour l'instant, retourner l'image sans modification
    return image;
  }

  /// Optimisation pour OCR
  img.Image _optimizeForOCR(img.Image image) {
    return img.adjustColor(image, 
      contrast: 1.3,
      brightness: 1.05,
      saturation: 1.1,
    );
  }

  /// OCR pour évaluer la qualité
  Future<String> _performOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += line.text + '\n';
        }
      }
      
      return extractedText.trim();
    } catch (e) {
      debugPrint('Erreur OCR: $e');
      return '';
    }
  }

  /// Évaluation de la qualité
  ScanQuality _assessQuality(File enhancedImage, String ocrText) {
    if (ocrText.length > 200) {
      return ScanQuality.excellent;
    } else if (ocrText.length > 100) {
      return ScanQuality.good;
    } else if (ocrText.length > 50) {
      return ScanQuality.fair;
    } else {
      return ScanQuality.poor;
    }
  }
} 