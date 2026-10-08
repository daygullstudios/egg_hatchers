import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('family privacy review intake audit passes', () async {
    final result = await Process.run('node', [
      'tool/audit_family_privacy_review_intake.mjs',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout.toString(),
      contains(
        'Family privacy review intake audit: review questions, evidence packet, acceptance criteria and stop conditions verified.',
      ),
    );
  });

  test('release docs and CI include family privacy review intake audit', () {
    final intake = File('docs/FAMILY_PRIVACY_REVIEW_INTAKE.md').readAsStringSync();
    final runbook = File('docs/RELEASE_VERIFICATION_RUNBOOK.md').readAsStringSync();
    final workflow = File('.github/workflows/verify.yml').readAsStringSync();
    final evidenceIndex = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    expect(intake, contains('Data and capability questions'));
    expect(intake, contains('Stop conditions'));
    expect(runbook, contains('node tool/audit_family_privacy_review_intake.mjs'));
    expect(workflow, contains('node tool/audit_family_privacy_review_intake.mjs'));
    expect(evidenceIndex, contains('docs/FAMILY_PRIVACY_REVIEW_INTAKE.md'));
  });
}
