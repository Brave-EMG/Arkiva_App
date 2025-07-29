import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const int connectionTimeout = 30; // 30 secondes
  static const int pingTimeout = 5; // 5 secondes
  
  // Pour le développement, utilisez 10.0.2.2 pour l'émulateur Android
  // et localhost pour iOS/web
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 est l'équivalent de localhost pour l'émulateur Android
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
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