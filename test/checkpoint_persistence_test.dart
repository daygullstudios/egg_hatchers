import 'dart:async';
import 'dart:convert';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/cloud_progress_read.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/models/progress_sync_checkpoint.dart';
import 'package:egg_hatchers/models/progress_sync_state.dart';
import 'package:egg_hatchers/screens/settings_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/audio_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/progress_sync_checkpoint_store.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/widgets/account_scope.dart';
import 'package:egg_hatchers/widgets/audio_scope.dart';
import 'package:egg_hatchers/widgets/progress_conflict_dialog.dart';
import 'package:egg_hatchers/widgets/progress_sync_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _id = 'mock_checkpoint';
const _key = 'egg_hatchers.sync_checkpoint.v1.account.$_id';
const _a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _b = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
ProgressSyncCheckpoint _record(int revision, [String fingerprint = _a]) =>
    ProgressSyncCheckpoint(
      contentFingerprint: fingerprint,
      cloudRevision: revision,
      recordedAt: DateTime.utc(2026, 9, 7),
    );
PlayerState _state(int coins) => GameData.startingPlayerState().copyWith(
  coins: coins,
  lastSavedTime: DateTime.utc(2026, 9, 7),
);
CloudProgressSnapshot _remote(int coins, int revision) => CloudProgressSnapshot(
  state: _state(coins),
  contentFingerprint: SaveService.contentFingerprint(_state(coins)),
  cloudRevision: revision,
  savedAt: DateTime.utc(2026, 9, 7),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final mode in _Failure.values.where((m) => m != _Failure.none)) {
    for (final removing in [false, true]) {
      test(
        'checkpoint ${removing ? 'removal' : 'write'} checks $mode and retries exact data',
        () async {
          final storage = _Storage()..values['other-player'] = 'keep';
          final store = ProgressSyncCheckpointStore(
            accountId: _id,
            storage: storage,
          );
          await store.write(_record(1));
          final old = storage.values[_key];
          storage.mode = mode;
          await expectLater(
            removing ? store.clear() : store.write(_record(2)),
            throwsA(isA<CheckpointStorageException>()),
          );
          expect(storage.values['other-player'], 'keep');
          if (mode != _Failure.applyReject) expect(storage.values[_key], old);
          final attempts = storage.mutations;
          storage.mode = _Failure.none;
          await (removing ? store.clear() : store.write(_record(2)));
          expect((await store.read())?.cloudRevision, removing ? null : 2);
          expect(
            storage.mutations,
            attempts + (mode == _Failure.applyReject ? 0 : 1),
          );
        },
      );
    }
  }

  test('checkpoint read outage preserves the previous record', () async {
    final storage = _Storage();
    final store = ProgressSyncCheckpointStore(accountId: _id, storage: storage);
    await store.write(_record(1));
    storage.failReads = true;
    await expectLater(store.read(), throwsA(isA<CheckpointStorageException>()));
    expect(storage.mutations, 1);
    storage.failReads = false;
    expect((await store.read())!.cloudRevision, 1);
  });

  test(
    'unexpected and malformed ancestry stays untouched until fresh assessment',
    () async {
      final storage = _Storage();
      final store = ProgressSyncCheckpointStore(
        accountId: _id,
        storage: storage,
      );
      await store.write(_record(1));
      final other = jsonEncode(_record(9, _b).toJson());
      storage.values[_key] = other;
      await expectLater(
        store.write(_record(2)),
        throwsA(isA<CheckpointStorageException>()),
      );
      expect(storage.values[_key], other);
      for (final invalid in [
        true,
        'broken',
        jsonEncode({..._record(1).toJson(), 'cloudRevision': 1.8}),
      ]) {
        storage.values[_key] = invalid;
        expect(await store.read(), isNull);
        expect(storage.values[_key], invalid);
      }
    },
  );

  testWidgets(
    'same-key stores serialize and reject an obsolete loaded baseline',
    (tester) async {
      final storage = _Storage();
      final first = ProgressSyncCheckpointStore(
        accountId: _id,
        storage: storage,
      );
      final second = ProgressSyncCheckpointStore(
        accountId: _id,
        storage: storage,
      );
      await first.write(_record(1));
      await second.read();
      final gate = Completer<void>();
      storage.gate = gate;
      final saving = first.write(_record(2));
      await tester.pump();
      final stale = expectLater(
        second.write(_record(3)),
        throwsA(isA<CheckpointStorageException>()),
      );
      await tester.pump();
      expect(storage.inFlight, 1);
      gate.complete();
      await saving;
      await stale;
      expect((await first.read())!.cloudRevision, 2);
      expect(storage.maxInFlight, 1);
    },
  );

  for (final equal in [false, true]) {
    testWidgets(
      '${equal ? 'matching copies' : 'upload'} never report synced after a rejected record',
      (tester) async {
        final fixture = await _fixture(cloudCoins: equal ? 900 : null);
        addTearDown(fixture.sync.dispose);
        fixture.storage.mode = _Failure.reject;
        await fixture.select();
        expect(fixture.sync.state.checkpointNeedsAttention, true);
        expect(fixture.sync.state.operationPending, false);
        expect(
          fixture.sync.state.message,
          contains('may already have completed'),
        );
        final reads = fixture.cloud.reads, writes = fixture.cloud.writes;
        for (var i = 0; i < 20; i++) {
          fixture.sync.localProgressSaved(_id);
          await fixture.sync.synchronize();
          await tester.pump(const Duration(seconds: 1));
        }
        expect(fixture.cloud.reads, reads);
        expect(fixture.cloud.writes, writes);
        expect(fixture.sync.state.checkpointNeedsAttention, true);
        fixture.storage.mode = _Failure.none;
        await fixture.sync.retrySyncConfirmation();
        expect(fixture.sync.state.status, ProgressSyncStatus.synced);
        expect(fixture.cloud.writes, writes);
        expect(fixture.restores, 0);
        expect((await fixture.local.load())!.coins, 900);
      },
    );
  }

  for (final keepDevice in [false, true]) {
    test(
      'failed confirmation after ${keepDevice ? 'device' : 'cloud'} choice does not replay replacement',
      () async {
        final fixture = await _fixture(cloudCoins: 1200);
        addTearDown(fixture.sync.dispose);
        await fixture.select();
        final review = (await fixture.sync.prepareConflictReview())!;
        fixture.storage.mode = _Failure.applyReject;
        expect(
          await (keepDevice
              ? fixture.sync.keepThisDevice(review)
              : fixture.sync.useCloud(review)),
          false,
        );
        expect(fixture.sync.state.checkpointNeedsAttention, true);
        final writes = fixture.cloud.writes, restores = fixture.restores;
        expect(await fixture.sync.keepThisDevice(review), false);
        expect(await fixture.sync.useCloud(review), false);
        fixture.storage.mode = _Failure.none;
        await fixture.sync.retrySyncConfirmation();
        expect(fixture.cloud.writes, writes);
        expect(fixture.restores, restores);
        expect(fixture.sync.state.status, ProgressSyncStatus.synced);
        expect((await fixture.local.load())!.coins, keepDevice ? 900 : 1200);
      },
    );
  }

  test('retry after newly diverged saves requires a fresh choice', () async {
    final fixture = await _fixture();
    addTearDown(fixture.sync.dispose);
    fixture.storage.mode = _Failure.reject;
    await fixture.select();
    await fixture.local.save(_state(950));
    fixture.cloud.snapshot = _remote(1300, 2);
    fixture.storage.mode = _Failure.none;
    await fixture.sync.retrySyncConfirmation();
    expect(fixture.sync.state.hasConflict, true);
    expect(fixture.cloud.writes, 1);
    expect(fixture.restores, 0);
    expect((await fixture.local.load())!.coins, 950);
    expect(fixture.cloud.snapshot!.state.coins, 1300);
  });

  test(
    'changed checkpoint retry reassesses without overwriting the unexpected record',
    () async {
      final fixture = await _fixture();
      addTearDown(fixture.sync.dispose);
      fixture.storage.mode = _Failure.reject;
      await fixture.select();
      final newer = jsonEncode(_record(5, _b).toJson());
      fixture.storage.values[_key] = newer;
      fixture.storage.mode = _Failure.none;
      await fixture.sync.retrySyncConfirmation();
      expect(fixture.sync.state.checkpointNeedsAttention, true);
      expect(fixture.storage.values[_key], newer);
      await fixture.local.save(_state(950));
      fixture.cloud.snapshot = _remote(1200, 6);
      await fixture.sync.retrySyncConfirmation();
      expect(fixture.sync.state.hasConflict, true);
      expect(fixture.storage.values[_key], newer);
      expect(fixture.cloud.writes, 1);
      expect(fixture.restores, 0);
    },
  );

  test(
    'checkpoint read outage blocks cloud IO and retries without changing local progress',
    () async {
      final fixture = await _fixture(cloudCoins: 900);
      addTearDown(fixture.sync.dispose);
      fixture.storage.failReads = true;
      await fixture.select();
      expect(fixture.sync.state.checkpointNeedsAttention, true);
      expect(fixture.cloud.reads, 0);
      expect(fixture.cloud.writes, 0);
      fixture.storage.failReads = false;
      await fixture.sync.retrySyncConfirmation();
      expect(fixture.sync.state.status, ProgressSyncStatus.synced);
      expect(fixture.cloud.writes, 0);
    },
  );

  testWidgets(
    'slow confirmation stays single-flight and late success checks newer gameplay',
    (tester) async {
      final fixture = await _fixture();
      final gate = Completer<void>();
      fixture.storage.gate = gate;
      final selecting = fixture.select();
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      expect(fixture.sync.state.checkpointNeedsAttention, true);
      expect(fixture.sync.state.operationPending, true);
      await fixture.sync.retrySyncConfirmation();
      await fixture.local.save(_state(980));
      fixture.sync.localProgressSaved(_id);
      expect(fixture.storage.mutations, 1);
      gate.complete();
      await selecting;
      expect(fixture.sync.state.status, ProgressSyncStatus.pending);
      expect(fixture.cloud.writes, 1);
      expect(fixture.storage.maxInFlight, 1);
      expect((await fixture.local.load())!.coins, 980);
      fixture.sync.dispose();
    },
  );

  for (final end in ['switch', 'import', 'dispose', 'local failure']) {
    testWidgets('late checkpoint completion cannot publish after $end', (
      tester,
    ) async {
      final fixture = await _fixture();
      final gate = Completer<void>();
      fixture.storage.gate = gate;
      final selecting = fixture.select();
      await tester.pump();
      var notifications = 0;
      fixture.sync.addListener(() => notifications++);
      Future<void>? drain;
      switch (end) {
        case 'switch':
          await fixture.sync.selectAccount(
            accountId: null,
            protectedPlayerId: null,
          );
        case 'import':
          drain = fixture.sync.pauseForSaveImport();
        case 'dispose':
          fixture.sync.dispose();
        case 'local failure':
          fixture.sync.setLocalPersistencePaused(true);
      }
      final before = notifications;
      gate.complete();
      await selecting;
      await drain;
      await tester.pump(const Duration(seconds: 20));
      expect(notifications, before);
      expect(fixture.cloud.writes, 1);
      if (end == 'local failure') {
        fixture.sync.setLocalPersistencePaused(false);
        expect(fixture.sync.state.checkpointNeedsAttention, true);
        await fixture.sync.retrySyncConfirmation();
        expect(fixture.sync.state.status, ProgressSyncStatus.synced);
      }
      if (end != 'dispose') fixture.sync.dispose();
    });
  }

  for (final size in [
    const Size(320, 360),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('confirmation feedback and retry fit $size at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final accounts = AccountService();
      final game = GameService();
      final preferences = PreferencesService();
      final audio = AudioService();
      final sync = _FeedbackSync();
      await accounts.initialize();
      await game.initialize(accountId: accounts.account!.id);
      await preferences.initialize();
      await tester.pumpWidget(
        AccountScope(
          accounts: accounts,
          child: AudioScope(
            audio: audio,
            child: ProgressSyncScope(
              sync: sync,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
                home: SettingsScreen(preferences: preferences, game: game),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-panel-account')));
      await tester.pumpAndSettle();
      final retry = find.byKey(
        const ValueKey('settings-retry-sync-confirmation'),
      );
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      await tester.tap(retry);
      await tester.pump();
      expect(sync.retries, 1);
      expect(find.text('Confirmation in progress'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(retry).onPressed, isNull);
      expect(
        find.byKey(const ValueKey('settings-compare-saves')),
        findsNothing,
      );
      final context = tester.element(find.byType(SettingsScreen));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) =>
              ProgressConflictDialog(sync: sync, playerName: 'Test player'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Replace'), findsNothing);
      final close = find.byKey(
        const ValueKey('save-review-confirmation-settings'),
      );
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await game.suspendProgressWrites();
      game.dispose();
      audio.dispose();
      preferences.dispose();
      accounts.dispose();
      sync.dispose();
    });
  }
}

enum _Failure { none, reject, throwBefore, applyReject, lie }

class _Storage implements SaveImportStorage {
  final values = <String, Object>{};
  _Failure mode = _Failure.none;
  bool failReads = false;
  Completer<void>? gate;
  int mutations = 0, inFlight = 0, maxInFlight = 0;
  @override
  Future<Map<String, Object>> readAll() async {
    if (failReads) throw StateError('private backend detail');
    return Map.of(values);
  }

  Future<bool> _change(String key, Object? value) async {
    mutations++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      await gate?.future;
      if (mode == _Failure.throwBefore) {
        throw StateError('private backend detail');
      }
      if (mode == _Failure.reject) return false;
      if (mode != _Failure.lie) {
        if (value == null) {
          values.remove(key);
        } else {
          values[key] = value;
        }
      }
      return mode != _Failure.applyReject;
    } finally {
      inFlight--;
    }
  }

  @override
  Future<bool> write(String key, Object value) => _change(key, value);
  @override
  Future<bool> remove(String key) => _change(key, null);
}

class _Cloud implements CloudProgressRepository {
  CloudProgressSnapshot? snapshot;
  int reads = 0, writes = 0;
  @override
  Future<CloudProgressRead> read(String id) async {
    reads++;
    return snapshot == null
        ? const CloudProgressRead.missing()
        : CloudProgressRead.present(snapshot!);
  }

  @override
  Future<CloudProgressSnapshot> write({
    required String protectedPlayerId,
    required ProgressSaveSnapshot local,
    required int? expectedCloudRevision,
  }) async {
    if (snapshot?.cloudRevision != expectedCloudRevision) {
      throw const CloudProgressWriteConflict();
    }
    writes++;
    return snapshot = CloudProgressSnapshot(
      state: local.state,
      contentFingerprint: local.contentFingerprint,
      cloudRevision: (expectedCloudRevision ?? 0) + 1,
      savedAt: DateTime.utc(2026, 9, 7),
    );
  }
}

class _Fixture {
  final local = SaveService(accountId: _id);
  final cloud = _Cloud();
  final storage = _Storage();
  late final sync = ProgressSyncService(
    debounce: const Duration(days: 1),
    checkpointFactory: (id) =>
        ProgressSyncCheckpointStore(accountId: id, storage: storage),
  );
  int restores = 0;
  Future<void> select() => sync.selectAccount(
    accountId: _id,
    protectedPlayerId: 'mock_uid',
    cloud: cloud,
    applyCloud: (state) async {
      restores++;
      await local.save(state);
      return true;
    },
  );
}

Future<_Fixture> _fixture({int? cloudCoins}) async {
  final fixture = _Fixture();
  await fixture.local.save(_state(900));
  if (cloudCoins != null) fixture.cloud.snapshot = _remote(cloudCoins, 4);
  return fixture;
}

class _FeedbackSync extends ProgressSyncService {
  int retries = 0;
  @override
  ProgressSyncState get state => ProgressSyncState(
    status: ProgressSyncStatus.error,
    checkpointNeedsAttention: true,
    operationPending: retries > 0,
    message:
        'Could not verify the sync record on this device. Local gameplay keeps saving. Retry confirmation; do not clear browser data.',
  );
  @override
  Future<void> retrySyncConfirmation() async {
    retries++;
    notifyListeners();
  }
}
