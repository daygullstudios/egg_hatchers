import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed beta findings template captures candidate and coverage', () {
    final template = File(
      'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md',
    ).readAsStringSync();
    final plan = File('docs/CLOSED_BETA_PLAN.md').readAsStringSync();

    for (final field in [
      'Candidate name',
      'Git commit',
      'Build/platform',
      'Protected playtest version',
      'Multiplayer Worker version',
      'Release owner',
      'Triage owner',
      'Fresh-player testers',
      'Returning/import testers',
      'Multiplayer/trading pairs',
      'Narrow-phone testers',
    ]) {
      expect(template, contains(field), reason: field);
    }

    expect(plan, contains('fresh-player tester'));
    expect(plan, contains('multiplayer/trading pair'));
  });

  test('closed beta findings template captures safe issue triage', () {
    final template = File(
      'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md',
    ).readAsStringSync();
    final plan = File('docs/CLOSED_BETA_PLAN.md').readAsStringSync();

    for (final field in [
      'Severity: Critical / High / Medium / Low',
      "Status: New / Investigating / Fixed / Retest passed / Accepted risk / Won't fix",
      'Progress/account/reward impact',
      'Reproduction steps',
      'Private data received',
      'Fix commit',
      'Focused retest result',
      'Release decision',
    ]) {
      expect(template, contains(field), reason: field);
    }

    expect(template, contains('not fill it with real tester details'));
    expect(plan, contains('Do not ask testers to send passwords'));
  });

  test('closed beta findings template keeps release exit gates visible', () {
    final template = File(
      'docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md',
    ).readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final releaseCandidate = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    for (final field in [
      'Critical findings open',
      'High findings open',
      'Account/save/multiplayer regressions open',
      'Privacy/family-safety findings open',
      'Candidate pass after last risky fix',
      'Rollback test after candidate',
    ]) {
      expect(template, contains(field), reason: field);
    }

    expect(roadmap, contains('[ ] Track crashes, save failures, progression confusion and multiplayer abuse.'));
    expect(roadmap, contains('[ ] Resolve all critical and high-priority findings.'));
    expect(releaseCandidate, contains('Critical risks'));
    expect(releaseCandidate, contains('High risks'));
  });
}

