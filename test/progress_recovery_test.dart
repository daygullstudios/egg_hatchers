import 'dart:convert';
import 'dart:async';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/progress_recovery_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'helpers/save_import_fixture.dart';

const _id = 'damaged';
final _key = ProgressRecoveryService.primaryKey(_id);
String _good([int coins = 321]) => jsonEncode(
  GameData.startingPlayerState()
      .copyWith(coins: coins, lastSavedTime: DateTime.utc(2026))
      .toJson(),
);
Map<String, Object> _pair() => {
  _key: '{damaged primary',
  '${_key}_backup': _good(),
  ProgressRecoveryService.primaryKey('other'): _good(999),
  'deviceGuestFirebaseUid': 'unchanged-mock-uid',
  'nestarium.device_guest_generation.v1': 7,
  'playerAccounts': 'unchanged-directory',
  'musicEnabled': false,
};
Future<ProgressReadException> _review(ImportMemoryStorage storage) async {
  try {
    await SaveService(accountId: _id, storage: storage).load();
  } on ProgressReadException catch (e) {
    return e;
  }
  throw StateError('Expected a recovery review');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'fresh progress check does not roll back the shared settings cache',
    () async {
      SharedPreferences.setMockInitialValues({
        _key: _good(),
        'overlayUnlocked': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final backend = _ReadGateStore({
        'flutter.$_key': _good(),
        'flutter.overlayUnlocked': false,
      });
      SharedPreferencesStorePlatform.instance = backend;
      final reading = SaveService(accountId: _id).load();
      await backend.readStarted.future;
      await prefs.setBool('overlayUnlocked', true);
      backend.readGate.complete();
      await reading;
      expect(prefs.getBool('overlayUnlocked'), true);
      expect(backend.requestedKeys, {
        'flutter.$_key',
        'flutter.${_key}_backup',
      });
    },
  );
  test(
    'autosave preserves fresh primary as backup instead of using stale cache',
    () async {
      SharedPreferences.setMockInitialValues({_key: _good(100)});
      final prefs = await SharedPreferences.getInstance();
      final backend = SharedPreferencesStorePlatform.instance;
      await backend.setValue('String', 'flutter.$_key', _good(200));
      expect(prefs.getString(_key), _good(100));
      await SaveService(
        accountId: _id,
      ).save(GameData.startingPlayerState().copyWith(coins: 300));
      expect(prefs.getString('${_key}_backup'), _good(200));
    },
  );
  for (var mutation = 1; mutation <= 4; mutation++) {
    test(
      'write uncertainty after mutation $mutation preserves restart recovery',
      () async {
        final storage = _UncertainStorage(_pair())..uncertainAt = mutation;
        final recovery = ProgressRecoveryService(storage: storage);
        final review = await _review(storage);
        if (mutation == 1) {
          await expectLater(recovery.stage(review), throwsStateError);
        } else {
          await recovery.stage(review);
          await expectLater(recovery.finish(), throwsStateError);
        }
        storage.uncertainAt = null;
        await recovery.finish();
        expect(await recovery.hasPending(), false);
        expect(storage.values[_key], review.backup);
        final archives = storage.values.entries.where(
          (e) => e.key.startsWith(ProgressRecoveryService.archivePrefix),
        );
        expect(archives, hasLength(1));
        expect(
          jsonDecode(archives.single.value as String)['primary'],
          review.primary,
        );
      },
    );
  }
  test(
    'storage read failure is distinct from missing progress and has no raw diagnostic',
    () async {
      final storage = _ReadFailureStorage();
      final review = await _review(storage);
      expect(review.failure, ProgressReadFailure.storageUnavailable);
      expect(review.primary, isNull);
      expect(review.toString(), isNot(contains('private-value')));
      expect(storage.operations, isEmpty);
    },
  );
  test('only two absent copies mean no saved progress', () async {
    final empty = ImportMemoryStorage();
    expect(await SaveService(storage: empty).load(), isNull);
    for (final original in [
      <String, Object>{_key: '{bad'},
      <String, Object>{_key: '{bad', '${_key}_backup': 42},
      <String, Object>{'${_key}_backup': _good()},
      <String, Object>{
        _key: <String>['wrong type'],
        '${_key}_backup': _good(),
      },
    ]) {
      final storage = ImportMemoryStorage(original);
      final review = await _review(storage);
      expect(
        review.failure,
        original['${_key}_backup'] is String
            ? ProgressReadFailure.backupAvailable
            : ProgressReadFailure.unreadable,
      );
      expect(storage.values, original);
      expect(storage.operations, isEmpty);
    }
  });
  test(
    'unsupported envelopes and malformed containers cannot become legacy saves',
    () {
      final raw = GameData.startingPlayerState().toJson();
      for (final invalid in [
        {...raw, 'format': 'future-progress'},
        {...raw, 'coins': -1},
        {...raw, 'eggMastery': <Object>[]},
        {...raw, 'dailyQuests': 12},
        {
          ...raw,
          'ownedAnimals': <Object>[
            {'animalId': '', 'quantity': 0},
          ],
        },
        {
          'format': SaveService.progressFormat,
          'schemaVersion': 999,
          'revision': 1,
          'playerState': raw,
        },
      ]) {
        expect(SaveService.decodeSnapshot(jsonEncode(invalid)), isNull);
      }
      expect(SaveService.decodeSnapshot(jsonEncode(raw)), isNotNull);
    },
  );
  test(
    'stage changes no progress; restore archives both originals and only repairs selected key',
    () async {
      final original = _pair(), storage = ImportMemoryStorage(_pair());
      final recovery = ProgressRecoveryService(storage: storage);
      await recovery.stage(await _review(storage));
      expect(
        {...storage.values}..remove(ProgressRecoveryService.pendingKey),
        original,
      );
      final transfer = SaveTransferService(storage: storage);
      expect(await transfer.hasPendingImport(), true);
      expect(
        await transfer.finishPendingImport(),
        SaveImportBootResult.backupRestored,
      );
      expect(await recovery.hasPending(), false);
      final archive = storage.values.entries.singleWhere(
        (e) => e.key.startsWith(ProgressRecoveryService.archivePrefix),
      );
      final raw = jsonDecode(archive.value as String);
      expect(raw['primary'], original[_key]);
      expect(raw['backup'], original['${_key}_backup']);
      expect({...storage.values}..remove(archive.key), {
        ...original,
        _key: original['${_key}_backup']!,
      });
      await recovery.finish();
      expect(
        (await SaveService(accountId: _id, storage: storage).load())!.coins,
        321,
      );
      expect(await transfer.exportSave(), contains('{damaged primary'));
    },
  );
  for (var mutation = 1; mutation <= 3; mutation++) {
    for (final cancel in [false, true]) {
      test(
        'interrupted restore mutation $mutation resumes/cancels=$cancel without losing originals',
        () async {
          final original = _pair(), storage = ImportMemoryStorage(_pair());
          final recovery = ProgressRecoveryService(storage: storage);
          await recovery.stage(await _review(storage));
          storage.failAt = storage.mutations + mutation;
          await expectLater(recovery.finish(), throwsStateError);
          expect(await recovery.hasPending(), true);
          storage.failAt = null;
          await recovery.finish(cancel: cancel);
          expect(await recovery.hasPending(), false);
          expect(
            storage.values[_key],
            cancel ? original[_key] : original['${_key}_backup'],
          );
          for (final entry in original.entries.where((e) => e.key != _key)) {
            expect(storage.values[entry.key], entry.value);
          }
          if (!cancel) {
            expect(
              storage.values.values.whereType<String>().any(
                (s) => s.contains('damaged primary'),
              ),
              true,
            );
          }
        },
      );
    }
  }
  test(
    'cancel restores wrong-typed or absent primary after partial application',
    () async {
      for (final primary in [
        null,
        <String>['original', 'damaged'],
        42,
        false,
      ]) {
        final storage = ImportMemoryStorage({
          _key: ?primary,
          '${_key}_backup': _good(),
        });
        final original = {...storage.values};
        final recovery = ProgressRecoveryService(storage: storage);
        await recovery.stage(await _review(storage));
        storage.failAt = storage.mutations + 3;
        await expectLater(recovery.finish(), throwsStateError);
        storage.failAt = null;
        await recovery.finish(cancel: true);
        expect(
          {...storage.values}..removeWhere(
            (k, v) => k.startsWith(ProgressRecoveryService.archivePrefix),
          ),
          original,
        );
      }
    },
  );
  test(
    'stale preview and changed copies at restart both fail closed',
    () async {
      for (final key in [_key, '${_key}_backup']) {
        final storage = ImportMemoryStorage(_pair());
        final recovery = ProgressRecoveryService(storage: storage);
        final review = await _review(storage);
        storage.values[key] = _good(777);
        await expectLater(recovery.stage(review), throwsStateError);
        expect(storage.operations, isEmpty);
        storage.values[key] = key == _key ? '{damaged primary' : review.backup!;
        await recovery.stage(review);
        storage.values[key] = _good(888);
        final changed = {...storage.values};
        await expectLater(recovery.finish(), throwsStateError);
        expect(storage.values, changed);
      }
    },
  );
  test('full import and backup restore cannot run concurrently', () async {
    final storage = ImportMemoryStorage(_pair());
    final recovery = ProgressRecoveryService(storage: storage);
    final transfer = SaveTransferService(storage: storage);
    await recovery.stage(await _review(storage));
    await expectLater(
      transfer.stageImport(transfer.inspectSave(importFixture())),
      throwsA(isA<SaveTransferException>()),
    );
    storage.values[SaveTransferService.pendingKey] = importFixture();
    final original = {...storage.values};
    await expectLater(
      transfer.finishPendingImport(),
      throwsA(isA<SaveTransferException>()),
    );
    await expectLater(
      transfer.cancelPendingImport(),
      throwsA(isA<SaveTransferException>()),
    );
    expect(storage.values, original);
  });
  test(
    'legacy tutorial migration does not consume marker or modify any saves when one is damaged',
    () async {
      final values = {
        ..._pair(),
        'rottenShellFinalBattleTutorialCompleted': true,
      };
      SharedPreferences.setMockInitialValues(values);
      await SaveService.migrateLegacyRottenShellTutorial(['other', _id]);
      final prefs = await SharedPreferences.getInstance();
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, values);
    },
  );
  test(
    'failed switch blocks writes and retries same target without overwriting either player',
    () async {
      SharedPreferences.setMockInitialValues(_pair());
      final game = GameService();
      addTearDown(game.dispose);
      await game.initialize(accountId: 'other');
      await expectLater(
        game.switchAccount(_id),
        throwsA(isA<ProgressReadException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      await game.save();
      await game.pauseForSaveImport();
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
    },
  );
  test(
    'failed load can retry the same player after explicit fixture repair',
    () async {
      SharedPreferences.setMockInitialValues(_pair());
      final game = GameService();
      addTearDown(game.dispose);
      await expectLater(
        game.initialize(accountId: _id),
        throwsA(isA<ProgressReadException>()),
      );
      expect(game.isInitialized, false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _good(876));
      await game.initialize(accountId: _id);
      expect(game.isInitialized, true);
      expect(game.state.coins, 876);
      expect(game.progressReadFailure, isNull);
      await game.save();
      expect((await SaveService(accountId: _id).load())!.coins, 876);
    },
  );
  test('runtime corruption blocks autosave and cloud replacement', () async {
    SharedPreferences.setMockInitialValues({_key: _good()});
    final game = GameService();
    addTearDown(game.dispose);
    await game.initialize(accountId: _id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, '{runtime-damage');
    await game.save();
    expect(game.progressReadFailure, isNotNull);
    expect(
      await game.replaceProgressFromCloud(_id, GameData.startingPlayerState()),
      false,
    );
    await game.save();
    expect(prefs.getString(_key), '{runtime-damage');
  });
}

class _UncertainStorage extends ImportMemoryStorage {
  _UncertainStorage(super.initial);
  int? uncertainAt;
  @override
  Future<bool> write(String key, Object value) async {
    final accepted = await super.write(key, value);
    return mutations == uncertainAt ? false : accepted;
  }

  @override
  Future<bool> remove(String key) async {
    final accepted = await super.remove(key);
    return mutations == uncertainAt ? false : accepted;
  }
}

class _ReadFailureStorage extends ImportMemoryStorage {
  @override
  Future<Map<String, Object>> readAll() async =>
      throw StateError('private-value');
}

class _ReadGateStore extends InMemorySharedPreferencesStore {
  _ReadGateStore(super.data) : super.withData();
  final readStarted = Completer<void>(), readGate = Completer<void>();
  Set<String>? requestedKeys;
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    requestedKeys = parameters.filter.allowList;
    final values = await super.getAllWithParameters(parameters);
    readStarted.complete();
    await readGate.future;
    return values;
  }
}
