import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cross-platform acceptance audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_cross_platform_acceptance.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Cross-platform acceptance audit: candidate identity, platform rows and supporting evidence verified.',
      ),
    );
  });

  test('release verification runbook and CI include cross-platform audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_cross_platform_acceptance.mjs'));
    expect(workflow, contains('node tool/audit_cross_platform_acceptance.mjs'));
    expect(workflow, contains('Verify cross-platform acceptance template'));
  });
}
