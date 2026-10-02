import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed beta plan stays behind release gates', () {
    final plan = File('docs/CLOSED_BETA_PLAN.md').readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final decisions = File(
      'docs/RELEASE_DECISION_PACKET.md',
    ).readAsStringSync();

    expect(plan, contains('does not authorize'));
    expect(plan, contains('Gates 2 through 7'));
    expect(plan, contains('release owner'));
    expect(plan, contains('rollback decision maker'));
    expect(plan, contains('Family/privacy review'));
    expect(plan, contains('ordinary fresh accounts'));
    expect(roadmap, contains('### 9. Closed beta'));
    expect(decisions, contains('Launch platforms'));
  });

  test('closed beta plan covers tester scope and reporting safety', () {
    final plan = File('docs/CLOSED_BETA_PLAN.md').readAsStringSync();

    const requiredPhrases = [
      'fresh-player tester',
      'returning-player tester',
      'multiplayer/trading pair',
      'narrow-phone layout tester',
      'preset-only',
      'one online battle',
      'one trade',
      'blocked-player/report flow',
      'Do not ask testers to send passwords',
      'Save Transfer file',
    ];

    for (final phrase in requiredPhrases) {
      expect(plan, contains(phrase), reason: phrase);
    }
  });

  test('closed beta plan defines triage and exit requirements', () {
    final plan = File('docs/CLOSED_BETA_PLAN.md').readAsStringSync();

    for (final severity in ['Critical', 'High', 'Medium', 'Low']) {
      expect(plan, contains('$severity:'), reason: severity);
    }
    expect(plan, contains('block release'));
    expect(plan, contains('focused retest'));
    expect(plan, contains('complete candidate pass'));
    expect(plan, contains('Rollback to the previous protected version'));
    expect(plan, contains('Tester message template'));
  });
}
