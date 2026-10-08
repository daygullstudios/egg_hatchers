import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform store audit passes for current gated store readiness', () async {
    final result = await Process.run('node', [
      'tool/audit_platform_store.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Platform store audit: Android signing guard'),
    );
  });

  test('release verification runbook and CI include platform store audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_platform_store.mjs'));
    expect(workflow, contains('node tool/audit_platform_store.mjs'));
    expect(workflow, contains('Verify platform store readiness'));
  });
}
