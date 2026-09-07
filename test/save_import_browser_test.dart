@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:convert';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/services/device_settings_store.dart';
import 'package:egg_hatchers/models/progress_sync_checkpoint.dart';
import 'package:egg_hatchers/services/progress_sync_checkpoint_store.dart';
import 'package:egg_hatchers/services/progress_recovery_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/saved_player_directory.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/save_storage_lease.dart';
import 'package:egg_hatchers/services/save_transfer_file_web.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/services/unsaved_exit_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:web/web.dart' as web;
import 'helpers/save_import_fixture.dart';

void main() {
  SharedPreferencesPlugin.registerWith(null);
  test(
    'browser settings ignore optimistic cache and retry uncertain writes without repeating them',
    () async {
      const key = DeviceSettingsStore.musicEnabledKey;
      final storage = _UncertainCheckpointStorage({key});
      final store = DeviceSettingsStore(storage: storage);
      try {
        expect(await store.writeMusicEnabled(false), true);
        final prefs = await SharedPreferences.getInstance();
        web.window.localStorage.setItem('flutter.$key', jsonEncode(true));
        expect(prefs.getBool(key), false);
        expect((await store.read()).musicEnabled, true);
        storage.uncertain = true;
        expect(await store.writeMusicEnabled(false), false);
        expect(store.needsAttention, true);
        final attempts = storage.writes;
        storage.uncertain = false;
        await store.retry();
        expect(storage.writes, attempts);
        expect(store.hasUnsavedChanges, false);
        expect((await store.read()).musicEnabled, false);
      } finally {
        store.dispose();
        await storage.remove(key);
      }
    },
  );
  test(
    'browser checkpoints use fresh backend reads and verify uncertain writes',
    () async {
      const id = 'mock-checkpoint-browser';
      const key = 'egg_hatchers.sync_checkpoint.v1.account.$id';
      final storage = _UncertainCheckpointStorage({key});
      final store = ProgressSyncCheckpointStore(
        accountId: id,
        storage: storage,
      );
      ProgressSyncCheckpoint record(int revision) => ProgressSyncCheckpoint(
        contentFingerprint:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        cloudRevision: revision,
        recordedAt: DateTime.utc(2026, 9, 7),
      );
      try {
        await store.write(record(1));
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(key);
        web.window.localStorage.setItem(
          'flutter.$key',
          jsonEncode(jsonEncode(record(2).toJson())),
        );
        expect(prefs.getString(key), cached);
        expect((await store.read())!.cloudRevision, 2);
        storage.uncertain = true;
        await expectLater(
          store.write(record(3)),
          throwsA(isA<CheckpointStorageException>()),
        );
        final attempts = storage.writes;
        storage.uncertain = false;
        await store.write(record(3));
        expect(storage.writes, attempts);
        expect((await store.read())!.cloudRevision, 3);
        await store.clear();
        expect(await store.read(), isNull);
      } finally {
        await storage.remove(key);
      }
    },
  );
  test(
    'browser progress writes verify failure, retry and per-player locking without removing older progress',
    () async {
      const id = 'mock-write-failure';
      final key = ProgressRecoveryService.primaryKey(id);
      final storage = _RejectingProgressStorage(key);
      final saves = SaveService(accountId: id, storage: storage);
      try {
        await saves.save(GameData.startingPlayerState().copyWith(coins: 321));
        storage.reject = true;
        await expectLater(
          saves.save(GameData.startingPlayerState().copyWith(coins: 999)),
          throwsA(isA<ProgressWriteException>()),
        );
        expect((await saves.load())!.coins, 321);
        storage.reject = false;
        await saves.retrySave(
          GameData.startingPlayerState().copyWith(coins: 999),
        );
        final values = await storage.readAll();
        expect(SaveService.decodeSnapshot(values[key])!.state.coins, 999);
        expect(
          SaveService.decodeSnapshot(values['${key}_backup'])!.state.coins,
          321,
        );
        final release = await acquireProgressWriteLease(key);
        try {
          await expectLater(
            acquireProgressWriteLease(key),
            throwsA(isA<SaveTransferException>()),
          );
        } finally {
          await release();
        }
      } finally {
        await storage.remove(key);
        await storage.remove('${key}_backup');
      }
    },
  );
  test(
    'browser unsaved-exit guard attaches and releases without permanently trapping navigation',
    () {
      setUnsavedExitGuard(true);
      final held = web.Event('beforeunload', web.EventInit(cancelable: true));
      web.window.dispatchEvent(held);
      expect(held.defaultPrevented, true);
      setUnsavedExitGuard(false);
      final resumed = web.Event(
        'beforeunload',
        web.EventInit(cancelable: true),
      );
      web.window.dispatchEvent(resumed);
      expect(resumed.defaultPrevented, false);
    },
  );
  test(
    'browser backup repair retains damaged originals and identity',
    () async {
      final release = await acquireSaveStorageLease(exclusive: true);
      final storage = PreferencesImportStorage();
      final key = ProgressRecoveryService.primaryKey('mock-recovery');
      final backup = jsonEncode(
        GameData.startingPlayerState().copyWith(coins: 4321).toJson(),
      );
      try {
        await storage.write(key, '{damaged mock progress');
        await storage.write('${key}_backup', backup);
        await storage.write('mock-identity-proof', 'not-replaced');
        final original = await storage.readAll();
        ProgressReadException? review;
        try {
          await SaveService(accountId: 'mock-recovery').load();
        } on ProgressReadException catch (e) {
          review = e;
        }
        expect(review!.backupSnapshot!.state.coins, 4321);
        expect(await storage.readAll(), original);
        await ProgressRecoveryService().stage(review);
        expect((await storage.readAll())[key], original[key]);
        expect(
          await SaveTransferService().finishPendingImport(),
          SaveImportBootResult.backupRestored,
        );
        final restored = await storage.readAll();
        expect(restored[key], backup);
        expect(restored['${key}_backup'], backup);
        expect(restored['mock-identity-proof'], 'not-replaced');
        final archive = restored.entries.singleWhere(
          (e) => e.key.startsWith(ProgressRecoveryService.archivePrefix),
        );
        expect(
          jsonDecode(archive.value as String)['primary'],
          '{damaged mock progress',
        );
        expect(
          (await SaveService(accountId: 'mock-recovery').load())!.coins,
          4321,
        );
      } finally {
        try {
          // Disposable Flutter test browser only; never the owner's browser.
          for (final key in (await storage.readAll()).keys) {
            await storage.remove(key);
          }
        } finally {
          await release();
        }
      }
    },
  );
  test(
    'damaged browser directory stays intact until explicitly restored at bootstrap',
    () async {
      final release = await acquireSaveStorageLease(exclusive: true);
      final storage = PreferencesImportStorage();
      final accounts = AccountService();
      try {
        await storage.write('playerAccounts', '{damaged mock directory');
        final original = await storage.readAll();
        await expectLater(
          accounts.initialize(),
          throwsA(isA<AccountStartupException>()),
        );
        expect(accounts.hasAccount, false);
        expect(await storage.readAll(), original);
        final transfer = SaveTransferService();
        final recoveryBackup = await transfer.exportSave();
        expect(recoveryBackup, contains('{damaged mock directory'));
        await transfer.stageImport(transfer.inspectSave(importFixture()));
        expect(
          (await storage.readAll())['playerAccounts'],
          '{damaged mock directory',
        );
        expect(
          await transfer.finishPendingImport(),
          SaveImportBootResult.imported,
        );
        await accounts.initialize();
        expect(accounts.account!.id, 'imported');
        expect(
          transfer
              .inspectSave(await transfer.exportSave())
              .progress['imported']!
              .coins,
          420,
        );
      } finally {
        accounts.dispose();
        try {
          // Only this disposable Flutter test browser's mock data is removed.
          for (final key in (await storage.readAll()).keys) {
            await storage.remove(key);
          }
        } finally {
          await release();
        }
      }
    },
  );
  test('browser chooser reads a selected file and cleans up once', () async {
    final picked = pickSaveFile();
    final input =
        web.document.querySelector('input[type=file]') as web.HTMLInputElement;
    final files = web.DataTransfer();
    files.items.add(web.File([importFixture().toJS].toJS, 'mock-save.json'));
    input.files = files.files;
    input.dispatchEvent(web.Event('change'));
    expect(
      SaveTransferService().inspectSave((await picked)!).players.single.id,
      'imported',
    );
    expect(web.document.querySelector('input[type=file]'), isNull);
  });

  test(
    'isolated browser preferences round trip through checked bootstrap import',
    () async {
      final release = await acquireSaveStorageLease(exclusive: true);
      try {
        final transfer = SaveTransferService();
        await transfer.stageImport(transfer.inspectSave(importFixture()));
        expect(
          await transfer.finishPendingImport(),
          SaveImportBootResult.imported,
        );
        expect(await transfer.hasPendingImport(), false);
        final restored = transfer.inspectSave(await transfer.exportSave());
        expect(restored.progress['imported']?.coins, 420);
      } finally {
        // This runner's ephemeral browser contains ONLY the mock fixture.
        try {
          final storage = PreferencesImportStorage();
          for (final key in (await storage.readAll()).keys) {
            await storage.remove(key);
          }
        } finally {
          await release();
        }
      }
    },
  );
  test(
    'browser cancellation settles the picker and removes its hidden input',
    () async {
      for (var attempt = 0; attempt < 2; attempt++) {
        final picked = pickSaveFile();
        final input = web.document.querySelector('input[type=file]')!;
        input.dispatchEvent(web.Event('cancel'));
        expect(await picked, isNull);
        expect(web.document.querySelector('input[type=file]'), isNull);
      }
    },
  );

  test(
    'browser shared runtimes block exclusive replacement without stealing',
    () async {
      expect(saveImportLockAvailable, true);
      final releaseFirst = await acquireSaveStorageLease();
      final releaseSecond = await acquireSaveStorageLease();
      await expectLater(
        acquireSaveStorageLease(exclusive: true),
        throwsA(isA<SaveTransferException>()),
      );
      await releaseFirst();
      await expectLater(
        acquireSaveStorageLease(exclusive: true),
        throwsA(isA<SaveTransferException>()),
      );
      await releaseSecond();
      final releaseExclusive = await acquireSaveStorageLease(exclusive: true);
      await releaseExclusive();
    },
  );

  test(
    'browser staging lease prevents concurrent pending-file replacement',
    () async {
      final release = await acquireSaveImportStagingLease();
      await expectLater(
        acquireSaveImportStagingLease(),
        throwsA(isA<SaveTransferException>()),
      );
      await release();
      final next = await acquireSaveImportStagingLease();
      await next();
    },
  );
}

class _RejectingProgressStorage extends PreferencesProgressStorage {
  _RejectingProgressStorage(super.primaryKey);
  bool reject = false;
  @override
  Future<bool> write(String key, Object value) =>
      reject ? Future.value(false) : super.write(key, value);
}

class _UncertainCheckpointStorage extends PreferencesKeyStorage {
  _UncertainCheckpointStorage(super.keys);
  bool uncertain = false;
  int writes = 0;
  @override
  Future<bool> write(String key, Object value) async {
    writes++;
    final accepted = await super.write(key, value);
    return uncertain ? false : accepted;
  }
}
