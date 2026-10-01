import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account recovery evidence references live regression coverage', () {
    final evidence = File(
      'docs/RELEASE_ACCOUNT_RECOVERY_EVIDENCE.md',
    ).readAsStringSync();
    final requiredEvidence = {
      'test/account_protection_service_test.dart': [
        'Linking Google preserves the anonymous UID and sync ancestry',
        'Opening an existing Google account clears old sync ancestry',
      ],
      'test/cross_device_recovery_test.dart': [
        'Existing identity recovery on a clean device requires a choice',
        'Guest Google linking preserves the same player and cloud document',
      ],
      'test/save_transfer_service_test.dart': [
        'Save Transfer review and staging never replace existing players',
        'Supported settings are restored without importing foreign identity',
      ],
    };

    for (final entry in requiredEvidence.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(evidence, contains(entry.key), reason: entry.key);
      expect(source, isNotEmpty, reason: entry.key);
      for (final phrase in entry.value) {
        expect(evidence, contains(phrase), reason: phrase);
      }
    }

    expect(evidence, contains('Google protection for guest progress'));
    expect(evidence, contains('Complete cloud-account deletion where required'));
  });
}
