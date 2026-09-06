import 'package:flutter/foundation.dart';

import '../models/account_protection_state.dart';
import 'device_guest_slot_store.dart';

class ProtectedPlayerIdentity {
  const ProtectedPlayerIdentity({
    required this.playerId,
    this.providerIds = const <String>{},
  });

  final String playerId;
  final Set<String> providerIds;
}

abstract interface class AccountProtectionGateway {
  bool get isConfigured;

  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  });
}

/// Owns the app-wide distinction between a device profile and a protected
/// player identity. Progress synchronization remains in the dedicated sync
/// services and must not infer cloud authority from a local username.
class AccountProtectionService extends ChangeNotifier {
  AccountProtectionService({this.gateway, DeviceGuestSlotStore? guestSlots})
    : _guestSlots = guestSlots ?? DeviceGuestSlotStore();

  final AccountProtectionGateway? gateway;
  final DeviceGuestSlotStore _guestSlots;
  AccountProtectionState _state = const AccountProtectionState(
    status: AccountProtectionStatus.starting,
  );
  var _isInitialized = false;

  AccountProtectionState get state => _state;
  bool get isInitialized => _isInitialized;
  var _selectionRevision = 0;

  Future<void> initialize({String? accountId}) async {
    if (_isInitialized) {
      await selectAccount(accountId);
      return;
    }
    await selectAccount(accountId);
    _isInitialized = true;
  }

  Future<void> selectAccount(String? accountId) async {
    final revision = ++_selectionRevision;
    final configuredGateway = gateway;
    if (configuredGateway == null || !configuredGateway.isConfigured) {
      _setStateIfCurrent(revision, const AccountProtectionState.localOnly());
      return;
    }

    try {
      final slot = await _guestSlots.read();
      if (accountId == null || slot == null || slot.accountId != accountId) {
        _setStateIfCurrent(
          revision,
          const AccountProtectionState(
            status: AccountProtectionStatus.localOnly,
            message: 'This local profile is not connected to a cloud identity.',
          ),
        );
        return;
      }

      final identity = await configuredGateway.restoreIdentity(
        accountId: accountId,
        expectedPlayerId: slot.firebaseUid,
      );
      if (identity != null) {
        await _guestSlots.bindFirebaseUid(
          accountId: accountId,
          firebaseUid: identity.playerId,
        );
      }
      _setStateIfCurrent(
        revision,
        identity == null
            ? const AccountProtectionState(
                status: AccountProtectionStatus.guest,
                message:
                    'Cloud identity is unavailable. Progress remains on this device.',
              )
            : identity.providerIds.isEmpty
            ? AccountProtectionState(
                status: AccountProtectionStatus.guest,
                protectedPlayerId: identity.playerId,
                message:
                    'Device guest identity established. Progress is not cloud-synced yet.',
              )
            : AccountProtectionState(
                status: AccountProtectionStatus.protected,
                protectedPlayerId: identity.playerId,
                providerIds: identity.providerIds,
                message: 'Progress protection is active.',
              ),
      );
    } catch (error, stackTrace) {
      debugPrint('Account protection startup failed: $error\n$stackTrace');
      _setStateIfCurrent(
        revision,
        const AccountProtectionState(
          status: AccountProtectionStatus.error,
          message:
              'Progress is still safe on this device. Cloud protection could not be checked.',
        ),
      );
    }
  }

  void _setStateIfCurrent(int revision, AccountProtectionState value) {
    if (revision == _selectionRevision) _setState(value);
  }

  void _setState(AccountProtectionState value) {
    _state = value;
    notifyListeners();
  }
}
