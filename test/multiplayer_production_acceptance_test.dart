import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multiplayer production acceptance covers trusted session checks', () {
    final checklist = File(
      'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
    ).readAsStringSync();
    final securityReview = File('docs/RELEASE_SECURITY_REVIEW.md').readAsStringSync();
    final auth = File('cloudflare/multiplayer/src/auth.ts').readAsStringSync();
    final worker = File('cloudflare/multiplayer/src/index.ts').readAsStringSync();

    for (final phrase in [
      'nestarium-v1',
      'firebase-auth.<token>',
      'trusted-registry decisions fail',
      'closed',
      'Client-supplied identity headers are stripped',
      'Duplicate sessions for the same UID retire the older session',
      'Hosted clients fail closed',
      'Battle, trading and preset-message capabilities are enforced separately',
    ]) {
      expect(checklist, contains(phrase), reason: phrase);
    }

    expect(securityReview, contains('Complete trusted authenticated sessions'));
    expect(auth, contains('verifyFirebaseSession'));
    expect(auth, contains('trusted_registry'));
    expect(worker, contains('headers.delete("X-Nestarium-Uid")'));
    expect(worker, contains('headers.delete("X-Nestarium-Capabilities")'));
  });

  test('multiplayer production acceptance covers two-device play and capacity', () {
    final checklist = File(
      'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
    ).readAsStringSync();
    final readme = File('cloudflare/multiplayer/README.md').readAsStringSync();
    final workerTest = File(
      'cloudflare/multiplayer/test/worker.test.ts',
    ).readAsStringSync();

    for (final phrase in [
      'two ordinary tester accounts',
      'Direct battle invitation succeeds',
      'Random matchmaking succeeds or times out gracefully',
      'Battle reconnect window works',
      'Battle reward receipt is delivered once',
      'Direct trade invitation succeeds',
      'Trade cancel/disconnect preserves both rosters',
      'Completed trade moves both roster items exactly once',
      'Preset trade messages work; open text is unavailable',
      'Expected 503/Retry-After behavior at guardrail',
    ]) {
      expect(checklist, contains(phrase), reason: phrase);
    }

    expect(readme, contains('32-session guardrail'));
    expect(readme, contains('503'));
    expect(workerTest, contains('accepts and isolates 32 protected sessions'));
    expect(workerTest, contains('retires a duplicate identity session'));
  });

  test('multiplayer production acceptance keeps roadmap gates open', () {
    final checklist = File(
      'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
    ).readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();

    for (final item in [
      '[ ] Complete trusted authenticated sessions in the production environment.',
      '[ ] Run two-device internet play outside the developer network.',
      '[ ] Run load and capacity tests for the intended launch size.',
    ]) {
      expect(roadmap, contains(item), reason: item);
    }

    expect(checklist, contains('selected launch environment'));
    expect(checklist, contains('selected launch size'));
    expect(checklist, contains('family/privacy capability model'));
  });
}

