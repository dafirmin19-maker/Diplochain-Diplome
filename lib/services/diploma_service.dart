// Service de gestion des diplômes
// Fournit les données des diplômes du diplômé connecté.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/diploma.dart';
import 'api_config.dart';
import 'auth_service.dart';

class DiplomaService {
  DiplomaService._();
  static final DiplomaService instance = DiplomaService._();

  /// Récupère les diplômes de l'utilisateur depuis l'API backend.
  Future<List<Diploma>> getDiplomasForUser(String userId) async {
    try {
      final url = '${ApiConfig.baseUrl}/diplomas?user=$userId';
      debugPrint('[DiplomaService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: AuthService.instance.authorizedHeaders)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          debugPrint(
              '[DiplomaService] ${items.length} diplômes récupérés via API.');
          return items.map((json) => Diploma.fromJson(json)).toList();
        }
      }
      return _mockDiplomas;
    } catch (e) {
      debugPrint('[DiplomaService] Fallback local: $e');
      // Simulation de filtrage par userId en fallback
      return _mockDiplomas.where((diploma) => diploma.studentName.toLowerCase().contains(userId.split('_').last.toLowerCase())).toList();
    }
  }

  /// Vérifie l'authenticité d'un diplôme via son hash blockchain
  Future<bool> verifyDiploma(String blockchainHash) async {
    try {
      final url = '${ApiConfig.baseUrl}/verify/$blockchainHash';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isVerified'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[DiplomaService] Erreur vérification: $e');
      return _mockDiplomas.any((d) => d.blockchainHash == blockchainHash);
    }
  }

  String getPublicDiplomaUrl(Diploma diploma) {
    return ApiConfig.publicDiplomaUrl(diploma.blockchainHash);
  }

  // Données de démonstration (Fallback si API inaccessible)
  static final List<Diploma> _mockDiplomas = [
    Diploma(
      id: '1',
      title: 'Ingénieur Généraliste',
      university: 'Université Polytechnique de Ouagadougou',
      date: DateTime(2025, 7, 12), // Changé en DateTime
      studentName: 'Da Firmin',
      blockchainHash: '0x71b2a4f9e3c18d5b2a4f9e3c18d5b2a4',
      specialization: 'Génie Informatique',
      mention: 'Très Bien',
      isVerified: true,
    ),
    Diploma(
      id: '2',
      title: 'Master en Cybersécurité',
      university: 'Institut Africain des Technologies',
      date: DateTime(2024, 10, 5), // Changé en DateTime
      studentName: 'Da Firmin',
      blockchainHash: '0xabcd1234ef567890abcd1234ef567890',
      specialization: 'Sécurité des Systèmes Distribués',
      mention: 'Bien',
      isVerified: true,
    ),
    Diploma(
      id: '3',
      title: 'Licence Professionnelle',
      university: 'Université de Koudougou',
      date: DateTime(2022, 6, 20), // Changé en DateTime
      studentName: 'Da Firmin',
      blockchainHash: '0xdeadbeef12345678deadbeef12345678',
      isVerified: true,
    ),
  ];
}
