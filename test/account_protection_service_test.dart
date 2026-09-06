import 'package:egg_hatchers/models/account_protection_state.dart';
import 'package:egg_hatchers/models/progress_sync_checkpoint.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/progress_sync_checkpoint_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('unconfigured builds report device-only progress', () async {
    final service = AccountProtectionService();

    await service.initialize(accountId: 'guest_test');

    expect(service.isInitialized, isTrue);
    expect(service.state.status, AccountProtectionStatus.localOnly);
    expect(service.state.isProtected, isFalse);
  });

  test('configured signed-out builds report an unprotected guest', () async {
    await DeviceGuestSlotStore().activate('guest_test');
    final service = AccountProtectionService(gateway: _Gateway(identity: null));

    await service.initialize(accountId: 'guest_test');

    expect(service.state.status, AccountProtectionStatus.guest);
    expect(service.state.canProtect, isTrue);
  });

  test('restored provider identity reports protected progress', () async {
    await DeviceGuestSlotStore().activate('guest_test');
    final service = AccountProtectionService(
      gateway: _Gateway(
        identity: ProtectedPlayerIdentity(
          playerId: 'player-123',
          providerIds: {'google.com'},
        ),
      ),
    );

    await service.initialize(accountId: 'guest_test');

    expect(service.state.status, AccountProtectionStatus.protected);
    expect(service.state.protectedPlayerId, 'player-123');
    expect(service.state.providerIds, {'google.com'});
  });

  test('identity restore failure cannot claim progress is protected', () async {
    await DeviceGuestSlotStore().activate('guest_test');
    final service = AccountProtectionService(gateway: _Gateway(error: true));

    await service.initialize(accountId: 'guest_test');

    expect(service.state.status, AccountProtectionStatus.error);
    expect(service.state.isProtected, isFalse);
  });

  test('anonymous identity remains explicitly unprotected', () async {
    await DeviceGuestSlotStore().activate('guest_test');
    final service = AccountProtectionService(
      gateway: _Gateway(
        identity: ProtectedPlayerIdentity(playerId: 'anonymous-123'),
      ),
    );

    await service.initialize(accountId: 'guest_test');

    expect(service.state.status, AccountProtectionStatus.guest);
    expect(service.state.isProtected, isFalse);
    expect(service.state.protectedPlayerId, 'anonymous-123');
    expect((await DeviceGuestSlotStore().read())?.firebaseUid, 'anonymous-123');
  });

  test('named local profiles never invoke the identity gateway', () async {
    await DeviceGuestSlotStore().activate('guest_test');
    final gateway = _Gateway(
      identity: const ProtectedPlayerIdentity(playerId: 'anonymous-123'),
    );
    final service = AccountProtectionService(gateway: gateway);

    await service.initialize(accountId: 'player_named');

    expect(service.state.status, AccountProtectionStatus.localOnly);
    expect(gateway.restoreCalls, 0);
  });

  test(
    'linking Google preserves the anonymous UID and sync ancestry',
    () async {
      final slots = DeviceGuestSlotStore();
      await slots.activate('guest_test');
      await slots.bindFirebaseUid(
        accountId: 'guest_test',
        firebaseUid: 'anonymous-123',
      );
      final checkpoints = ProgressSyncCheckpointStore(accountId: 'guest_test');
      await checkpoints.write(
        ProgressSyncCheckpoint(
          contentFingerprint: List.filled(64, 'a').join(),
          cloudRevision: 4,
          recordedAt: DateTime.utc(2026),
        ),
      );
      final service = AccountProtectionService(
        gateway: _Gateway(
          identity: const ProtectedPlayerIdentity(playerId: 'anonymous-123'),
          linkedIdentity: const ProtectedPlayerIdentity(
            playerId: 'anonymous-123',
            providerIds: {'google.com'},
          ),
        ),
      );
      await service.initialize(accountId: 'guest_test');

      final outcome = await service.protectWithGoogle(accountId: 'guest_test');

      expect(outcome.status, AccountProtectionAttemptStatus.protected);
      expect(service.state.isProtected, isTrue);
      expect((await slots.read())?.firebaseUid, 'anonymous-123');
      expect((await checkpoints.read())?.cloudRevision, 4);
    },
  );

  test('opening an existing Google account clears old sync ancestry', () async {
    final slots = DeviceGuestSlotStore();
    await slots.activate('guest_test');
    await slots.bindFirebaseUid(
      accountId: 'guest_test',
      firebaseUid: 'anonymous-123',
    );
    final checkpoints = ProgressSyncCheckpointStore(accountId: 'guest_test');
    await checkpoints.write(
      ProgressSyncCheckpoint(
        contentFingerprint: List.filled(64, 'a').join(),
        cloudRevision: 4,
        recordedAt: DateTime.utc(2026),
      ),
    );
    final service = AccountProtectionService(
      gateway: _Gateway(
        identity: const ProtectedPlayerIdentity(playerId: 'anonymous-123'),
        linkedIdentity: const ProtectedPlayerIdentity(
          playerId: 'google-existing',
          providerIds: {'google.com'},
        ),
      ),
    );
    await service.initialize(accountId: 'guest_test');

    final outcome = await service.protectWithGoogle(accountId: 'guest_test');

    expect(outcome.status, AccountProtectionAttemptStatus.switched);
    expect((await slots.read())?.firebaseUid, 'google-existing');
    expect(await checkpoints.read(), isNull);
  });
}

final class _Gateway implements AccountProtectionGateway {
  _Gateway({this.identity, this.linkedIdentity, this.error = false});

  final ProtectedPlayerIdentity? identity;
  final ProtectedPlayerIdentity? linkedIdentity;
  final bool error;
  int restoreCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  bool get canLinkGoogle => true;

  @override
  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  }) async {
    restoreCalls += 1;
    if (error) throw StateError('offline');
    return identity;
  }

  @override
  Future<ProtectedPlayerIdentity?> linkGoogle({
    required String expectedPlayerId,
  }) async => linkedIdentity;
}
