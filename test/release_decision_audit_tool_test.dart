import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release decision audit passes for current decision packet evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_release_decisions.mjs',
    ]);

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains(
        'Release decision audit: owner decisions, launch blockers, rights, monitoring and family-review dependencies verified.',
      ),
    );
  });

  test('release verification runbook and CI include release decision audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_release_decisions.mjs'));
    expect(workflow, contains('node tool/audit_release_decisions.mjs'));
    expect(workflow, contains('Verify release decision packet'));
  });
}
