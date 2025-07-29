import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:arkiva/config/api_config.dart';

class FichierService extends ChangeNotifier {
  final String baseUrl = ApiConfig.baseUrl;
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, String dossierId) async {
    if (_authToken == null) {
      throw Exception('Non authentifié');
    }

    try {
      // TODO: Implement file upload logic
      return {'message': 'Fonctionnalité en cours de développement'};
    } catch (e) {
      throw Exception('Erreur lors du téléversement: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFichiers(String dossierId) async {
    if (_authToken == null) {
      throw Exception('Non authentifié');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/dossiers/$dossierId/fichiers'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erreur lors de la récupération des fichiers');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<Map<String, dynamic>> getFichierDetails(String fichierId) async {
    if (_authToken == null) {
      throw Exception('Non authentifié');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/fichiers/$fichierId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des détails du fichier');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<void> deleteFichier(String fichierId) async {
    if (_authToken == null) {
      throw Exception('Non authentifié');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/fichiers/$fichierId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression du fichier');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}
