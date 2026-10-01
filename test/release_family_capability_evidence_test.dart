import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('family capability evidence references live safety coverage', () {
    final evidence = File(
      'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md',
    ).readAsStringSync();
    final requiredEvidence = {
      'cloudflare/multiplayer/test/worker.test.ts': [
        'fails closed unless trusted capability claims use the current policy',
        'fails closed in registry mode and accepts only a resolved hosted capability',
        'enforces battle and trade permissions independently after connection',
        'matches two verified identities without disclosing supplied names or ids',
        'records preset reports and persists two-way matchmaking blocks',
        'retires a live hosted session when its capability decision is revoked',
      ],
      'cloudflare/multiplayer/test/safety_authority.test.ts': [
        'stores idempotent pseudonymous reports and prunes them after retention',
        'issues, expires, and revokes bounded capability decisions',
      ],
      'cloudflare/multiplayer/src/safety_authority.ts': [
        'profile discovery is not approved in family policy v1',
        'preset messages require trading permission',
      ],
      'test/trading_service_test.dart': [
        'hosted trading authenticates and consumes only server inventory',
        'TradeChatTag.isThisFair',
        'TradeChatTag.requestAnimal',
      ],
      'test/multiplayer_service_test.dart': [
        'hosted battle sends preset player safety actions',
      ],
    };

    for (final entry in requiredEvidence.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(evidence, contains(entry.key), reason: entry.key);
      expect(source, isNotEmpty, reason: entry.key);
      for (final phrase in entry.value) {
        expect(evidence, contains(phrase), reason: phrase);
        expect(source, contains(phrase), reason: phrase);
      }
    }

    expect(evidence, contains('technical evidence only'));
    expect(evidence, contains('professional audience/privacy review'));
    expect(evidence, contains('parent-managed permissions'));
  });
}
