import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multiplayer load capacity audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_multiplayer_load_capacity.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Multiplayer load/capacity audit: launch-size plan, measurements, pass criteria and stop conditions verified.',
      ),
    );
  });

  test('release docs and CI include multiplayer load capacity audit', () {
    final rehearsal = File('docs/MULTIPLAYER_LOAD_CAPACITY_REHEARSAL.md').readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(rehearsal, contains('Load plan'));
    expect(rehearsal, contains('Pass criteria'));
    expect(rehearsal, contains('Stop conditions'));
    expect(runbook, contains('node tool/audit_multiplayer_load_capacity.mjs'));
    expect(workflow, contains('node tool/audit_multiplayer_load_capacity.mjs'));
    expect(evidenceIndex, contains('docs/MULTIPLAYER_LOAD_CAPACITY_REHEARSAL.md'));
  });
}
