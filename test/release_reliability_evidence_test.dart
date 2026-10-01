import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release reliability evidence references live regression coverage', () {
    final evidence = File(
      'docs/RELEASE_RELIABILITY_EVIDENCE.md',
    ).readAsStringSync();
    final requiredEvidence = {
      'test/offline_startup_test.dart': [
        'Valid local players can open and save with hanging or failed Firebase',
        'Hanging identity does not block local play',
      ],
      'test/unsaved_progress_test.dart': [
        'Failed live saves freeze mutation',
        'Queued writes serialize backup rotation',
      ],
      'test/progress_recovery_test.dart': [
        'Runtime corruption blocks autosave and cloud replacement',
        'Storage outages surface `storageUnavailable`',
      ],
      'test/progress_recovery_ui_test.dart': [
        'Runtime damage replaces gameplay with the recovery screen',
      ],
      'test/settings_persistence_test.dart': [
        'Import is refused before writers are paused',
      ],
    };

    for (final entry in requiredEvidence.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(evidence, contains(entry.key), reason: entry.key);
      for (final phrase in entry.value) {
        expect(evidence, contains(phrase), reason: phrase);
      }
      expect(source, isNotEmpty, reason: entry.key);
    }
  });
}
