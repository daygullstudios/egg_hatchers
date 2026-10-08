import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('custom egg retirement audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_custom_eggs_retired.mjs',
    ]);

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(
      result.stdout.toString(),
      contains(
        'Custom egg retirement audit: dormant legacy records, save transfer compatibility and built-in-only hatch pipeline verified.',
      ),
    );
  });

  test('release verification runbook and CI include custom egg retirement audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_custom_eggs_retired.mjs'));
    expect(workflow, contains('node tool/audit_custom_eggs_retired.mjs'));
    expect(workflow, contains('Verify custom eggs are retired'));
  });
}
