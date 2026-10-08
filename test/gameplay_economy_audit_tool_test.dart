import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gameplay economy audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_gameplay_economy.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Gameplay economy audit: new-player path, economy tables, boss balance, DayGull, rewards and save stages verified.',
      ),
    );
  });

  test('release verification runbook and CI include gameplay economy audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_gameplay_economy.mjs'));
    expect(workflow, contains('node tool/audit_gameplay_economy.mjs'));
    expect(workflow, contains('Verify gameplay economy evidence'));
  });
}
