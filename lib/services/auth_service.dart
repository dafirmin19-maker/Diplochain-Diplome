// Service d'authentification DiploChain
// Gère la connexion, l'inscription et la session utilisateur.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';

/// Résultat générique d'une opération auth
class AuthResult {
  final bool success;
  final String? errorMessage;
  final AppUser? user;

  const AuthResult.success(this.user)
      : success = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;
}

/// Service d'authentification (ChangeNotifier pour Provider)
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  factory AuthService() => instance;

  AppUser? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  SharedPreferences? _prefs;

  AppUser? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  Map<String, String> get authorizedHeaders => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Initialise le service et charge la session persistée
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPersistedSession();
  }

  // ------------------------------------------------------------------
  // Connexion
  // ------------------------------------------------------------------

  /// Authentifie l'utilisateur avec email + mot de passe.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      // Validation côté client
      final emailError = _validateEmail(email);
      if (emailError != null) return AuthResult.failure(emailError);
      final passwordError = _validatePassword(password);
      if (passwordError != null) return AuthResult.failure(passwordError);

      // Tenter l'appel API
      try {
        final url = '${ApiConfig.authUrl}/login';
        debugPrint('[AuthService] POST $url');
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'email': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final userData = data['user'];
            final user = AppUser(
              id: userData['id'],
              fullName: userData['fullName'],
              email: userData['email'],
              phone: userData['phone'] as String?,
              institution: userData['institution'] as String?,
              createdAt: DateTime.parse(userData['createdAt']),
            );
            _authToken = data['token'] as String?;
            _currentUser = user;
            await _saveSession();
            notifyListeners();
            debugPrint(
                '[AuthService] Connexion API réussie pour ${user.fullName}');
            return AuthResult.success(user);
          }
        }

        if (kDebugMode) {
          // Fallback uniquement pour les credentials de démo spécifiques
          if (email == 'demo@example.com' && password == 'Demo1234') {
            return _loginFallback(email);
          }
        }
        return AuthResult.failure('Email ou mot de passe incorrect.');
      } catch (networkError) {
        debugPrint('[AuthService] Serveur injoignable: $networkError');
        if (kDebugMode) {
          // Fallback uniquement pour les credentials de démo spécifiques
          if (email == 'demo@example.com' && password == 'Demo1234') {
            return _loginFallback(email);
          }
        }
        return AuthResult.failure(
          'Impossible de joindre le serveur. Veuillez réessayer plus tard.',
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Fallback de connexion quand le backend est indisponible
  AuthResult _loginFallback(String email) {
    final fallbackUser = AppUser(
      id: 'usr_da_firmin',
      fullName: 'Da Firmin',
      email: email.toLowerCase().trim(),
      phone: '+226 70 00 00 00',
      institution: 'Universite Polytechnique de Ouagadougou',
      createdAt: DateTime.now(),
    );
    _currentUser = fallbackUser;
    _authToken = null;
    _saveSession(); // Pas await car void
    notifyListeners();
    debugPrint('[AuthService] Connexion via fallback local (démo).');
    return AuthResult.success(fallbackUser);
  }

  // ------------------------------------------------------------------
  // Inscription
  // ------------------------------------------------------------------

  /// Crée un nouveau compte diplômé.
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? institution,
  }) async {
    _setLoading(true);
    try {
      // Validation stricte
      final nameError = _validateFullName(fullName);
      if (nameError != null) return AuthResult.failure(nameError);

      final emailError = _validateEmail(email);
      if (emailError != null) return AuthResult.failure(emailError);

      final passwordError = _validatePassword(password);
      if (passwordError != null) return AuthResult.failure(passwordError);

      // Tenter l'appel API
      try {
        final url = '${ApiConfig.authUrl}/register';
        debugPrint('[AuthService] POST $url');
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'fullName': fullName,
                'email': email,
                'password': password,
                'phone': phone,
                'institution': institution,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final userData = data['user'];
            final user = AppUser(
              id: userData['id'],
              fullName: userData['fullName'],
              email: userData['email'],
              phone: userData['phone'] as String?,
              institution: userData['institution'] as String?,
              createdAt: DateTime.parse(userData['createdAt']),
            );
            _authToken = data['token'] as String?;
            _currentUser = user;
            await _saveSession();
            notifyListeners();
            debugPrint(
                '[AuthService] Inscription API réussie pour ${user.fullName}');
            return AuthResult.success(user);
          }
        }
      } catch (networkError) {
        debugPrint(
            '[AuthService] Serveur injoignable pour inscription: $networkError');
        if (kDebugMode) {
          return _registerFallback(
            fullName: fullName,
            email: email,
            phone: phone,
            institution: institution,
          );
        }
        return AuthResult.failure(
          'Impossible de joindre le serveur. Veuillez réessayer plus tard.',
        );
      }

      if (kDebugMode) {
        return _registerFallback(
          fullName: fullName,
          email: email,
          phone: phone,
          institution: institution,
        );
      }
      return AuthResult.failure(
        'Impossible de créer le compte. Vérifiez vos informations.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Fallback d'inscription quand le backend est indisponible
  AuthResult _registerFallback({
    required String fullName,
    required String email,
    String? phone,
    String? institution,
  }) {
    final fallbackUser = AppUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: email.toLowerCase().trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      institution:
          institution?.trim().isEmpty == true ? null : institution?.trim(),
      createdAt: DateTime.now(),
    );
    _currentUser = fallbackUser;
    _authToken = null;
    _saveSession(); // Pas await car void
    notifyListeners();
    debugPrint('[AuthService] Inscription via fallback local (démo).');
    return AuthResult.success(fallbackUser);
  }

  // ------------------------------------------------------------------
  // Déconnexion
  // ------------------------------------------------------------------

  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    await _clearPersistedSession();
    notifyListeners();
  }

  @visibleForTesting
  void setTestSession({required AppUser user, String? token}) {
    _currentUser = user;
    _authToken = token;
    notifyListeners();
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _currentUser;
    if (user == null) return null;
    if (_authToken == null) return user;

    try {
      final url = '${ApiConfig.baseUrl}/users/${user.id}/profile';
      debugPrint('[AuthService] GET $url');
      final response = await http
          .get(Uri.parse(url), headers: authorizedHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final refreshed = AppUser.fromJson(data['user']);
          _currentUser = refreshed;
          notifyListeners();
          return refreshed;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Profil local utilise: $e');
    }

    return user;
  }

  // ------------------------------------------------------------------
  // Validation (réutilisable par les formulaires)
  // ------------------------------------------------------------------

  static String? validateFullName(String? value) =>
      _validateFullName(value ?? '');
  static String? validateEmail(String? value) => _validateEmail(value ?? '');
  static String? validatePassword(String? value) =>
      _validatePassword(value ?? '');

  static String? _validateFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Le nom complet est requis.';
    if (trimmed.length < 3) return 'Minimum 3 caractères.';
    if (trimmed.length > 100) return 'Trop long (100 chars max).';
    return null;
  }

  static String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'L\'email est requis.';
    if (trimmed.contains(' ')) return 'Adresse email invalide.';
    // Regex plus complète pour RFC 5322 (mais simplifiée pour éviter complexité)
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(trimmed)) return 'Adresse email invalide.';
    return null;
  }

  static String? _validatePassword(String value) {
    if (value.isEmpty) return 'Le mot de passe est requis.';
    if (value.length < 8) return 'Minimum 8 caractères.';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins une majuscule.';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins un chiffre.';
    return null;
  }

  // ------------------------------------------------------------------
  // Helpers privés
  // ------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _saveSession() async {
    if (_prefs == null) return;
    if (_currentUser != null) {
      await _prefs!.setString('user', json.encode(_currentUser!.toJson()));
    }
    if (_authToken != null) {
      await _prefs!.setString('token', _authToken!);
    }
  }

  Future<void> _loadPersistedSession() async {
    if (_prefs == null) return;
    final userJson = _prefs!.getString('user');
    final token = _prefs!.getString('token');
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = AppUser.fromJson(userData);
        _authToken = token;
        notifyListeners();
        debugPrint('[AuthService] Session chargée depuis SharedPreferences');
      } catch (e) {
        debugPrint('[AuthService] Erreur chargement session: $e');
        await _clearPersistedSession();
      }
    }
  }

  Future<void> _clearPersistedSession() async {
    if (_prefs == null) return;
    await _prefs!.remove('user');
    await _prefs!.remove('token');
  }
}
