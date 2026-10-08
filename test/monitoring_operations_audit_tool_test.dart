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
        'Monitoring operations audit: Worker observability, telemetry boundary and open owner gates verified.',
      ),
    );
  });

  test('release verification runbook and CI include monitoring audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();

    expect(runbook, contains('node tool/audit_monitoring_operations.mjs'));
    expect(workflow, contains('node tool/audit_monitoring_operations.mjs'));
    expect(workflow, contains('Verify monitoring operations readiness'));
  });
}
