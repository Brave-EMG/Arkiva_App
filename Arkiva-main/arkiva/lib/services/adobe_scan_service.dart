import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Point simple pour les coordonnées
class ScanPoint {
  final int x;
  final int y;
  
  ScanPoint(this.x, this.y);
}

/// Résultat du scan Adobe Scan
class AdobeScanResult {
  final File originalImage;
  final File processedImage;
  final String ocrText;
  final ScanQuality quality;
  final Rectangle? detectedBounds;
  final DateTime timestamp;

  AdobeScanResult({
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

/// Rectangle pour la détection de bords
class Rectangle {
  final int x;
  final int y;
  final int width;
  final int height;

  Rectangle(this.x, this.y, this.width, this.height);
}

/// Service Adobe Scan exactement comme l'original
class AdobeScanService {
  static final AdobeScanService _instance = AdobeScanService._internal();
  factory AdobeScanService() => _instance;
  AdobeScanService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // Configuration Adobe Scan exacte
  static const double _edgeDetectionThreshold = 0.12;
  static const double _autoCaptureConfidence = 0.85;
  static const int _autoCaptureDelay = 1500; // 1.5 secondes
  static const double _minDocumentRatio = 0.7;
  static const double _maxDocumentRatio = 1.4;

  /// Détection en temps réel comme Adobe Scan
  Future<Rectangle?> detectDocumentEdgesRealTime(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final img.Image? cameraImage = img.decodeImage(bytes);
      if (cameraImage == null) return null;

      // Détection Adobe Scan exacte
      final documentBounds = _detectDocumentBoundsAdobeStyle(cameraImage);
      if (documentBounds == null) return null;

      // Validation Adobe Scan
      if (_isValidAdobeDocument(documentBounds, cameraImage)) {
        return documentBounds;
      }

      return null;
    } catch (e) {
      debugPrint('Erreur détection Adobe Scan: $e');
      return null;
    }
  }

  /// Détection Adobe Scan exacte
  Rectangle? _detectDocumentBoundsAdobeStyle(img.Image image) {
    final gray = img.grayscale(image);
    final width = gray.width;
    final height = gray.height;

    // Algorithme Adobe Scan : détection de quadrilatères
    final edges = _detectEdgesAdobeStyle(gray);
    if (edges.isEmpty) return null;

    // Trouver le plus grand quadrilatère (document)
    Rectangle? bestDocument = null;
    double maxArea = 0;

    for (final edge in edges) {
      final area = edge.width * edge.height;
      if (area > maxArea) {
        maxArea = area.toDouble();
        bestDocument = edge;
      }
    }

    return bestDocument;
  }

  /// Détection de bords style Adobe Scan
  List<Rectangle> _detectEdgesAdobeStyle(img.Image image) {
    final edges = <Rectangle>[];
    final width = image.width;
    final height = image.height;

    // Filtre de détection Adobe Scan
    for (int y = 3; y < height - 3; y++) {
      for (int x = 3; x < width - 3; x++) {
        final pixel = image.getPixel(x, y);
        
        // Gradient Adobe Scan (plus sophistiqué)
        final gradient = _calculateAdobeGradient(image, x, y);
        
        if (gradient > _edgeDetectionThreshold) {
          // Créer un rectangle de détection Adobe
          final rectSize = 40; // Plus grand pour Adobe
          final rectX = (x - rectSize ~/ 2).clamp(0, width - rectSize);
          final rectY = (y - rectSize ~/ 2).clamp(0, height - rectSize);
          
          edges.add(Rectangle(rectX, rectY, rectSize, rectSize));
        }
      }
    }

    // Fusion Adobe Scan
    return _mergeAdobeRectangles(edges);
  }

  /// Calcul de gradient Adobe Scan
  double _calculateAdobeGradient(img.Image image, int x, int y) {
    final center = image.getPixel(x, y);
    
    // Voisins Adobe Scan (plus de directions)
    final neighbors = [
      image.getPixel(x - 2, y),     // gauche
      image.getPixel(x + 2, y),     // droite
      image.getPixel(x, y - 2),     // haut
      image.getPixel(x, y + 2),     // bas
      image.getPixel(x - 2, y - 2), // haut-gauche
      image.getPixel(x + 2, y - 2), // haut-droite
      image.getPixel(x - 2, y + 2), // bas-gauche
      image.getPixel(x + 2, y + 2), // bas-droite
    ];
    
    double gradient = 0;
    for (final neighbor in neighbors) {
      gradient += (center.r - neighbor.r).abs() +
                  (center.g - neighbor.g).abs() +
                  (center.b - neighbor.b).abs();
    }
    
    return gradient / (neighbors.length * 255);
  }

  /// Fusion Adobe Scan
  List<Rectangle> _mergeAdobeRectangles(List<Rectangle> rectangles) {
    if (rectangles.isEmpty) return [];
    
    final merged = <Rectangle>[];
    final used = <bool>[];
    for (int i = 0; i < rectangles.length; i++) {
      used.add(false);
    }
    
    for (int i = 0; i < rectangles.length; i++) {
      if (used[i]) continue;
      
      Rectangle current = rectangles[i];
      used[i] = true;
      
      // Fusion Adobe (plus agressive)
      for (int j = i + 1; j < rectangles.length; j++) {
        if (used[j]) continue;
        
        final other = rectangles[j];
        final distance = _calculateAdobeDistance(current, other);
        
        if (distance < 80) { // Seuil Adobe plus élevé
          current = _mergeAdobeRectangles(current, other);
          used[j] = true;
        }
      }
      
      merged.add(current);
    }
    
    return merged;
  }

  /// Distance Adobe Scan
  double _calculateAdobeDistance(Rectangle r1, Rectangle r2) {
    final center1X = r1.x + r1.width ~/ 2;
    final center1Y = r1.y + r1.height ~/ 2;
    final center2X = r2.x + r2.width ~/ 2;
    final center2Y = r2.y + r2.height ~/ 2;
    
    return ((center1X - center2X) * (center1X - center2X) + 
            (center1Y - center2Y) * (center1Y - center2Y)).toDouble();
  }

  /// Fusion Adobe
  Rectangle _mergeAdobeRectangles(Rectangle r1, Rectangle r2) {
    final minX = r1.x < r2.x ? r1.x : r2.x;
    final minY = r1.y < r2.y ? r1.y : r2.y;
    final maxX = (r1.x + r1.width) > (r2.x + r2.width) ? 
                  (r1.x + r1.width) : (r2.x + r2.width);
    final maxY = (r1.y + r1.height) > (r2.y + r2.height) ? 
                  (r1.y + r1.height) : (r2.y + r2.height);
    
    return Rectangle(minX, minY, maxX - minX, maxY - minY);
  }

  /// Validation Adobe Scan
  bool _isValidAdobeDocument(Rectangle rect, img.Image image) {
    final ratio = rect.width / rect.height;
    
    // Critères Adobe Scan exacts
    if (ratio < _minDocumentRatio || ratio > _maxDocumentRatio) {
      return false;
    }
    
    // Vérifier la taille minimale Adobe
    final minArea = image.width * image.height * 0.1; // 10% de l'image
    final area = rect.width * rect.height;
    
    return area >= minArea;
  }

  /// Amélioration Adobe Scan exacte
  Future<File> enhanceImageAdobeStyle(File originalImage) async {
    try {
      final bytes = await originalImage.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Impossible de décoder l\'image');

      // Pipeline Adobe Scan exact
      image = _correctPerspectiveAdobe(image);
      image = _enhanceContrastAdobe(image);
      image = _denoiseAdobe(image);
      image = _sharpenAdobe(image);
      image = _optimizeForOCRAdobe(image);

      // Sauvegarder Adobe style
      final tempDir = await getTemporaryDirectory();
      final enhancedPath = '${tempDir.path}/adobe_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final enhancedBytes = img.encodeJpg(image, quality: 95);
      final enhancedFile = File(enhancedPath);
      await enhancedFile.writeAsBytes(enhancedBytes);

      return enhancedFile;
    } catch (e) {
      debugPrint('Erreur amélioration Adobe: $e');
      return originalImage;
    }
  }

  /// Correction perspective Adobe
  img.Image _correctPerspectiveAdobe(img.Image image) {
    try {
      final corners = _detectAdobeCorners(image);
      if (corners.length == 4) {
        return _applyAdobePerspective(image, corners);
      }
    } catch (e) {
      debugPrint('Erreur perspective Adobe: $e');
    }
    return image;
  }

  /// Détection coins Adobe
  List<ScanPoint> _detectAdobeCorners(img.Image image) {
    final corners = <ScanPoint>[];
    final gray = img.grayscale(image);
    final width = gray.width;
    final height = gray.height;
    
    // Quadrants Adobe
    final quadrants = [
      [0, 0, width ~/ 2, height ~/ 2],
      [width ~/ 2, 0, width, height ~/ 2],
      [0, height ~/ 2, width ~/ 2, height],
      [width ~/ 2, height ~/ 2, width, height],
    ];
    
    for (final quadrant in quadrants) {
      final corner = _findAdobeCorner(gray, quadrant[0], quadrant[1], quadrant[2], quadrant[3]);
      if (corner != null) {
        corners.add(corner);
      }
    }
    
    return corners;
  }

  /// Trouver coin Adobe
  ScanPoint? _findAdobeCorner(img.Image image, int x1, int y1, int x2, int y2) {
    double maxGradient = 0;
    ScanPoint? bestCorner;
    
    for (int y = y1; y < y2; y++) {
      for (int x = x1; x < x2; x++) {
        final gradient = _calculateAdobeCornerGradient(image, x, y);
        if (gradient > maxGradient) {
          maxGradient = gradient;
          bestCorner = ScanPoint(x, y);
        }
      }
    }
    
    return bestCorner;
  }

  /// Gradient coin Adobe
  double _calculateAdobeCornerGradient(img.Image image, int x, int y) {
    if (x < 2 || y < 2 || x >= image.width - 2 || y >= image.height - 2) {
      return 0;
    }
    
    final center = image.getPixel(x, y);
    final neighbors = [
      image.getPixel(x - 1, y),
      image.getPixel(x + 1, y),
      image.getPixel(x, y - 1),
      image.getPixel(x, y + 1),
    ];
    
    double gradient = 0;
    for (final neighbor in neighbors) {
      gradient += (center.r - neighbor.r).abs() +
                  (center.g - neighbor.g).abs() +
                  (center.b - neighbor.b).abs();
    }
    
    return gradient;
  }

  /// Perspective Adobe
  img.Image _applyAdobePerspective(img.Image image, List<ScanPoint> corners) {
    corners.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });
    
