import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed beta readiness audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_closed_beta_readiness.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Closed beta readiness audit: entry gates, tester safety, triage and exit blockers verified.',
      ),
    );
  });

  test('release verification runbook and CI include closed beta audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_closed_beta_readiness.mjs'));
    expect(workflow, contains('node tool/audit_closed_beta_readiness.mjs'));
    expect(workflow, contains('Verify closed beta readiness template'));
  });
}
