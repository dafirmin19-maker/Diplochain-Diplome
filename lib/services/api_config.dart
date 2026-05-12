// Configuration centralisée de l'API DiploChain
// Modifier cette classe pour pointer vers le bon serveur backend.

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// Port du backend Express
  static const int _port = 3001;

  /// IP du PC sur le réseau local (pour device réel via Wi-Fi).
  /// Mettre à jour avec l'IP de ta machine : ipconfig → IPv4
  static const String _lanIp = '192.168.11.100';

  /// Host public du backend si l'API est hébergée sur Internet.
  /// Exemple : 'diplochain-backend.up.railway.app'
  static const String _publicHost = 'YOUR_PUBLIC_API_HOST';

  /// Mode de connexion actuel.
  /// - [ConnectionMode.emulator] → 10.0.2.2 (émulateur Android standard)
  /// - [ConnectionMode.realDevice] → IP LAN du PC (téléphone réel)
  /// - [ConnectionMode.desktop] → localhost
  /// - [ConnectionMode.public] → backend hébergé sur Internet
  ///
  /// Pour un usage réel après déploiement, sélectionne `public`.
  static ConnectionMode mode = ConnectionMode.auto;

  /// URL de base calculée automatiquement
  static String get baseUrl {
    final host = _resolveHost();
    return 'http://$host:$_port/api';
  }

  /// URL d'authentification
  static String get authUrl => '$baseUrl/auth';

  /// URL publique partageable d'un diplome.
  static String publicDiplomaUrl(String blockchainHash) {
    return '$baseUrl/public/diplomas/${Uri.encodeComponent(blockchainHash)}';
  }

  /// Résout l'hôte selon le mode choisi
  static String _resolveHost() {
    switch (mode) {
      case ConnectionMode.emulator:
        return '10.0.2.2';
      case ConnectionMode.realDevice:
        return _lanIp;
      case ConnectionMode.desktop:
        return 'localhost';
      case ConnectionMode.public:
        return _publicHost;
      case ConnectionMode.auto:
        return _autoDetect();
    }
  }

  /// Détection automatique de la plateforme
  static String _autoDetect() {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) {
      // Sur Android, on privilégie le device réel (IP LAN)
      // Changer en '10.0.2.2' si vous utilisez l'émulateur Android Studio
      return _lanIp;
    }
    if (Platform.isIOS) return 'localhost'; // iOS Simulator partage le réseau
    return 'localhost'; // Desktop (Windows, macOS, Linux)
  }
}

/// Mode de connexion au backend
enum ConnectionMode {
  /// Détection automatique selon la plateforme
  auto,

  /// Émulateur Android (10.0.2.2)
  emulator,

  /// Device physique via Wi-Fi (IP LAN du PC)
  realDevice,

  /// Backend hébergé sur Internet (URL publique)
  public,

  /// Windows / macOS / Linux (localhost)
  desktop,
}
