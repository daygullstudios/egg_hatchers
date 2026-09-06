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

    await service.keepThisDevice();

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

final class _CloudRepository implements CloudProgressRepository {
  _CloudRepository({this.snapshot, this.unknown = false});

  CloudProgressSnapshot? snapshot;
  final bool unknown;
  var writes = 0;

  @override
  Future<CloudProgressRead> read(String protectedPlayerId) async {
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
    if (snapshot?.cloudRevision != expectedCloudRevision) {
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
