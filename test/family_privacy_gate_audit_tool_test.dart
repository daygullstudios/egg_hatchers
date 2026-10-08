import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('family privacy gate audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_family_privacy_gate.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Family privacy gate audit: review blockers, fail-closed capabilities, preset safety and policy readiness verified.',
      ),
    );
  });

  test('release verification runbook and CI include family privacy audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_family_privacy_gate.mjs'));
    expect(workflow, contains('node tool/audit_family_privacy_gate.mjs'));
    expect(workflow, contains('Verify family privacy gate evidence'));
  });
}
