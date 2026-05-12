import 'package:flutter_test/flutter_test.dart';
import 'package:diplochain_app/services/diploma_service.dart';
import 'package:diplochain_app/models/diploma.dart';

void main() {
  group('DiplomaService', () {
    test('getDiplomasForUser retourne liste filtrée en fallback', () async {
      final diplomas = await DiplomaService.instance.getDiplomasForUser('usr_da_firmin');
      expect(diplomas, isNotEmpty);
      expect(diplomas.every((d) => d.studentName.contains('Da Firmin')), isTrue);
    });

    test('verifyDiploma retourne true pour hash connu en fallback', () async {
      final isVerified = await DiplomaService.instance.verifyDiploma('0x71b2a4f9e3c18d5b2a4f9e3c18d5b2a4');
      expect(isVerified, isTrue);
    });

    test('getPublicDiplomaUrl construit URL correcte', () {
      final diploma = Diploma(
        id: '1',
        title: 'Test',
        university: 'Test Univ',
        date: DateTime(2023, 1, 1),
        studentName: 'Test User',
        blockchainHash: '0x1234567890abcdef',
      );
      final url = DiplomaService.instance.getPublicDiplomaUrl(diploma);
      expect(url, contains('0x1234567890abcdef'));
    });
  });
}