import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public policy link audit passes for current public site', () async {
    final result = await Process.run('node', [
      'tool/audit_public_policy_links.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Public policy link audit: 6 pages and 5 routes verified'),
    );
  });

  test('release verification runbook and CI include public policy audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_public_policy_links.mjs'));
    expect(workflow, contains('node tool/audit_public_policy_links.mjs'));
    expect(workflow, contains('Verify public policy and support links'));
  });
}
