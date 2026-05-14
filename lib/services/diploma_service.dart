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

  bool isUsingFallback = false;

  /// Récupère les diplômes de l'utilisateur depuis la blockchain (via API).
  Future<List<Diploma>> getDiplomasForUser(String userId) async {
    isUsingFallback = false;
    try {
      final url = '${ApiConfig.baseUrl}/diplomas?user=$userId';
      debugPrint('[DiplomaService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: AuthService.instance.authorizedHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> items = data['data'];
          debugPrint(
              '[DiplomaService] ${items.length} diplômes récupérés via API.');
          return items.map((json) => Diploma.fromJson(json)).toList();
        }
      }
      if (userId == 'usr_da_firmin') {
        return _getFallbackDiplomas();
      }
      return [];
    } catch (e) {
      debugPrint('[DiplomaService] API indisponible, fallback activé: $e');
      if (userId == 'usr_da_firmin') {
        return _getFallbackDiplomas();
      }
      return [];
    }
  }

  // FALLBACK TEMPORAIRE — à supprimer quand Moussa finalise le contrat
  List<Diploma> _getFallbackDiplomas() {
    isUsingFallback = true;
    return [
      Diploma(
        id: '1',
        title: 'Ingénieur Généraliste',
        university: 'Université Polytechnique de Ouagadougou',
        date: DateTime(2025, 7, 12),
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
        date: DateTime(2024, 10, 5),
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
        date: DateTime(2022, 6, 20),
        studentName: 'Da Firmin',
        blockchainHash: '0xdeadbeef12345678deadbeef12345678',
        isVerified: true,
      ),
    ];
  }

  /// Vérifie l'authenticité d'un diplôme via son hash blockchain
  Future<bool> verifyDiploma(String blockchainHash) async {
    try {
      final url = '${ApiConfig.baseUrl}/verify/$blockchainHash';
      debugPrint('[DiplomaService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: AuthService.instance.authorizedHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final dynamic status = data['data'] != null ? data['data']['status'] : null;
          return status == 'AUTHENTIQUE' || data['isVerified'] == true;
        } else {
          throw Exception(data['error'] ?? 'Erreur de vérification');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DiplomaService] Erreur vérification: $e');
      throw Exception('Impossible de vérifier le diplôme (timeout ou erreur réseau).');
    }
  }

  String getPublicDiplomaUrl(Diploma diploma) {
    return ApiConfig.publicDiplomaUrl(diploma.blockchainHash);
  }


}
