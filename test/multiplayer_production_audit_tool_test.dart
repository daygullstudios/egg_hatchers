import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multiplayer production audit passes for current guarded launch state', () async {
    final result = await Process.run('node', [
      'tool/audit_multiplayer_production.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains('Multiplayer production audit: trusted sessions'),
    );
  });

  test('release verification runbook and CI include multiplayer production audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_multiplayer_production.mjs'));
    expect(workflow, contains('node tool/audit_multiplayer_production.mjs'));
    expect(workflow, contains('Verify multiplayer production readiness'));
  });
}
