import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EdgeDetectionService {
  static const double _minEdgeConfidence = 0.7;
  static const double _maxFrameAdjustment = 0.2;

  /// Détecte les bords d'un document dans une image
  static Future<Map<String, double>?> detectDocumentEdges(File imageFile) async {
    if (kIsWeb) {
      // Retourner des valeurs par défaut sur le web
      return {
        'topLeft': 0.1,
        'topRight': 0.9,
        'bottomLeft': 0.1,
        'bottomRight': 0.9,
        'confidence': 0.85,
      };
    }

    try {
      // Simulation de détection de bords
      // Dans une implémentation réelle, vous utiliseriez OpenCV ou ML Kit
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Retourner des coordonnées simulées
      return {
        'topLeft': 0.1,
        'topRight': 0.9,
        'bottomLeft': 0.1,
        'bottomRight': 0.9,
        'confidence': 0.85,
      };
    } catch (e) {
      debugPrint('Erreur lors de la détection de bords: $e');
      return null;
    }
  }

  /// Calcule les dimensions optimales du cadre basées sur les bords détectés
  static Map<String, double> calculateOptimalFrame(
    Map<String, double> edges,
    Size screenSize,
    bool isLandscape,
  ) {
    final double confidence = edges['confidence'] ?? 0.0;
    
    if (confidence < _minEdgeConfidence) {
      // Retourner les dimensions par défaut si la confiance est faible
      return _getDefaultFrame(screenSize, isLandscape);
    }

    // Calculer les dimensions optimales basées sur les bords détectés
    final double left = edges['topLeft'] ?? 0.1;
    final double right = edges['topRight'] ?? 0.9;
    final double top = edges['topLeft'] ?? 0.1;
    final double bottom = edges['bottomLeft'] ?? 0.9;

    double frameWidth = (right - left).clamp(0.5, 0.95);
    double frameHeight = (bottom - top).clamp(0.3, 0.8);
    double frameX = left.clamp(0.05, 0.4);
    double frameY = top.clamp(0.1, 0.3);

    // Ajuster selon l'orientation
    if (isLandscape) {
      frameWidth = frameWidth * 0.8;
      frameHeight = frameHeight * 1.2;
      frameX = frameX * 1.2;
      frameY = frameY * 0.8;
    }

    return {
      'width': frameWidth,
      'height': frameHeight,
      'x': frameX,
      'y': frameY,
    };
  }

  /// Retourne les dimensions par défaut du cadre
  static Map<String, double> _getDefaultFrame(Size screenSize, bool isLandscape) {
    if (isLandscape) {
      return {
        'width': 0.6,
        'height': 0.8,
        'x': 0.2,
        'y': 0.1,
      };
    } else {
      return {
        'width': 0.85,
        'height': 0.7,
        'x': 0.075,
        'y': 0.15,
      };
    }
  }

  /// Valide si les dimensions du cadre sont acceptables
  static bool isValidFrame(Map<String, double> frame) {
    final double width = frame['width'] ?? 0;
    final double height = frame['height'] ?? 0;
    final double x = frame['x'] ?? 0;
    final double y = frame['y'] ?? 0;

    // Vérifier que le cadre est dans les limites de l'écran
    if (x < 0 || y < 0 || x + width > 1 || y + height > 1) {
      return false;
    }

    // Vérifier que le cadre a une taille minimale
    if (width < 0.3 || height < 0.2) {
      return false;
    }

    // Vérifier que le cadre a une taille maximale
    if (width > 0.95 || height > 0.9) {
      return false;
    }

    return true;
  }

  /// Ajuste progressivement le cadre vers les dimensions optimales
  static Map<String, double> interpolateFrame(
    Map<String, double> currentFrame,
    Map<String, double> targetFrame,
    double progress,
  ) {
    return {
      'width': _interpolate(currentFrame['width'] ?? 0, targetFrame['width'] ?? 0, progress),
      'height': _interpolate(currentFrame['height'] ?? 0, targetFrame['height'] ?? 0, progress),
      'x': _interpolate(currentFrame['x'] ?? 0, targetFrame['x'] ?? 0, progress),
      'y': _interpolate(currentFrame['y'] ?? 0, targetFrame['y'] ?? 0, progress),
    };
  }

  static double _interpolate(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  /// Calcule la qualité de la détection basée sur la netteté et le contraste
  static double calculateDetectionQuality(File imageFile) {
    if (kIsWeb) {
      return 0.8; // Valeur par défaut sur le web
    }
    
    // Simulation de calcul de qualité
    // Dans une implémentation réelle, vous analyseriez l'image
    return Random().nextDouble() * 0.3 + 0.7; // Entre 0.7 et 1.0
  }

  /// Détermine si l'image est suffisamment stable pour la détection
  static bool isImageStable(List<Map<String, double>> recentDetections) {
    if (kIsWeb) {
      return true; // Toujours stable sur le web
    }
    
    if (recentDetections.length < 3) return false;

    // Calculer la variance des détections récentes
    double variance = 0;
    final double mean = recentDetections
        .map((d) => d['confidence'] ?? 0)
        .reduce((a, b) => a + b) / recentDetections.length;

    for (final detection in recentDetections) {
      final double confidence = detection['confidence'] ?? 0;
      variance += pow(confidence - mean, 2);
    }
    variance /= recentDetections.length;

    // Retourner true si la variance est faible (image stable)
    return variance < 0.01;
  }

  /// Optimise les paramètres de détection selon les conditions
  static Map<String, dynamic> optimizeDetectionParameters(
    double lightLevel,
    double motionLevel,
    bool isLandscape,
  ) {
    if (kIsWeb) {
      // Paramètres par défaut pour le web
      return {
        'sensitivity': 0.7,
        'updateInterval': 1000,
        'confidenceThreshold': 0.7,
        'maxAdjustment': 0.2,
      };
    }

    return {
      'sensitivity': _calculateSensitivity(lightLevel, motionLevel),
      'updateInterval': _calculateUpdateInterval(motionLevel),
      'confidenceThreshold': _calculateConfidenceThreshold(lightLevel),
      'maxAdjustment': _calculateMaxAdjustment(motionLevel),
    };
  }

  static double _calculateSensitivity(double lightLevel, double motionLevel) {
    // Sensibilité plus élevée en faible luminosité
    double sensitivity = 0.5 + (1 - lightLevel) * 0.3;
    
    // Réduire la sensibilité si beaucoup de mouvement
    if (motionLevel > 0.7) {
      sensitivity *= 0.7;
    }
    
    return sensitivity.clamp(0.3, 0.9);
  }

  static int _calculateUpdateInterval(double motionLevel) {
    // Intervalle plus court si peu de mouvement
    if (motionLevel < 0.3) return 500;
    if (motionLevel < 0.7) return 1000;
    return 2000;
  }

  static double _calculateConfidenceThreshold(double lightLevel) {
    // Seuil plus bas en faible luminosité
    return (0.6 + lightLevel * 0.2).clamp(0.5, 0.8);
  }

  static double _calculateMaxAdjustment(double motionLevel) {
    // Ajustement plus conservateur si beaucoup de mouvement
    return (0.3 - motionLevel * 0.2).clamp(0.1, 0.3);
  }
} 