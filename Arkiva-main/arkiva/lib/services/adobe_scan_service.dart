import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AdobeScanService {
  static final AdobeScanService _instance = AdobeScanService._internal();
  factory AdobeScanService() => _instance;
  AdobeScanService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // Configuration Adobe Scan-like
  static const double _edgeDetectionThreshold = 0.1; // Seuil de détection des bords

  /// Détecte automatiquement les bords d'un document dans l'image
  Future<Rectangle?> detectDocumentEdges(CameraImage image) async {
    try {
      // Convertir l'image de la caméra en format utilisable
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Créer une image à partir des bytes
      final img.Image? cameraImage = img.decodeImage(bytes);
      if (cameraImage == null) return null;

      // Détecter les contours
      final edges = _detectEdges(cameraImage);
      if (edges.isEmpty) return null;

      // Trouver le plus grand rectangle (probablement le document)
      Rectangle? bestRectangle;
      double maxArea = 0;

      for (final edge in edges) {
        final area = edge.width * edge.height;
        if (area > maxArea && _isValidDocumentRatio(edge, cameraImage)) {
          maxArea = area.toDouble();
          bestRectangle = edge;
        }
      }

      return bestRectangle;
    } catch (e) {
      debugPrint('Erreur lors de la détection des bords: $e');
      return null;
    }
  }

  /// Vérifie si le rectangle détecté a un ratio valide pour un document
  bool _isValidDocumentRatio(Rectangle rect, img.Image image) {
    final rectRatio = rect.width / rect.height;
    
    // Un document typique a un ratio entre 0.5 (A4 portrait) et 2.0 (A4 paysage)
    return rectRatio >= 0.5 && rectRatio <= 2.0;
  }

  /// Détecte les contours dans l'image
  List<Rectangle> _detectEdges(img.Image image) {
    // Algorithme simplifié de détection de contours
    final edges = <Rectangle>[];
    
    // Convertir en niveaux de gris
    final gray = img.grayscale(image);
    
    // Appliquer un filtre de détection de contours (Sobel simplifié)
    final width = gray.width;
    final height = gray.height;
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final pixel = gray.getPixel(x, y);
        final neighbors = [
          gray.getPixel(x - 1, y),
          gray.getPixel(x + 1, y),
          gray.getPixel(x, y - 1),
          gray.getPixel(x, y + 1),
        ];
        
        // Calculer la différence avec les voisins
        double gradient = 0;
        for (final neighbor in neighbors) {
          gradient += (pixel.r - neighbor.r).abs() + 
                     (pixel.g - neighbor.g).abs() + 
                     (pixel.b - neighbor.b).abs();
        }
        
        // Si le gradient est élevé, c'est probablement un bord
        if (gradient > _edgeDetectionThreshold * 255 * 4) {
          // Ajouter un rectangle autour de ce point
          edges.add(Rectangle(x - 10, y - 10, 20, 20));
        }
      }
    }
    
    return edges;
  }

  /// Améliore automatiquement la qualité de l'image (comme Adobe Scan)
  Future<File> enhanceImage(File originalImage) async {
    try {
      // Lire l'image
      final bytes = await originalImage.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Impossible de décoder l\'image');

      // 1. Correction automatique de la perspective
      image = _correctPerspective(image);

      // 2. Amélioration du contraste
      image = _enhanceContrast(image);

      // 3. Suppression du bruit
      image = _denoise(image);

      // 4. Amélioration de la netteté
      image = _sharpen(image);

      // 5. Optimisation pour l'OCR
      image = _optimizeForOCR(image);

      // Sauvegarder l'image améliorée
      final tempDir = await getTemporaryDirectory();
      final enhancedPath = '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final enhancedBytes = img.encodeJpg(image, quality: 95);
      final enhancedFile = File(enhancedPath);
      await enhancedFile.writeAsBytes(enhancedBytes);

      return enhancedFile;
    } catch (e) {
      debugPrint('Erreur lors de l\'amélioration de l\'image: $e');
      return originalImage; // Retourner l'original en cas d'erreur
    }
  }

  /// Correction automatique de la perspective
  img.Image _correctPerspective(img.Image image) {
    // Algorithme simplifié de correction de perspective
    // Dans une vraie implémentation, on utiliserait la détection de quadrilatères
    
    // Pour l'instant, on retourne l'image telle quelle
    // TODO: Implémenter la correction de perspective
    return image;
  }

  /// Amélioration du contraste
  img.Image _enhanceContrast(img.Image image) {
    // Augmenter le contraste de 50%
    return img.adjustColor(image, contrast: 1.5);
  }

  /// Suppression du bruit
  img.Image _denoise(img.Image image) {
    // Pour l'instant, on retourne l'image telle quelle
    // TODO: Implémenter la suppression de bruit
    return image;
  }

  /// Amélioration de la netteté
  img.Image _sharpen(img.Image image) {
    // Pour l'instant, on retourne l'image telle quelle
    // TODO: Implémenter l'amélioration de netteté
    return image;
  }

  /// Optimisation pour l'OCR
  img.Image _optimizeForOCR(img.Image image) {
    // Conversion en noir et blanc pour améliorer l'OCR
    final gray = img.grayscale(image);
    
    // Seuillage adaptatif pour améliorer la lisibilité
    return img.adjustColor(gray, brightness: 1.2);
  }

  /// Effectue l'OCR sur l'image
  Future<String> performOCR(File imageFile) async {
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
      debugPrint('Erreur lors de l\'OCR: $e');
      return '';
    }
  }

  /// Processus complet Adobe Scan-like
  Future<ScanResult> processDocumentScan(File originalImage) async {
    try {
      // 1. Amélioration automatique de l'image
      final enhancedImage = await enhanceImage(originalImage);
      
      // 2. OCR automatique
      final ocrText = await performOCR(enhancedImage);
      
      // 3. Créer le résultat
      return ScanResult(
        originalImage: originalImage,
        enhancedImage: enhancedImage,
        ocrText: ocrText,
        scanQuality: _assessScanQuality(enhancedImage, ocrText),
      );
    } catch (e) {
      debugPrint('Erreur lors du traitement Adobe Scan: $e');
      rethrow;
    }
  }

  /// Évalue la qualité du scan
  ScanQuality _assessScanQuality(File enhancedImage, String ocrText) {
    // Logique simplifiée d'évaluation de la qualité
    if (ocrText.length > 100) {
      return ScanQuality.excellent;
    } else if (ocrText.length > 50) {
      return ScanQuality.good;
    } else if (ocrText.length > 10) {
      return ScanQuality.fair;
    } else {
      return ScanQuality.poor;
    }
  }

  /// Demande les permissions nécessaires
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    
    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Résultat du scan Adobe Scan-like
class ScanResult {
  final File originalImage;
  final File enhancedImage;
  final String ocrText;
  final ScanQuality scanQuality;

  ScanResult({
    required this.originalImage,
    required this.enhancedImage,
    required this.ocrText,
    required this.scanQuality,
  });
}

/// Qualité du scan
enum ScanQuality {
  excellent,
  good,
  fair,
  poor,
}

/// Rectangle pour la détection de bords
class Rectangle {
  final int x;
  final int y;
  final int width;
  final int height;

  Rectangle(this.x, this.y, this.width, this.height);
} 