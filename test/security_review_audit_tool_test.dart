import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('security review audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_security_review.mjs',
    ]);

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains(
        'Security review audit: authentication, hosted authority, trading, reports, blocks and open production gates verified.',
      ),
    );
  });

  test('release verification runbook and CI include security review audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_security_review.mjs'));
    expect(workflow, contains('node tool/audit_security_review.mjs'));
    expect(workflow, contains('Verify security review evidence'));
  });
}
