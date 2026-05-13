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

  /// Récupère les diplômes de l'utilisateur depuis la blockchain (via API).
  Future<List<Diploma>> getDiplomasForUser(String userId) async {
    try {
      final url = '${ApiConfig.baseUrl}/diplomas/$userId';
      debugPrint('[DiplomaService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: AuthService.instance.authorizedHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          debugPrint(
              '[DiplomaService] ${items.length} diplômes récupérés via API.');
          return items.map((json) => Diploma.fromJson(json)).toList();
        } else {
          throw Exception(data['error'] ?? 'Erreur inconnue du serveur');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DiplomaService] Erreur réseau ou timeout: $e');
      throw Exception('Impossible de charger les diplômes depuis la blockchain. Vérifiez votre connexion réseau.');
    }
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
