import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release reliability audit passes for current evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_release_reliability.mjs',
    ]);

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains(
        'Release reliability audit: offline startup, interrupted saves, recovery, settings, legacy saves and release-surface evidence verified.',
      ),
    );
  });

  test('release verification runbook and CI include release reliability audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_release_reliability.mjs'));
    expect(workflow, contains('node tool/audit_release_reliability.mjs'));
    expect(workflow, contains('Verify release reliability evidence'));
  });
}
