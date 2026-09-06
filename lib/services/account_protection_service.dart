import 'package:flutter/foundation.dart';

import '../models/account_protection_state.dart';
import 'device_guest_slot_store.dart';
import 'progress_sync_checkpoint_store.dart';

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
  bool get canLinkGoogle;

  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  });

  Future<ProtectedPlayerIdentity?> linkGoogle({
    required String expectedPlayerId,
  });
}

enum AccountProtectionAttemptStatus { protected, switched, canceled, failed }

class AccountProtectionAttempt {
  const AccountProtectionAttempt({required this.status, required this.message});

  final AccountProtectionAttemptStatus status;
  final String message;

  bool get succeeded =>
      status == AccountProtectionAttemptStatus.protected ||
      status == AccountProtectionAttemptStatus.switched;
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
  bool get canLinkGoogle => gateway?.canLinkGoogle ?? false;
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
                    'A cloud copy exists for this device guest. Link Google to recover it on other devices.',
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

  Future<AccountProtectionAttempt> protectWithGoogle({
    required String accountId,
  }) async {
    final revision = ++_selectionRevision;
    final configuredGateway = gateway;
    final slot = await _guestSlots.read();
    final expectedPlayerId = slot?.firebaseUid;
    if (revision != _selectionRevision) {
      return const AccountProtectionAttempt(
        status: AccountProtectionAttemptStatus.failed,
        message: 'The active player changed before Google started.',
      );
    }
    if (configuredGateway == null ||
        !configuredGateway.isConfigured ||
        slot?.accountId != accountId ||
        expectedPlayerId == null) {
      return const AccountProtectionAttempt(
        status: AccountProtectionAttemptStatus.failed,
        message: 'Google protection is unavailable for this local profile.',
      );
    }
    if (_state.isProtected) {
      return const AccountProtectionAttempt(
        status: AccountProtectionAttemptStatus.protected,
        message: 'This progress is already protected.',
      );
    }

    _setStateIfCurrent(
      revision,
      AccountProtectionState(
        status: AccountProtectionStatus.syncing,
        protectedPlayerId: expectedPlayerId,
        message: 'Connecting Google without changing your progress…',
      ),
    );
    try {
      final identity = await configuredGateway.linkGoogle(
        expectedPlayerId: expectedPlayerId,
      );
      if (revision != _selectionRevision) {
        return const AccountProtectionAttempt(
          status: AccountProtectionAttemptStatus.failed,
          message: 'The active player changed before Google finished.',
        );
      }
      if (identity == null) {
        _setState(
          AccountProtectionState(
            status: AccountProtectionStatus.guest,
            protectedPlayerId: expectedPlayerId,
            message:
                'Google linking was canceled. Your guest save is unchanged.',
          ),
        );
        return const AccountProtectionAttempt(
          status: AccountProtectionAttemptStatus.canceled,
          message: 'Google linking canceled.',
        );
      }
      if (!identity.providerIds.contains('google.com')) {
        throw StateError('Google was not present on the returned identity.');
      }

      final switched = identity.playerId != expectedPlayerId;
      if (switched) {
        await ProgressSyncCheckpointStore(accountId: accountId).clear();
      }
      await _guestSlots.bindFirebaseUid(
        accountId: accountId,
        firebaseUid: identity.playerId,
      );
      _setState(
        AccountProtectionState(
          status: AccountProtectionStatus.protected,
          protectedPlayerId: identity.playerId,
          providerIds: identity.providerIds,
          message: switched
              ? 'Google account opened. Compare its cloud progress before choosing a save.'
              : 'Progress is protected with Google and can be recovered on other devices.',
        ),
      );
      return AccountProtectionAttempt(
        status: switched
            ? AccountProtectionAttemptStatus.switched
            : AccountProtectionAttemptStatus.protected,
        message: switched
            ? 'Google account opened. Review the progress comparison below.'
            : 'Progress protected with Google.',
      );
    } catch (error, stackTrace) {
      debugPrint('Google account protection failed: $error\n$stackTrace');
      if (revision == _selectionRevision) {
        _setState(
          AccountProtectionState(
            status: AccountProtectionStatus.guest,
            protectedPlayerId: expectedPlayerId,
            message:
                'Google could not be connected. Your guest save and cloud copy are unchanged.',
          ),
        );
      }
      return const AccountProtectionAttempt(
        status: AccountProtectionAttemptStatus.failed,
        message: 'Could not connect Google. Please try again.',
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
