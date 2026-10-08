import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('audio release audit passes for current shipped audio', () async {
    final result = await Process.run('node', [
      'tool/audit_audio_release.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Audio release audit: 3 music tracks, 4 boss sections and 29 WAV loudness checks verified',
      ),
    );
  });

  test('release verification runbook and CI include audio release audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_audio_release.mjs'));
    expect(workflow, contains('node tool/audit_audio_release.mjs'));
    expect(workflow, contains('Verify audio release readiness'));
  });
}
