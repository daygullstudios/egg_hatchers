import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release code review evidence references live regression coverage', () {
    final evidence = File('docs/RELEASE_CODE_REVIEW.md').readAsStringSync();
    final requiredEvidence = {
      'test/save_transfer_service_test.dart': [
        'Import review and staging never replace existing players',
        'Legacy files with dormant custom eggs remain importable',
      ],
      'test/progress_sync_service_test.dart': [
        'Changed cloud state blocks both reviewed device and cloud replacement',
        'Unknown cloud state never authorizes an upload',
      ],
      'test/account_protection_service_test.dart': [
        'Opening an existing Google account clears old sync ancestry',
        'Replacement guests receive fresh identity after local removal',
      ],
      'test/multiplayer_service_test.dart': [
        'Released hosted multiplayer rejects a missing identity token',
        'Hosted settlement is parsed and acknowledged explicitly',
      ],
      'test/trading_service_test.dart': [
        'Released hosted trading rejects a missing identity token',
        'Trading uses preset messages',
      ],
      'cloudflare/multiplayer/test/worker.test.ts': [
        'Missing Firebase tokens',
        'Online Roster trades commit exactly once',
      ],
      'cloudflare/multiplayer/src/index.ts': [
        'Client-supplied `X-Nestarium-Uid`',
        'trusted values after verification',
      ],
    };

    for (final entry in requiredEvidence.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(evidence, contains(entry.key), reason: entry.key);
      expect(source, isNotEmpty, reason: entry.key);
      for (final phrase in entry.value) {
        expect(evidence, contains(phrase), reason: phrase);
      }
    }

    expect(
      evidence,
      contains('the later production security review'),
    );
    expect(
      evidence,
      contains('Perform the final authentication, multiplayer and trading security review'),
    );
  });
}
