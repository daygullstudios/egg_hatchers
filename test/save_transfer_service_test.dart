import 'dart:convert';

import 'package:egg_hatchers/services/account_session_store.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/save_import_fixture.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    writeActiveAccountId('original');
  });

  test(
    'review and staging never replace existing players or session',
    () async {
      final storage = ImportMemoryStorage({'keep': 'original'});
      final service = SaveTransferService(storage: storage);
      final preview = service.inspectSave(importFixture());
      expect(preview.players.single.displayName, 'Mock Explorer');
      expect(preview.progress['imported']?.coins, 420);
      expect(storage.operations, isEmpty);
      await service.stageImport(preview);
      expect(storage.values['keep'], 'original');
      expect(readActiveAccountId(), 'original');
      expect(storage.operations, ['write:${SaveTransferService.pendingKey}']);
      await service.cancelPendingImport();
      expect(storage.values, {'keep': 'original'});
    },
  );

  test(
    'a second staging attempt cannot replace the reviewed pending file',
    () async {
      final storage = ImportMemoryStorage();
      final service = SaveTransferService(storage: storage);
      final source = importFixture();
      await service.stageImport(service.inspectSave(source));
      await expectLater(
        service.stageImport(service.inspectSave(importFixture(coins: 999))),
        throwsA(isA<SaveTransferException>()),
      );
      expect(storage.values[SaveTransferService.pendingKey], source);
    },
  );

  test(
    'checked replacement restores supported types but not identity or ancestry',
    () async {
      final storage = ImportMemoryStorage({
        'stale': 'remove',
        '${DeviceGuestSlotStore.keyPrefix}generation': 5,
        '${DeviceGuestSlotStore.keyPrefix}firebase_uid': 'original-identity',
        'egg_hatchers.sync_checkpoint.v1.account.original': 'old ancestry',
      });
      final service = SaveTransferService(storage: storage);
      await service.stageImport(
        service.inspectSave(
          importFixture(
            extra: {
              'sound': {'type': 'bool', 'value': true},
              'volume': {'type': 'double', 'value': 0.75},
              'counter': {'type': 'int', 'value': 7},
              'list': {
                'type': 'stringList',
                'value': ['one', 'two'],
              },
              '${DeviceGuestSlotStore.keyPrefix}firebase_uid': {
                'type': 'string',
                'value': 'foreign-identity',
              },
              'egg_hatchers.sync_checkpoint.v1.account.imported': {
                'type': 'string',
                'value': 'foreign ancestry',
              },
            },
          ),
        ),
      );
      expect(
        await service.finishPendingImport(),
        SaveImportBootResult.imported,
      );
      expect(storage.values['stale'], isNull);
      expect(storage.values['sound'], true);
      expect(storage.values['volume'], 0.75);
      expect(storage.values['counter'], 7);
      expect(storage.values['list'], ['one', 'two']);
      expect(storage.values['${DeviceGuestSlotStore.keyPrefix}generation'], 6);
      expect(
        storage.values['${DeviceGuestSlotStore.keyPrefix}firebase_uid'],
        isNull,
      );
      expect(
        storage.values.keys.where((key) => key.contains('sync_checkpoint')),
        isEmpty,
      );
      expect(readActiveAccountId(), 'imported');
      expect(await service.hasPendingImport(), false);
      final exported = jsonDecode(await service.exportSave()) as Map;
      expect(exported['format'], 'egg_hatchers_save');
      expect(
        (exported['preferences'] as Map).keys.where(
          (key) =>
              key.toString().startsWith('nestarium.import.') ||
              DeviceGuestSlotStore.ownsKey(key),
        ),
        isEmpty,
      );
    },
  );

  test(
    'valid pre-directory legacy save remains importable through real preferences',
    () async {
      final service = SaveTransferService();
      final source = jsonEncode({
        'format': 'egg_hatchers_save',
        'version': 1,
        'preferences': {
          'egg_hatchers_player_state': {
            'type': 'string',
            'value':
                '{"coins":123,"ownedAnimals":[],"lastSavedTime":"2026-09-06T12:00:00Z"}',
          },
          'egg_hatchers.settings.audio.music_enabled.v1': {
            'type': 'bool',
            'value': false,
          },
        },
      });
      final preview = service.inspectSave(source);
      expect(preview.hasLegacyProgress, true);
      await service.stageImport(preview);
      expect(
        await service.finishPendingImport(),
        SaveImportBootResult.imported,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('egg_hatchers_player_state')!)['coins'],
        123,
      );
      expect(
        prefs.getBool('egg_hatchers.settings.audio.music_enabled.v1'),
        false,
      );
    },
  );

  for (final entry in <String, Object>{
    'playerAccounts': {'type': 'string', 'value': '[{"id":"incomplete"}]'},
    'egg_hatchers_player_state_account_imported': {
      'type': 'string',
      'value': '{"coins":123}',
    },
    'customEggs.account.imported': {'type': 'string', 'value': '[false]'},
    'customSprite.account.imported.chicken': {
      'type': 'string',
      'value': '{"size":24,"pixels":[0]}',
    },
    'spriteRatingClaims.account.imported': {
      'type': 'string',
      'value': '{"chicken":false}',
    },
    'spriteReferenceOverlayUnlocks.account.imported': {
      'type': 'string',
      'value': '{"chicken":"yes"}',
    },
    'egg_hatchers.settings.audio.music_enabled.v1': {
      'type': 'string',
      'value': 'true',
    },
    'badPreference': {'type': 'int', 'value': 'seven'},
  }.entries) {
    test('rejects unreadable ${entry.key} without mutations', () {
      final storage = ImportMemoryStorage({'keep': 'original'});
      final service = SaveTransferService(storage: storage);
      expect(
        () =>
            service.inspectSave(importFixture(extra: {entry.key: entry.value})),
        throwsA(isA<SaveTransferException>()),
      );
      expect(storage.operations, isEmpty);
      expect(storage.values, {'keep': 'original'});
    });
  }

  test(
    'pending input is validated again before the recovery snapshot or replacement',
    () async {
      final storage = ImportMemoryStorage({
        'keep': 'original',
        SaveTransferService.pendingKey: '{}',
      });
      final service = SaveTransferService(storage: storage);
      await expectLater(
        service.finishPendingImport(),
        throwsA(isA<SaveTransferException>()),
      );
      expect(storage.operations, isEmpty);
      await service.cancelPendingImport();
      expect(storage.values, {'keep': 'original'});
    },
  );

  test('unverified recovery copy blocks every destructive write', () async {
    final storage = ImportMemoryStorage({'keep': 'original'})
      ..wrongReadBack = true;
    final service = SaveTransferService(storage: storage);
    await service.stageImport(service.inspectSave(importFixture()));
    await expectLater(
      service.finishPendingImport(),
      throwsA(isA<SaveTransferException>()),
    );
    expect(storage.values['keep'], 'original');
    expect(storage.operations.where((op) => op.startsWith('remove:')), isEmpty);
  });

  test(
    'each failed mutation either rolls back or leaves a recoverable restart',
    () async {
      final baseline = ImportMemoryStorage({'keep': 'original'});
      final base = SaveTransferService(storage: baseline);
      await base.stageImport(base.inspectSave(importFixture()));
      baseline.mutations = 0;
      await base.finishPendingImport();
      final count = baseline.mutations;
      for (var failure = 1; failure <= count; failure++) {
        writeActiveAccountId('original');
        final storage = ImportMemoryStorage({'keep': 'original'});
        final service = SaveTransferService(storage: storage);
        await service.stageImport(service.inspectSave(importFixture()));
        storage.mutations = 0;
        storage.failAt = failure;
        try {
          await service.finishPendingImport();
        } on SaveTransferException {
          /* bootstrap stays blocked */
        }
        storage.failAt = null;
        // Cancellation also rolls a retained recovery journal back, never starts
        // another import after a preparation-stage failure.
        await SaveTransferService(storage: storage).cancelPendingImport();
        expect(storage.values, {
          'keep': 'original',
        }, reason: 'failure $failure');
        expect(readActiveAccountId(), 'original', reason: 'failure $failure');
      }
    },
  );

  test(
    'interrupted replacement retains journal and restores exact original identity on restart',
    () async {
      final original = <String, Object>{
        'keep': 'original',
        '${DeviceGuestSlotStore.keyPrefix}generation': 9,
        '${DeviceGuestSlotStore.keyPrefix}firebase_uid': 'original-identity',
        'egg_hatchers.sync_checkpoint.v1.account.original': 'original ancestry',
      };
      final storage = ImportMemoryStorage(original);
      final service = SaveTransferService(storage: storage);
      await service.stageImport(service.inspectSave(importFixture()));
      storage.mutations = 0;
      storage.failAt = 3;
      storage.persistFailure = true;
      await expectLater(
        service.finishPendingImport(),
        throwsA(isA<SaveTransferException>()),
      );
      expect(storage.values.containsKey(SaveTransferService.recoveryKey), true);
      storage.failAt = null;
      expect(
        await SaveTransferService(storage: storage).finishPendingImport(),
        SaveImportBootResult.originalRestored,
      );
      expect(storage.values, original);
      expect(readActiveAccountId(), 'original');
    },
  );

  test(
    'ambiguous commit removal never starts rollback without its journal',
    () async {
      final storage = ImportMemoryStorage({'keep': 'original'});
      final service = SaveTransferService(storage: storage);
      await service.stageImport(service.inspectSave(importFixture()));
      storage.falseAfterRemoval = true;
      await expectLater(
        service.finishPendingImport(),
        throwsA(isA<SaveTransferException>()),
      );
      expect(storage.values['keep'], isNull);
      expect(
        storage.operations.last,
        'remove:${SaveTransferService.recoveryKey}',
      );
      expect(
        await SaveTransferService(storage: storage).finishPendingImport(),
        SaveImportBootResult.none,
      );
      expect(readActiveAccountId(), 'imported');
    },
  );
}
