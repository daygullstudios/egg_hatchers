import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release security review references authentication boundaries', () {
    final review = File('docs/RELEASE_SECURITY_REVIEW.md').readAsStringSync();
    final auth = File('cloudflare/multiplayer/src/auth.ts').readAsStringSync();
    final worker = File(
      'cloudflare/multiplayer/src/index.ts',
    ).readAsStringSync();
    final multiplayerClient = File(
      'lib/services/multiplayer_service.dart',
    ).readAsStringSync();
    final tradingClient = File(
      'lib/services/trading_service.dart',
    ).readAsStringSync();

    expect(review, contains('No new critical or high-severity'));
    expect(review, contains('firebase-auth.<token>'));
    expect(auth, contains('verifyFirebaseSession'));
    expect(auth, contains('trusted_registry'));
    expect(auth, contains('trusted_claims'));
    expect(worker, contains('headers.delete("X-Nestarium-Uid")'));
    expect(worker, contains('headers.delete("X-Nestarium-Capabilities")'));
    expect(multiplayerClient, contains('Hosted multiplayer is not released'));
    expect(tradingClient, contains('Hosted trading is not released'));
  });

  test('release security review references hosted battle and trade authority', () {
    final review = File('docs/RELEASE_SECURITY_REVIEW.md').readAsStringSync();
    final worker = File(
      'cloudflare/multiplayer/src/index.ts',
    ).readAsStringSync();
    final workerTest = File(
      'cloudflare/multiplayer/test/worker.test.ts',
    ).readAsStringSync();
    final multiplayerTest = File(
      'test/multiplayer_service_test.dart',
    ).readAsStringSync();
    final tradingTest = File('test/trading_service_test.dart').readAsStringSync();

    for (final phrase in [
      'Server-owned Online Roster inventory',
      'Trade completion is transactional',
      'Player communication remains preset-only',
      'WebSocket messages are size-limited and rate-limited',
      'Open release gates',
    ]) {
      expect(review, contains(phrase), reason: phrase);
    }

    expect(worker, contains('trustedBattleTeam'));
    expect(worker, contains('completeTrade'));
    expect(worker, contains('acknowledgeTrade'));
    expect(worker, contains('enforceRateLimit'));
    expect(workerTest, contains('owns the online roster and rejects a forged battle team'));
    expect(workerTest, contains('commits a two-sided Online Roster trade exactly once'));
    expect(multiplayerTest, contains('released hosted multiplayer rejects a missing identity token'));
    expect(tradingTest, contains('TradeChatTag.isThisFair'));
    expect(tradingTest, contains('TradeChatTag.requestAnimal'));
  });

  test('release roadmap records the completed security review', () {
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    expect(
      roadmap,
      contains('[x] Perform a security review of authentication, multiplayer and trading.'),
    );
  });
}
