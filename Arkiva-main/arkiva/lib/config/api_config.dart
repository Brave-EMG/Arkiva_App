import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const int connectionTimeout = 30; // 30 secondes
  static const int pingTimeout = 5; // 5 secondes
  
  // Configuration pour différents environnements
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Détection automatique : émulateur vs vrai appareil
      return _getAndroidBaseUrl();
    } else {
      return 'http://localhost:3000';
    }
  }

  static String _getAndroidBaseUrl() {
    // Pour l'émulateur Android
    if (_isEmulator()) {
      return 'http://10.0.2.2:3000';
    }
    
    // Pour un vrai appareil Android - utilisez l'IP de votre ordinateur
    // Remplacez par l'IP de votre ordinateur sur le réseau local
    return 'http://192.168.100.112:3000'; // IP de votre ordinateur
  }

  static bool _isEmulator() {
    // Détection basique d'émulateur
    try {
      final androidId = Platform.environment['ANDROID_ID'] ?? '';
      return androidId.contains('google') || androidId.contains('sdk');
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
} 