import 'dart:async';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/cloud_progress_read.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/models/progress_sync_state.dart';
import 'package:egg_hatchers/services/progress_sync_checkpoint_store.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'import pause drains a late cloud read without upload or restore',
    (tester) async {
      final local = SaveService(accountId: 'guest_local');
      await local.save(GameData.startingPlayerState());
      final gate = Completer<void>();
      final cloud = _CloudRepository()..readGate = gate;
      final sync = ProgressSyncService();
      addTearDown(sync.dispose);
      var restores = 0, paused = false;
      final selection = sync.selectAccount(
        accountId: 'guest_local',
        protectedPlayerId: 'mock-identity',
        cloud: cloud,
        applyCloud: (_) async {
          restores++;
          return true;
        },
      );
      await tester.pump();
      final pausing = sync.pauseForSaveImport().then((_) => paused = true);
      await tester.pump();
      expect(paused, false);
      gate.complete();
      await selection;
      await pausing;
      sync.localProgressSaved('guest_local');
      await tester.pump(const Duration(seconds: 30));
      await sync.synchronize();
      expect(cloud.reads, 1);
      expect(cloud.writes, 0);
      expect(restores, 0);
    },
  );

  test('comparison reads fresh saves without writing or restoring', () async {
    final fixture = await _reviewFixture();
    addTearDown(fixture.sync.dispose);
    await fixture.local.save(
      GameData.startingPlayerState().copyWith(coins: 980),
    );
    final review = (await fixture.sync.prepareConflictReview())!;
    expect(review.local.state.coins, 980);
    expect(review.cloud.state.coins, 1200);
    expect(fixture.cloud.writes, 0);
    expect(fixture.sync.state.hasConflict, isTrue);
    expect(
      await ProgressSyncCheckpointStore(accountId: 'review_player').read(),
      isNull,
    );
    // Device selection intentionally keeps income accrued after the snapshot.
    await fixture.local.save(
      GameData.startingPlayerState().copyWith(coins: 990),
    );
    expect(await fixture.sync.keepThisDevice(review), isTrue);
    expect(fixture.cloud.snapshot?.state.coins, 990);
  });

  for (final keepDevice in [true, false]) {
    test(
      'changed cloud blocks reviewed ${keepDevice ? 'device' : 'cloud'} replacement',
      () async {
        final fixture = await _reviewFixture();
        addTearDown(fixture.sync.dispose);
        final review = (await fixture.sync.prepareConflictReview())!;
        fixture.cloud.snapshot = _snapshot(
          GameData.startingPlayerState().copyWith(coins: 1500),
          5,
        );
        final result = keepDevice
            ? await fixture.sync.keepThisDevice(review)
            : await fixture.sync.useCloud(review);
        expect(result, isFalse);
        expect(fixture.sync.state.message, contains('cloud save changed'));
        expect(fixture.cloud.writes, 0);
        expect((await fixture.local.load())?.coins, 900);
        expect(fixture.cloud.snapshot?.state.coins, 1500);
        final refreshed = (await fixture.sync.prepareConflictReview())!;
        expect(refreshed.cloud.state.coins, 1500);
        expect(
          keepDevice
              ? await fixture.sync.keepThisDevice(refreshed)
              : await fixture.sync.useCloud(refreshed),
          isTrue,
        );
      },
    );
  }

  test(
    'expired review cannot resolve another account or supersede a new review',
    () async {
      final fixture = await _reviewFixture();
      addTearDown(fixture.sync.dispose);
      final old = (await fixture.sync.prepareConflictReview())!;
      final latest = (await fixture.sync.prepareConflictReview())!;
      expect(await fixture.sync.keepThisDevice(old), isFalse);
      expect(await fixture.sync.useCloud(old), isFalse);
      await fixture.sync.selectAccount(
        accountId: null,
        protectedPlayerId: null,
      );
      expect(await fixture.sync.keepThisDevice(latest), isFalse);
      expect(await fixture.sync.useCloud(latest), isFalse);
      expect(fixture.cloud.writes, 0);
      expect((await fixture.local.load())?.coins, 900);
    },
  );

  test(
    'unavailable comparison exposes no review or automatic resolution',
    () async {
      final fixture = await _reviewFixture();
      addTearDown(fixture.sync.dispose);
      final old = (await fixture.sync.prepareConflictReview())!;
      fixture.cloud.unknown = true;
      expect(await fixture.sync.prepareConflictReview(), isNull);
      expect(await fixture.sync.keepThisDevice(old), isFalse);
      expect(fixture.sync.state.hasConflict, isTrue);
      expect(fixture.cloud.writes, 0);
      fixture.cloud.unknown = false;
      fixture.cloud.snapshot = null;
      expect(await fixture.sync.prepareConflictReview(), isNull);
      expect(fixture.cloud.writes, 0);
    },
  );

  testWidgets('autosaves and queued retries cannot dismiss a save choice', (
    tester,
  ) async {
    final local = SaveService(accountId: 'guest_local');
    await local.save(GameData.startingPlayerState().copyWith(coins: 900));
    final gate = Completer<void>();
    final cloud = _CloudRepository(
      snapshot: _snapshot(
        GameData.startingPlayerState().copyWith(coins: 1200),
        4,
      ),
    )..readGate = gate;
    final service = ProgressSyncService();
    var restores = 0;
    final selection = service.selectAccount(
      accountId: 'guest_local',
      protectedPlayerId: 'firebase-guest',
      cloud: cloud,
      applyCloud: (_) async {
        restores++;
        return true;
      },
    );
    await tester.pump();
    expect(cloud.reads, 1);
    // An idle save during the first comparison queues another pass today.
    service.localProgressSaved('guest_local');
    gate.complete();
    await selection;
    expect(service.state.status, ProgressSyncStatus.conflict);
    final transitions = <ProgressSyncStatus>[];
    service.addListener(() => transitions.add(service.state.status));

    for (var tick = 1; tick <= 20; tick++) {
      await local.save(
        GameData.startingPlayerState().copyWith(coins: 900 + tick),
      );
      service.localProgressSaved('guest_local');
      await tester.pump(const Duration(seconds: 1));
      await service.synchronize();
      expect(service.state.status, ProgressSyncStatus.conflict);
    }
    expect(transitions, isEmpty);
    expect(cloud.reads, 1);
    expect(cloud.writes, 0);
    expect(restores, 0);
    expect((await local.load())?.coins, 920);
    expect(cloud.snapshot?.state.coins, 1200);
    service.dispose();
  });

  for (final keepDevice in [true, false]) {
    testWidgets(
      'player switch during ${keepDevice ? 'device' : 'cloud'} choice is isolated',
      (tester) async {
        final local = SaveService(accountId: 'guest_local');
        await local.save(GameData.startingPlayerState().copyWith(coins: 900));
        final cloud = _CloudRepository(
          snapshot: _snapshot(
            GameData.startingPlayerState().copyWith(coins: 1200),
            4,
          ),
        );
        final service = ProgressSyncService();
        var restores = 0;
        await service.selectAccount(
          accountId: 'guest_local',
          protectedPlayerId: 'firebase-guest',
          cloud: cloud,
          applyCloud: (_) async {
            restores++;
            return true;
          },
        );
        final review = (await service.prepareConflictReview())!;
        final gate = Completer<void>();
        cloud.readGate = gate;
        final resolving = keepDevice
            ? service.keepThisDevice(review)
            : service.useCloud(review);
        await tester.pump();
        expect(cloud.reads, 3);
        service.localProgressSaved('guest_local');
        expect(service.state.status, ProgressSyncStatus.syncing);
        final otherCloud = _CloudRepository();
        await service.selectAccount(
          accountId: 'other_player',
          protectedPlayerId: 'other-identity',
          cloud: otherCloud,
          applyCloud: (_) async {
            restores++;
            return true;
          },
        );
        gate.complete();
        await resolving;
        await tester.pump(const Duration(seconds: 3));
        expect(service.state.status, ProgressSyncStatus.synced);
        expect(otherCloud.reads, 1);
        expect(cloud.writes, 0);
        expect(otherCloud.writes, 0);
        expect(restores, 0);
        expect(
          await ProgressSyncCheckpointStore(accountId: 'other_player').read(),
          isNull,
        );
        service.dispose();
      },
    );

    testWidgets(
      'explicit ${keepDevice ? 'device' : 'cloud'} choice resumes sync',
      (tester) async {
        final local = SaveService(accountId: 'guest_local');
        await local.save(GameData.startingPlayerState().copyWith(coins: 900));
        final cloud = _CloudRepository(
          snapshot: _snapshot(
            GameData.startingPlayerState().copyWith(coins: 1200),
            4,
          ),
        );
        final service = ProgressSyncService();
        await service.selectAccount(
          accountId: 'guest_local',
          protectedPlayerId: 'firebase-guest',
          cloud: cloud,
          applyCloud: (state) async {
            await local.save(state);
            service.localProgressSaved('guest_local');
            return true;
          },
        );
        await local.save(GameData.startingPlayerState().copyWith(coins: 950));
        service.localProgressSaved('guest_local');
        cloud.snapshot = _snapshot(
          GameData.startingPlayerState().copyWith(coins: 1300),
          5,
        );
        final review = (await service.prepareConflictReview())!;
        if (keepDevice) {
          await service.keepThisDevice(review);
        } else {
          await service.useCloud(review);
        }
        expect(service.state.status, ProgressSyncStatus.synced);
        expect((await local.load())?.coins, keepDevice ? 950 : 1300);
        expect(cloud.snapshot?.state.coins, keepDevice ? 950 : 1300);

        await local.save(GameData.startingPlayerState().copyWith(coins: 1400));
        service.localProgressSaved('guest_local');
        await tester.pump(const Duration(seconds: 3));
        expect(service.state.status, ProgressSyncStatus.synced);
        expect(cloud.snapshot?.state.coins, 1400);
        service.dispose();
      },
    );

    testWidgets(
      'failed ${keepDevice ? 'device' : 'cloud'} choice stays actionable',
      (tester) async {
        final local = SaveService(accountId: 'guest_local');
        await local.save(GameData.startingPlayerState().copyWith(coins: 900));
        final cloud = _CloudRepository(
          snapshot: _snapshot(
            GameData.startingPlayerState().copyWith(coins: 1200),
            4,
          ),
        );
        final service = ProgressSyncService();
        await service.selectAccount(
          accountId: 'guest_local',
          protectedPlayerId: 'firebase-guest',
          cloud: cloud,
          applyCloud: (_) async => true,
        );
        final review = (await service.prepareConflictReview())!;
        cloud.unknown = true;
        if (keepDevice) {
          await service.keepThisDevice(review);
        } else {
          await service.useCloud(review);
        }
        expect(service.state.status, ProgressSyncStatus.conflict);
        final reads = cloud.reads;
        service.localProgressSaved('guest_local');
        await tester.pump(const Duration(seconds: 30));
        expect(service.state.status, ProgressSyncStatus.conflict);
        expect(cloud.reads, reads);
        expect(cloud.writes, 0);
        expect((await local.load())?.coins, 900);
        expect(cloud.snapshot?.state.coins, 1200);
        service.dispose();
      },
    );
  }

  test(
    'selecting another player clears only the previous save choice',
    () async {
      final local = SaveService(accountId: 'guest_local');
      await local.save(GameData.startingPlayerState().copyWith(coins: 900));
      final cloud = _CloudRepository(
        snapshot: _snapshot(
          GameData.startingPlayerState().copyWith(coins: 1200),
          4,
        ),
      );
      final service = ProgressSyncService();
      addTearDown(service.dispose);
      await service.selectAccount(
        accountId: 'guest_local',
        protectedPlayerId: 'firebase-guest',
        cloud: cloud,
        applyCloud: (_) async => true,
      );
      expect(service.state.hasConflict, isTrue);
      final otherCloud = _CloudRepository();
      await service.selectAccount(
        accountId: 'other_player',
        protectedPlayerId: 'other-identity',
        cloud: otherCloud,
        applyCloud: (_) async => true,
      );
      expect(service.state.status, ProgressSyncStatus.synced);
      service.localProgressSaved('guest_local');
      expect(service.state.status, ProgressSyncStatus.synced);
      expect(cloud.writes, 0);
      expect(otherCloud.reads, 1);
    },
  );

  testWidgets(
    'a cloud revision race keeps the choice without automatic retries',
    (tester) async {
      final local = SaveService(accountId: 'guest_local');
      await local.save(GameData.startingPlayerState().copyWith(coins: 900));
      final cloud = _CloudRepository(
        snapshot: _snapshot(
          GameData.startingPlayerState().copyWith(coins: 1200),
          4,
        ),
      )..rejectWrite = true;
      final service = ProgressSyncService();
      await service.selectAccount(
        accountId: 'guest_local',
        protectedPlayerId: 'firebase-guest',
        cloud: cloud,
        applyCloud: (_) async => true,
      );
      await service.keepThisDevice((await service.prepareConflictReview())!);
      expect(service.state.hasConflict, isTrue);
      expect(service.state.message, contains('changed again'));
      final reads = cloud.reads;
      service.localProgressSaved('guest_local');
      await tester.pump(const Duration(seconds: 30));
      expect(cloud.reads, reads);
      expect(cloud.writes, 0);
      expect((await local.load())?.coins, 900);
      expect(cloud.snapshot?.state.coins, 1200);
      service.dispose();
    },
  );

  test(
    'a declined cloud apply returns to the choice instead of staying busy',
    () async {
      final local = SaveService(accountId: 'guest_local');
      await local.save(GameData.startingPlayerState().copyWith(coins: 900));
      final cloud = _CloudRepository(
        snapshot: _snapshot(
          GameData.startingPlayerState().copyWith(coins: 1200),
          4,
        ),
      );
      final service = ProgressSyncService();
      addTearDown(service.dispose);
      await service.selectAccount(
        accountId: 'guest_local',
        protectedPlayerId: 'firebase-guest',
        cloud: cloud,
        applyCloud: (_) async => false,
      );
      await service.useCloud((await service.prepareConflictReview())!);
      expect(service.state.hasConflict, isTrue);
      expect(service.state.message, contains('choose again'));
      expect((await local.load())?.coins, 900);
      expect(cloud.writes, 0);
    },
  );

  test(
    'confirmed empty cloud uploads local progress and records ancestry',
    () async {
      final local = SaveService(accountId: 'guest_local');
      await local.save(GameData.startingPlayerState().copyWith(coins: 900));
      final cloud = _CloudRepository();
      final service = ProgressSyncService(debounce: const Duration(days: 1));
      addTearDown(service.dispose);

      await service.selectAccount(
        accountId: 'guest_local',
        protectedPlayerId: 'firebase-guest',
        cloud: cloud,
        applyCloud: (_) async => true,
      );

      expect(service.state.status, ProgressSyncStatus.synced);
      expect(cloud.writes, 1);
      expect(cloud.snapshot?.state.coins, 900);
      final checkpoint = await ProgressSyncCheckpointStore(
        accountId: 'guest_local',
      ).read();
      expect(checkpoint?.cloudRevision, 1);
      expect(
        checkpoint?.contentFingerprint,
        cloud.snapshot?.contentFingerprint,
      );
    },
  );

  test('unknown cloud never authorizes an upload', () async {
    final local = SaveService(accountId: 'guest_local');
    await local.save(GameData.startingPlayerState().copyWith(coins: 900));
    final cloud = _CloudRepository(unknown: true);
    final service = ProgressSyncService(debounce: const Duration(days: 1));
    addTearDown(service.dispose);

    await service.selectAccount(
      accountId: 'guest_local',
      protectedPlayerId: 'firebase-guest',
      cloud: cloud,
      applyCloud: (_) async => true,
    );

    expect(service.state.status, ProgressSyncStatus.pending);
    expect(cloud.writes, 0);
  });

  test(
    'continuous local saves still reach the cloud on a bounded cadence',
    () async {
      final local = SaveService(accountId: 'guest_local');
      final cloud = _CloudRepository();
      final service = ProgressSyncService(
        debounce: const Duration(milliseconds: 20),
      );
      addTearDown(service.dispose);
      await service.selectAccount(
        accountId: 'guest_local',
        protectedPlayerId: 'firebase-guest',
        cloud: cloud,
        applyCloud: (_) async => true,
      );

      for (var coins = 1; coins <= 4; coins += 1) {
        await local.save(GameData.startingPlayerState().copyWith(coins: coins));
        service.localProgressSaved('guest_local');
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(cloud.writes, greaterThanOrEqualTo(1));
      expect(cloud.snapshot?.state.coins, 4);
    },
  );

  test('cloud-only progress restores locally without a conflict', () async {
    final remoteState = GameData.startingPlayerState().copyWith(coins: 1200);
    final cloud = _CloudRepository(snapshot: _snapshot(remoteState, 4));
    final local = SaveService(accountId: 'guest_local');
    final service = ProgressSyncService(debounce: const Duration(days: 1));
    addTearDown(service.dispose);

    await service.selectAccount(
      accountId: 'guest_local',
      protectedPlayerId: 'firebase-guest',
      cloud: cloud,
      applyCloud: (state) async {
        await local.save(state);
        return true;
      },
    );

    expect(service.state.status, ProgressSyncStatus.synced);
    expect((await local.load())?.coins, 1200);
    expect(cloud.writes, 0);
    expect(
      (await ProgressSyncCheckpointStore(
        accountId: 'guest_local',
      ).read())?.cloudRevision,
      4,
    );
  });

  test('divergent first sync waits for an explicit device choice', () async {
    final local = SaveService(accountId: 'guest_local');
    await local.save(GameData.startingPlayerState().copyWith(coins: 900));
    final remoteState = GameData.startingPlayerState().copyWith(coins: 1200);
    final cloud = _CloudRepository(snapshot: _snapshot(remoteState, 4));
    final service = ProgressSyncService(debounce: const Duration(days: 1));
    addTearDown(service.dispose);

    await service.selectAccount(
      accountId: 'guest_local',
      protectedPlayerId: 'firebase-guest',
      cloud: cloud,
      applyCloud: (_) async => true,
    );

    expect(service.state.status, ProgressSyncStatus.conflict);
    expect(cloud.writes, 0);

    await service.keepThisDevice((await service.prepareConflictReview())!);

    expect(service.state.status, ProgressSyncStatus.synced);
    expect(cloud.writes, 1);
    expect(cloud.snapshot?.cloudRevision, 5);
    expect(cloud.snapshot?.state.coins, 900);
  });
}

