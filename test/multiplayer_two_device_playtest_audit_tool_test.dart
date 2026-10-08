import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multiplayer two-device playtest audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_multiplayer_two_device_playtest.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Multiplayer two-device playtest audit: battle, matchmaking, trading, block/report and stop-condition script verified.',
      ),
    );
  });

  test('release docs and CI include multiplayer two-device playtest audit', () {
    final script = File('docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md').readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(script, contains('Battle invitation path'));
    expect(script, contains('Trading path'));
    expect(script, contains('Stop conditions'));
    expect(runbook, contains('node tool/audit_multiplayer_two_device_playtest.mjs'));
    expect(workflow, contains('node tool/audit_multiplayer_two_device_playtest.mjs'));
    expect(evidenceIndex, contains('docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md'));
  });
}
