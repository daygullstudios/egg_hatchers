import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('music rights and listening audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_music_rights_listening.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Music rights/listening audit: source records, boss loop checks, whole-game mix and stop conditions verified.',
      ),
    );
  });

  test('release docs and CI include music rights listening audit', () {
    final signoff = File('docs/MUSIC_RIGHTS_AND_LISTENING_SIGNOFF.md').readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(signoff, contains('Music source records to fill'));
    expect(signoff, contains('Normal boss listening pass'));
    expect(signoff, contains('docs/PLATFORM_AUDIO_BEHAVIOR_MATRIX.md'));
    expect(signoff, contains('Stop conditions'));
    expect(runbook, contains('node tool/audit_music_rights_listening.mjs'));
    expect(runbook, contains('docs/PLATFORM_AUDIO_BEHAVIOR_MATRIX.md'));
    expect(workflow, contains('node tool/audit_music_rights_listening.mjs'));
    expect(evidenceIndex, contains('docs/MUSIC_RIGHTS_AND_LISTENING_SIGNOFF.md'));
    expect(evidenceIndex, contains('docs/PLATFORM_AUDIO_BEHAVIOR_MATRIX.md'));
  });
}
