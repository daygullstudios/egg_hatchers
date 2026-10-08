import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gradual release monitoring audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_gradual_release_monitoring.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Gradual release monitoring audit: rollout checks, rollback triggers and exit evidence verified.',
      ),
    );
  });

  test('release docs and CI include gradual release monitoring audit', () {
    final checklist = File(
      'docs/GRADUAL_RELEASE_MONITORING_CHECKLIST.md',
    ).readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(checklist, contains('First-hour checks'));
    expect(checklist, contains('Pause or rollback triggers'));
    expect(runbook, contains('node tool/audit_gradual_release_monitoring.mjs'));
    expect(workflow, contains('node tool/audit_gradual_release_monitoring.mjs'));
    expect(evidenceIndex, contains('docs/GRADUAL_RELEASE_MONITORING_CHECKLIST.md'));
  });
}
