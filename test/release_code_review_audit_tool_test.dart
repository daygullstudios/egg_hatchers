import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release code review audit passes for current evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_release_code_review.mjs',
    ]);

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains(
        'Release code review audit: save integrity, sync, account protection, multiplayer, trading and worker trust evidence verified.',
      ),
    );
  });

  test('release verification runbook and CI include release code review audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_release_code_review.mjs'));
    expect(workflow, contains('node tool/audit_release_code_review.mjs'));
    expect(workflow, contains('Verify release code review evidence'));
  });
}
