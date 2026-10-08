import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release evidence index covers every roadmap gate', () {
    final index = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    for (final gate in [
      '## 1. Scope and ownership',
      '## 2. Accounts and save recovery',
      '## 3. Family safety and privacy',
      '## 4. Multiplayer and trading',
      '## 5. Gameplay and economy',
      '## 6. Visuals, audio and accessibility',
      '## 7. Reliability and security',
      '## 8. Platform and store readiness',
      '## 9. Closed beta',
      '## 10. Release candidate and launch',
    ]) {
      expect(index, contains(gate), reason: gate);
    }

    expect(index, contains('does not close any unchecked roadmap item'));
    expect(index, contains('exact candidate build'));
  });

  test('release evidence index links owner-dependent release records', () {
    final index = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    for (final file in [
      'docs/RELEASE_DECISION_PACKET.md',
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
      'docs/RELEASE_VERIFICATION_RUNBOOK.md',
      'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
      'docs/ROLLBACK_REHEARSAL_TEMPLATE.md',
      'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
    ]) {
      expect(index, contains(file), reason: file);
      expect(File(file).existsSync(), isTrue, reason: file);
    }
  });

  test('release evidence index links safety multiplayer and asset evidence', () {
    final index = File('docs/RELEASE_EVIDENCE_INDEX.md').readAsStringSync();

    for (final file in [
      'docs/FAMILY_AUDIENCE_V1.md',
      'docs/PUBLIC_POLICY_READINESS.md',
      'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
      'docs/RELEASE_SECURITY_REVIEW.md',
      'docs/AUDIO_RELEASE_ACCEPTANCE.md',
      'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
      'docs/PLATFORM_STORE_READINESS.md',
      'docs/CLOSED_BETA_PLAN.md',
    ]) {
      expect(index, contains(file), reason: file);
      expect(File(file).existsSync(), isTrue, reason: file);
    }
  });
}
