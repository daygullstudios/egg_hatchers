import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account matrix evidence references live regression coverage', () {
    final evidence = File(
      'docs/RELEASE_ACCOUNT_MATRIX_EVIDENCE.md',
    ).readAsStringSync();
    final requiredEvidence = {
      'test/account_service_test.dart': [
        'Multiple local profiles can be selected independently',
        'Profile removal deletes progress only after directory commit',
      ],
      'test/account_onboarding_screen_test.dart': [
        'Picker cancellation and removal preserve another player and settings',
      ],
      'test/settings_account_test.dart': [
        'Local removal cancels safely and preserves other players',
        'Cloud data and sign-in accounts are not deleted.',
      ],
      'test/offline_startup_test.dart': [
        'Valid local players can open and save with hanging or failed Firebase',
      ],
      'test/progress_conflict_dialog_test.dart': [
        'Only final device or cloud confirmation replaces progress',
      ],
      'test/progress_recovery_test.dart': [
        'Runtime corruption blocks autosave and cloud replacement',
      ],
      'test/unsaved_progress_test.dart': [
        'Failed live saves freeze mutation',
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

    expect(
      evidence,
      contains('cloud-account erasure is complete'),
    );
    expect(evidence, contains('Complete cloud-account deletion where required'));
  });
}
