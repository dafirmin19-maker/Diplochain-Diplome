// Tests unitaires DiploChain v2
// Couvre : AuthService (validation), Diploma (modèle)
// Lancer avec : flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:diplochain_app/services/auth_service.dart';
import 'package:diplochain_app/models/diploma.dart';
import 'package:diplochain_app/models/user.dart';

void main() {
  // ────────────────────────────────────────────
  // Tests validation email
  // ────────────────────────────────────────────
  group('AuthService.validateEmail', () {
    test('accepte un email valide', () {
      expect(AuthService.validateEmail('user@example.com'), isNull);
      expect(AuthService.validateEmail('a.b+c@domain.co.uk'), isNull);
    });

    test('rejette un email vide', () {
      expect(AuthService.validateEmail(''), isNotNull);
    });

    test('rejette un email sans @', () {
      expect(AuthService.validateEmail('notanemail'), isNotNull);
    });

    test('rejette un email sans domaine', () {
      expect(AuthService.validateEmail('user@'), isNotNull);
    });

    test('rejette un email avec espace', () {
      expect(AuthService.validateEmail('user @example.com'), isNotNull);
    });
  });

  // ────────────────────────────────────────────
  // Tests validation mot de passe
  // ────────────────────────────────────────────
  group('AuthService.validatePassword', () {
    test('accepte un mot de passe fort', () {
      expect(AuthService.validatePassword('Secure1Pass'), isNull);
      expect(AuthService.validatePassword('DiploChain2025!'), isNull);
    });

    test('rejette un mot de passe vide', () {
      expect(AuthService.validatePassword(''), isNotNull);
    });

    test('rejette moins de 8 caractères', () {
      expect(AuthService.validatePassword('Short1'), isNotNull);
    });

    test('rejette sans majuscule', () {
      expect(AuthService.validatePassword('alllower1'), isNotNull);
    });

    test('rejette sans chiffre', () {
      expect(AuthService.validatePassword('NoNumbers!'), isNotNull);
    });
  });

  // ────────────────────────────────────────────
  // Tests validation nom complet
  // ────────────────────────────────────────────
  group('AuthService.validateFullName', () {
    test('accepte un nom valide', () {
      expect(AuthService.validateFullName('Aminata Sawadogo'), isNull);
      expect(AuthService.validateFullName('Ali'), isNull);
    });

    test('rejette un nom vide', () {
      expect(AuthService.validateFullName(''), isNotNull);
    });

    test('rejette un nom trop court', () {
      expect(AuthService.validateFullName('AB'), isNotNull);
    });

    test('rejette un nom de plus de 100 chars', () {
      final longName = 'A' * 101;
      expect(AuthService.validateFullName(longName), isNotNull);
    });
  });

  // ────────────────────────────────────────────
  // Tests connexion (mock)
  // ────────────────────────────────────────────
  group('AuthService.login', () {
    late AuthService auth;
    setUp(() => auth = AuthService());

    test('connecte avec credentials valides', () async {
      final result = await auth.login(
        email: 'demo@example.com',
        password: 'Demo1234',
      );
      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user!.email, 'demo@example.com');
    });

    test('rejette un mot de passe trop court', () async {
      final result = await auth.login(
        email: 'test@example.com',
        password: 'abc',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('rejette un email invalide', () async {
      final result = await auth.login(
        email: 'invalidemail',
        password: 'Password1',
      );
      expect(result.success, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // Tests inscription (mock)
  // ────────────────────────────────────────────
  group('AuthService.register', () {
    late AuthService auth;
    setUp(() => auth = AuthService());

    test('crée un compte avec données valides', () async {
      final result = await auth.register(
        fullName: 'Aminata Sawadogo',
        email: 'aminata@example.com',
        password: 'Secure2025!',
      );
      expect(result.success, isTrue);
      expect(result.user?.fullName, 'Aminata Sawadogo');
    });

    test('rejette si mot de passe faible', () async {
      final result = await auth.register(
        fullName: 'Test User',
        email: 'test@example.com',
        password: 'weak',
      );
      expect(result.success, isFalse);
    });
  });

  // ────────────────────────────────────────────
  // Tests modèle Diploma
  // ────────────────────────────────────────────
  group('Diploma model', () {
    final diploma = Diploma(
      id: '1',
      title: 'Ingénieur Généraliste',
      university: 'Université Polytechnique',
      date: DateTime(2025, 7, 12),
      studentName: 'Aminata Sawadogo',
      blockchainHash: '0x71b2a4f9e3c18d5b',
    );

    test('shortHash tronque correctement', () {
      expect(diploma.shortHash, '0x71b2...8d5b');
    });

    test('verificationUrl est correct', () {
      expect(
          diploma.verificationUrl, '/api/public/diplomas/0x71b2a4f9e3c18d5b');
    });

    test('sérialisation JSON aller-retour', () {
      final json = diploma.toJson();
      final restored = Diploma.fromJson(json);
      expect(restored.id, diploma.id);
      expect(restored.blockchainHash, diploma.blockchainHash);
      expect(restored.isVerified, diploma.isVerified);
    });

    test('égalité basée sur id + hash', () {
      final other = Diploma(
        id: '1',
        title: 'Autre titre',
        university: 'X',
        date: DateTime(2025),
        studentName: 'Y',
        blockchainHash: '0x71b2a4f9e3c18d5b',
      );
      expect(diploma == other, isTrue);
    });
  });

  // ────────────────────────────────────────────
  // Tests modèle AppUser
  // ────────────────────────────────────────────
  group('AppUser model', () {
    test('initiales extraites correctement', () {
      final user = AppUser(
        id: '1',
        fullName: 'Aminata Sawadogo',
        email: 'a@b.com',
        createdAt: DateTime.now(),
      );
      expect(user.initials, 'AS');
    });

    test('initiales avec un seul mot', () {
      final user = AppUser(
        id: '2',
        fullName: 'Aminata',
        email: 'a@b.com',
        createdAt: DateTime.now(),
      );
      expect(user.initials, 'A');
    });

    test('sérialisation JSON', () {
      final now = DateTime.now();
      final user = AppUser(
        id: '3',
        fullName: 'Test User',
        email: 'test@example.com',
        createdAt: now,
      );
      final json = user.toJson();
      expect(json['email'], 'test@example.com');
      expect(json['fullName'], 'Test User');
    });
  });
}
