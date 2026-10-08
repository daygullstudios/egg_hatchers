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
        'Operations dry-run audit: rehearsal checklist, privacy boundary, backup references and open release gates verified.',
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
      expect(workflow, contains('node tool/audit_operations_dry_run.mjs'));
      expect(workflow, contains('Verify operations dry-run checklist'));
    },
  );
}