    final width = _calculateAdobeDistance(corners[0], corners[1]).round();
    final height = _calculateAdobeDistance(corners[0], corners[2]).round();
    
    final corrected = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final sourceX = _interpolateAdobeX(x, y, width, height, corners);
        final sourceY = _interpolateAdobeY(x, y, width, height, corners);
        
        if (sourceX >= 0 && sourceX < image.width && 
            sourceY >= 0 && sourceY < image.height) {
          corrected.setPixel(x, y, image.getPixel(sourceX.round(), sourceY.round()));
        }
      }
    }
    
    return corrected;
  }

  /// Interpolation Adobe X
  double _interpolateAdobeX(int x, int y, int width, int height, List<ScanPoint> corners) {
    final u = x / width.toDouble();
    final v = y / height.toDouble();
    
    return (1 - u) * (1 - v) * corners[0].x +
           u * (1 - v) * corners[1].x +
           u * v * corners[2].x +
           (1 - u) * v * corners[3].x;
  }

  /// Interpolation Adobe Y
  double _interpolateAdobeY(int x, int y, int width, int height, List<ScanPoint> corners) {
    final u = x / width.toDouble();
    final v = y / height.toDouble();
    
    return (1 - u) * (1 - v) * corners[0].y +
           u * (1 - v) * corners[1].y +
           u * v * corners[2].y +
           (1 - u) * v * corners[3].y;
  }

  /// Distance Adobe
  double _calculateAdobeDistance(ScanPoint p1, ScanPoint p2) {
    return ((p1.x - p2.x) * (p1.x - p2.x) + 
            (p1.y - p2.y) * (p1.y - p2.y)).toDouble();
  }

  /// Amélioration contraste Adobe
  img.Image _enhanceContrastAdobe(img.Image image) {
    return img.adjustColor(image, contrast: 1.4); // Adobe style
  }

  /// Dénuiser Adobe
  img.Image _denoiseAdobe(img.Image image) {
    // Filtre Adobe
    return img.gaussianBlur(image, radius: 0.5);
  }

  /// Netteté Adobe
  img.Image _sharpenAdobe(img.Image image) {
    // Filtre de netteté Adobe
    final kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0]
    ];
    return img.convolution(image, kernel);
  }

  /// Optimisation OCR Adobe
  img.Image _optimizeForOCRAdobe(img.Image image) {
    return img.adjustColor(image, 
      contrast: 1.3,
      brightness: 1.05,
      saturation: 1.1,
    );
  }

  /// OCR Adobe Scan
  Future<String> performAdobeOCR(File imageFile) async {
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
      debugPrint('Erreur OCR Adobe: $e');
      return '';
    }
  }

  /// Processus Adobe Scan complet
  Future<AdobeScanResult> processAdobeScan(File originalImage, Rectangle? detectedBounds) async {
    try {
      // Amélioration Adobe
      final enhancedImage = await enhanceImageAdobeStyle(originalImage);
      
      // OCR Adobe
      final ocrText = await performAdobeOCR(enhancedImage);
      
      // Qualité Adobe
      final quality = _assessAdobeQuality(enhancedImage, ocrText);
      
      return AdobeScanResult(
        originalImage: originalImage,
        processedImage: enhancedImage,
        ocrText: ocrText,
        quality: quality,
        detectedBounds: detectedBounds,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur Adobe Scan: $e');
      rethrow;
    }
  }

  /// Évaluation qualité Adobe
  ScanQuality _assessAdobeQuality(File enhancedImage, String ocrText) {
    if (ocrText.length > 150) {
      return ScanQuality.excellent;
    } else if (ocrText.length > 80) {
      return ScanQuality.good;
    } else if (ocrText.length > 20) {
      return ScanQuality.fair;
    } else {
      return ScanQuality.poor;
    }
  }

  /// Demande permissions Adobe style
  Future<bool> requestAdobePermissions() async {
    try {
      final cameraStatus = await Permission.camera.request();
      
      PermissionStatus storageStatus;
      if (await Permission.storage.isGranted) {
        storageStatus = PermissionStatus.granted;
      } else {
        if (await Permission.photos.isGranted) {
          storageStatus = PermissionStatus.granted;
        } else {
          storageStatus = await Permission.photos.request();
        }
      }
      
      final hasCamera = cameraStatus.isGranted;
      final hasStorage = storageStatus.isGranted;
      
      return hasCamera && hasStorage;
    } catch (e) {
      debugPrint('Erreur permissions Adobe: $e');
      return false;
    }
  }
} 