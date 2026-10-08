import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monitoring operations audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_monitoring_operations.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Monitoring operations audit: Worker observability, telemetry boundary, error visibility drill and open owner gates verified.',
      ),
    );
  });

  test('release verification runbook and CI include monitoring audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_monitoring_operations.mjs'));
    expect(runbook, contains('docs/PRODUCTION_ERROR_VISIBILITY_DRILL.md'));
    expect(workflow, contains('node tool/audit_monitoring_operations.mjs'));
    expect(workflow, contains('Verify monitoring operations readiness'));
  });

  test('production error visibility drill keeps private data out of logs', () {
    final drill = File(
      'docs/PRODUCTION_ERROR_VISIBILITY_DRILL.md',
    ).readAsStringSync();
    final monitoring = File(
      'docs/RELEASE_MONITORING_EVIDENCE.md',
    ).readAsStringSync();
    final candidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final scenario in [
      'Web route failure visibility',
      'Multiplayer capability-denial visibility',
      'Trading or battle safety failure visibility',
      'Support and account-deletion link failure visibility',
      'Alert delivery and rollback handoff',
    ]) {
      expect(drill, contains(scenario), reason: scenario);
    }

    for (final privateData in [
      'player progress',
      'identity details',
      'Save Transfer files',
      'custom art',
      'animal rosters',
      'preset-message contents',
      'child/guardian information',
    ]) {
      expect(drill, contains(privateData), reason: privateData);
    }

    expect(monitoring, contains('docs/PRODUCTION_ERROR_VISIBILITY_DRILL.md'));
    expect(candidate, contains('Production error visibility drill result'));
  });
}
