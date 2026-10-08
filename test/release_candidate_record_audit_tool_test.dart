import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release candidate record audit passes for current template', () async {
    final result = await Process.run('node', [
      'tool/audit_release_candidate_record.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Release candidate record audit: identity, artifacts, verification, rollback, privacy, risks and approvals verified.',
      ),
    );
  });

  test('release verification runbook and CI include candidate record audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_release_candidate_record.mjs'));
    expect(workflow, contains('node tool/audit_release_candidate_record.mjs'));
    expect(workflow, contains('Verify release candidate record template'));
  });
}
