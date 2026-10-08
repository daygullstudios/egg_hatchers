import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed beta readiness audit passes for current release evidence', () async {
    final result = await Process.run('node', [
      'tool/audit_closed_beta_readiness.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Closed beta readiness audit: entry gates, tester safety, triage and exit blockers verified.',
      ),
    );
  });

  test('release verification runbook and CI include closed beta audit', () {
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(runbook, contains('node tool/audit_closed_beta_readiness.mjs'));
    expect(runbook, contains('docs/CLOSED_BETA_COVERAGE_MATRIX.md'));
    expect(evidenceIndex, contains('docs/CLOSED_BETA_COVERAGE_MATRIX.md'));
    expect(workflow, contains('node tool/audit_closed_beta_readiness.mjs'));
    expect(workflow, contains('Verify closed beta readiness template'));
  });

  test('closed beta coverage matrix records required assignment mix', () {
    final matrix = File('docs/CLOSED_BETA_COVERAGE_MATRIX.md').readAsStringSync();
    final plan = File('docs/CLOSED_BETA_PLAN.md').readAsStringSync();
    final findings = File(
      'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md',
    ).readAsStringSync();

    for (final coverage in [
      'Fresh-player path',
      'Returning/import path',
      'Multiplayer/trading pair',
      'Narrow phone layout',
      'Larger screen/tablet',
      'Selected web browser',
      'School/work or restricted network',
      'Parent/guardian-supervised tester',
    ]) {
      expect(matrix, contains(coverage), reason: coverage);
    }

    expect(matrix, contains('not an invitation list'));
    expect(matrix, contains('Do not record passwords'));
    expect(matrix, contains('private Save Transfer files'));
    expect(plan, contains('docs/CLOSED_BETA_COVERAGE_MATRIX.md'));
    expect(findings, contains('Closed beta coverage matrix reference'));
  });
}
