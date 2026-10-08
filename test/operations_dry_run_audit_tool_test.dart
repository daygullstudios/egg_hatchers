import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operations dry-run audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_operations_dry_run.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Operations dry-run audit: rehearsal checklist, privacy boundary, backup restore drill and open release gates verified.',
      ),
    );
  });

  test(
    'release verification runbook and CI include operations dry-run audit',
    () {
      final runbook = File(
        'docs/RELEASE_VERIFICATION_RUNBOOK.md',
      ).readAsStringSync();
      final workflow = File('.github/workflows/verify.yml').readAsStringSync();

      expect(runbook, contains('node tool/audit_operations_dry_run.mjs'));
      expect(runbook, contains('docs/BACKUP_RESTORE_DRILL.md'));
      expect(workflow, contains('node tool/audit_operations_dry_run.mjs'));
      expect(workflow, contains('Verify operations dry-run checklist'));
    },
  );

  test('backup restore drill covers every release backup surface', () {
    final drill = File('docs/BACKUP_RESTORE_DRILL.md').readAsStringSync();
    final checklist = File(
      'docs/OPERATIONS_DRY_RUN_CHECKLIST.md',
    ).readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();
    final rollback = File('docs/ROLLBACK_REHEARSAL_TEMPLATE.md').readAsStringSync();

    for (final surface in [
      'Local progress restore',
      'Save Transfer restore',
      'Cloud account restore',
      'Safety database restore',
      'Multiplayer migration restore',
      'Release artifact restore',
    ]) {
      expect(drill, contains(surface), reason: surface);
    }

    for (final reference in [
      'Firebase/Firestore backup reference',
      'D1 safety database backup/export reference',
      'Multiplayer Durable Object migration/export reference',
      'Release build artifact backup location',
    ]) {
      expect(drill, contains(reference), reason: reference);
    }

    expect(checklist, contains('docs/BACKUP_RESTORE_DRILL.md'));
    expect(candidate, contains('Backup restore drill result'));
    expect(rollback, contains('Backup restore drill result'));
  });
}
