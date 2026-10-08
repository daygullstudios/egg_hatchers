import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rollback rehearsal audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_rollback_rehearsal.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Rollback rehearsal audit: version identity, backups, smoke checks and open rollback gate verified.',
      ),
    );
  });

  test('release verification runbook and CI include rollback audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_rollback_rehearsal.mjs'));
    expect(workflow, contains('node tool/audit_rollback_rehearsal.mjs'));
    expect(workflow, contains('Verify rollback rehearsal template'));
  });
}
