import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud account deletion evidence references live coverage', () {
    final evidence = File(
      'docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md',
    ).readAsStringSync();
    final requiredEvidence = {
      'lib/screens/settings_screen.dart': [
        'Delete cloud account',
        'The local player stays on this device',
        'Remove local player',
      ],
      'test/settings_account_test.dart': [
        'protected player can delete cloud account from settings',
      ],
      'lib/services/account_protection_service.dart': [
        'deleteCloudAccount',
        'Cloud account deleted. This local player remains on this device',
        'Cloud account deletion failed. Nothing local was removed.',
      ],
      'lib/services/firebase_anonymous_auth_gateway.dart': [
        "doc('egg_hatchers')",
        'deleteProtectedAccount',
        'user.delete()',
      ],
      'test/account_protection_service_test.dart': [
        'cloud account deletion clears identity binding and sync ancestry',
        'failed cloud deletion keeps protected identity binding',
      ],
    };

    for (final entry in requiredEvidence.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(evidence, contains(entry.key), reason: entry.key);
      expect(source, isNotEmpty, reason: entry.key);
      for (final phrase in entry.value) {
        expect(evidence, contains(phrase), reason: phrase);
        expect(source, contains(phrase), reason: phrase);
      }
    }

    expect(evidence, contains('local player removal'));
    expect(evidence, contains('selected launch platforms'));
  });
}
