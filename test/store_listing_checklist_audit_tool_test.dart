import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store listing checklist audit passes for current release evidence',
    () async {
      final result = await Process.run('node', [
        'tool/audit_store_listing_checklist.mjs',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout.toString(),
        contains(
          'Store listing checklist audit: metadata, screenshots, ratings, privacy answers and open store gates verified.',
        ),
      );
    },
  );

  test('release verification runbook and CI include store listing audit', () {
    final runbook = File(
      'docs/RELEASE_VERIFICATION_RUNBOOK.md',
    ).readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_store_listing_checklist.mjs'));
    expect(workflow, contains('node tool/audit_store_listing_checklist.mjs'));
    expect(workflow, contains('Verify store listing checklist'));
  });
}