CloudProgressSnapshot _snapshot(PlayerState state, int revision) =>
    CloudProgressSnapshot(
      state: state,
      contentFingerprint: SaveService.contentFingerprint(state),
      cloudRevision: revision,
      savedAt: DateTime.utc(2026),
    );

Future<({SaveService local, _CloudRepository cloud, ProgressSyncService sync})>
_reviewFixture() async {
  final local = SaveService(accountId: 'review_player');
  await local.save(GameData.startingPlayerState().copyWith(coins: 900));
  final cloud = _CloudRepository(
    snapshot: _snapshot(
      GameData.startingPlayerState().copyWith(coins: 1200),
      4,
    ),
  );
  final sync = ProgressSyncService(debounce: const Duration(days: 1));
  await sync.selectAccount(
    accountId: 'review_player',
    protectedPlayerId: 'review-identity',
    cloud: cloud,
    applyCloud: (state) async {
      await local.save(state);
      return true;
    },
  );
  return (local: local, cloud: cloud, sync: sync);
}

final class _CloudRepository implements CloudProgressRepository {
  _CloudRepository({this.snapshot, this.unknown = false});

  CloudProgressSnapshot? snapshot;
  bool unknown;
  Completer<void>? readGate;
  var reads = 0;
  var rejectWrite = false;
  var writes = 0;

  @override
  Future<CloudProgressRead> read(String protectedPlayerId) async {
    reads += 1;
    await readGate?.future;
    if (unknown) return const CloudProgressRead.unknown();
    final value = snapshot;
    return value == null
        ? const CloudProgressRead.missing()
        : CloudProgressRead.present(value);
  }

  @override
  Future<CloudProgressSnapshot> write({
    required String protectedPlayerId,
    required ProgressSaveSnapshot local,
    required int? expectedCloudRevision,
  }) async {
    if (rejectWrite || snapshot?.cloudRevision != expectedCloudRevision) {
      throw const CloudProgressWriteConflict();
    }
    writes += 1;
    snapshot = CloudProgressSnapshot(
      state: local.state,
      contentFingerprint: local.contentFingerprint,
      cloudRevision: (expectedCloudRevision ?? 0) + 1,
      savedAt: DateTime.utc(2026),
    );
    return snapshot!;
  }
}
