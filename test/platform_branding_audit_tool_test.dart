import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform branding audit passes for current source and targets', () async {
    final result = await Process.run('node', [
      'tool/audit_platform_branding.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Platform branding audit: 15 PNG targets and 1 icon targets verified'),
    );
  });

  test('release verification runbook and CI include platform branding audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_platform_branding.mjs'));
    expect(workflow, contains('node tool/audit_platform_branding.mjs'));
    expect(workflow, contains('Verify platform branding readiness'));
  });
}
