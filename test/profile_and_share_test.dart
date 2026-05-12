import 'package:diplochain_app/models/diploma.dart';
import 'package:diplochain_app/models/user.dart';
import 'package:diplochain_app/screens/diploma_detail_screen.dart';
import 'package:diplochain_app/screens/profile_screen.dart';
import 'package:diplochain_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final diploma = Diploma(
    id: '1',
    title: 'Master en Cybersecurite',
    university: 'Institut Africain des Technologies',
    date: DateTime(2024, 10, 5),
    studentName: 'Da Firmin',
    blockchainHash: '0xabcd1234ef567890abcd1234ef567890',
    specialization: 'Securite des Systemes Distribues',
    mention: 'Bien',
  );

  setUp(() async {
    await AuthService.instance.logout();
  });

  testWidgets('ProfileScreen affiche les informations du diplome connecte',
      (tester) async {
    AuthService.instance.setTestSession(
      user: AppUser(
        id: 'usr_test',
        fullName: 'Aminata Sawadogo',
        email: 'aminata@example.com',
        phone: '+226 70 00 00 00',
        institution: 'Universite de Koudougou',
        createdAt: DateTime(2026, 5, 11),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Aminata Sawadogo'), findsWidgets);
    expect(find.text('aminata@example.com'), findsWidgets);
    expect(find.text('+226 70 00 00 00'), findsOneWidget);
    expect(find.text('Universite de Koudougou'), findsOneWidget);
  });

  testWidgets('ProfileScreen affiche un etat vide sans session',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Profil indisponible'), findsOneWidget);
  });

  testWidgets(
      'DiplomaDetailScreen expose les actions de partage et verification',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DiplomaDetailScreen(diploma: diploma)),
    );

    expect(find.byKey(const Key('shareDiplomaButton')), findsOneWidget);
    expect(find.byKey(const Key('copyHashButton')), findsOneWidget);
    expect(find.byKey(const Key('openVerificationButton')), findsOneWidget);
    expect(find.byKey(const Key('shareQrCodeButton')), findsOneWidget);
    expect(find.textContaining('/api/public/diplomas/'), findsOneWidget);
  });

  testWidgets('copier le hash place la valeur dans le presse-papier',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DiplomaDetailScreen(diploma: diploma)),
    );

    await tester.tap(find.byKey(const Key('copyHashButton')));
    await tester.pump();

    expect(find.text('Hash copié dans le presse-papier'), findsOneWidget);
  });
}
