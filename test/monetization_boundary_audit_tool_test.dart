import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monetization boundary audit passes for current release contract', () async {
    final result = await Process.run('node', [
      'tool/audit_monetization_boundary.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Monetization boundary audit: default-off ads, purchase gates, placement limits and release blockers verified.',
      ),
    );
  });

  test('release verification runbook and CI include monetization audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_monetization_boundary.mjs'));
    expect(workflow, contains('node tool/audit_monetization_boundary.mjs'));
    expect(workflow, contains('Verify monetization remains dormant'));
  });
}
