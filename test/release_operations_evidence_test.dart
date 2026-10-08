import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release operations evidence references recovery and restore coverage', () {
    final evidence = File(
      'docs/RELEASE_OPERATIONS_EVIDENCE.md',
    ).readAsStringSync();
    final requiredEvidence = {
      'test/unsaved_progress_test.dart': [
        'Failed live saves freeze risky actions',
        'Backup rotation and revision increments serialize',
      ],
      'test/progress_recovery_test.dart': [
        'Storage outages surface `storageUnavailable`',
        'Runtime corruption blocks autosave and cloud replacement',
      ],
      'test/progress_recovery_ui_test.dart': [
        'Damaged progress opens recovery UI',
      ],
      'test/save_transfer_service_test.dart': [
        'Versioned Save Transfer imports are staged for review',
      ],
      'docs/MULTIPLAYER_SHARD_MIGRATION.md': [
        'drain',
        'rollback',
      ],
      'cloudflare/multiplayer/README.md': [
        'encrypted manifest artifacts',
        'rollback sequence',
      ],
      'docs/BACKUP_RESTORE_DRILL.md': [
        'Local progress restore',
        'Release artifact restore',
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
  });

  test('release operations evidence tracks guardrails and remaining alerts', () {
    final evidence = File(
      'docs/RELEASE_OPERATIONS_EVIDENCE.md',
    ).readAsStringSync();
    final workerTest = File(
      'cloudflare/multiplayer/test/worker.test.ts',
    ).readAsStringSync();
    final safetyTest = File(
      'cloudflare/multiplayer/test/safety_authority.test.ts',
    ).readAsStringSync();
    final monitoring = File(
      'docs/RELEASE_MONITORING_EVIDENCE.md',
    ).readAsStringSync();

    expect(evidence, contains('32-session guardrail'));
    expect(evidence, contains('ten unique reports per reporter per day'));
    expect(evidence, contains('Do not mark the roadmap operations item complete'));
    expect(evidence, contains('docs/BACKUP_RESTORE_DRILL.md'));
    expect(evidence, contains('Alert destinations'));
    expect(workerTest, contains('capacity'));
    expect(workerTest, contains('settles a hosted result once'));
    expect(safetyTest, contains('prunes them after retention'));
    expect(monitoring, contains('Cloudflare Worker Observability'));
  });
}
