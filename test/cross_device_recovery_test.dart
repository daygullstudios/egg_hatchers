import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/cloud_progress_read.dart';
import 'package:egg_hatchers/models/progress_sync_state.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'existing identity recovery requires a choice and preserves cloud progress',
    () async {
      const firstAccount = 'guest_first_device';
      const secondAccount = 'guest_clean_device';
      const protectedPlayer = 'google-player';
      final cloud = _MemoryCloud();

      final firstSave = SaveService(accountId: firstAccount);
      await firstSave.save(
        GameData.startingPlayerState().copyWith(coins: 5000),
      );
      final firstSync = ProgressSyncService();
      addTearDown(firstSync.dispose);
      await firstSync.selectAccount(
        accountId: firstAccount,
        protectedPlayerId: protectedPlayer,
        cloud: cloud,
        applyCloud: (_) async => false,
      );

      expect(firstSync.state.status, ProgressSyncStatus.synced);
      expect(cloud.snapshot?.state.coins, 5000);
      expect(cloud.writes, 1);

      final secondSave = SaveService(accountId: secondAccount);
      await secondSave.save(
        GameData.startingPlayerState().copyWith(coins: 300),
      );
      final slots = DeviceGuestSlotStore();
      await slots.activate(secondAccount);
      await slots.bindFirebaseUid(
        accountId: secondAccount,
        firebaseUid: 'anonymous-clean-device',
      );
      final protection = AccountProtectionService(gateway: _RecoveryGateway());
      addTearDown(protection.dispose);
      await protection.initialize(accountId: secondAccount);

      final link = await protection.protectWithGoogle(accountId: secondAccount);

      expect(link.status, AccountProtectionAttemptStatus.switched);
      expect(protection.state.protectedPlayerId, protectedPlayer);
      expect((await slots.read())?.firebaseUid, protectedPlayer);

      final secondSync = ProgressSyncService();
      addTearDown(secondSync.dispose);
      await secondSync.selectAccount(
        accountId: secondAccount,
        protectedPlayerId: protection.state.protectedPlayerId,
        cloud: cloud,
        applyCloud: (state) async {
          await secondSave.save(state);
          return true;
        },
      );

      expect(secondSync.state.status, ProgressSyncStatus.conflict);
      expect((await secondSave.load())?.coins, 300);
      expect(cloud.snapshot?.state.coins, 5000);
      expect(cloud.writes, 1);

      final review = await secondSync.prepareConflictReview();
      expect(review, isNotNull);
      expect(review?.local.state.coins, 300);
      expect(review?.cloud.state.coins, 5000);
      expect(await secondSync.useCloud(review!), isTrue);

      expect((await secondSave.load())?.coins, 5000);
      expect(cloud.snapshot?.state.coins, 5000);
      expect(cloud.writes, 1);
    },
  );
}

final class _RecoveryGateway implements AccountProtectionGateway {
  @override
  bool get isConfigured => true;

  @override
  bool get canLinkGoogle => true;

  @override
  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  }) async => ProtectedPlayerIdentity(playerId: expectedPlayerId!);

  @override
  Future<ProtectedPlayerIdentity?> linkGoogle({
    required String expectedPlayerId,
  }) async => const ProtectedPlayerIdentity(
    playerId: 'google-player',
    providerIds: {'google.com'},
  );
}

final class _MemoryCloud implements CloudProgressRepository {
  CloudProgressSnapshot? snapshot;
  int writes = 0;

  @override
  Future<CloudProgressRead> read(String protectedPlayerId) async =>
      snapshot == null
      ? const CloudProgressRead.missing()
      : CloudProgressRead.present(snapshot!);

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
      savedAt: DateTime.now().toUtc(),
    );
  }
}
