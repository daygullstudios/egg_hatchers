import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release evidence audit passes for current index', () async {
    final result = await Process.run('node', [
      'tool/audit_release_evidence.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Release evidence audit: 10 gates'),
    );
  });

  test('release verification runbook and CI include evidence audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_release_evidence.mjs'));
    expect(workflow, contains('node tool/audit_release_evidence.mjs'));
    expect(workflow, contains('Verify release evidence index'));
  });
}
