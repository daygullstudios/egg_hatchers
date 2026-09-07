import 'dart:async';
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
  AccountProtectionService({
    this.gateway,
    DeviceGuestSlotStore? guestSlots,
    this.slowAfter = const Duration(seconds: 8),
  }) : _guestSlots = guestSlots ?? DeviceGuestSlotStore();

  final AccountProtectionGateway? gateway;
  final DeviceGuestSlotStore _guestSlots;
  final Duration slowAfter;
  AccountProtectionState _state = const AccountProtectionState(
    status: AccountProtectionStatus.starting,
  );
  var _isInitialized = false;

  AccountProtectionState get state => _state;
  bool get isInitialized => _isInitialized;
  bool get canLinkGoogle => !isChecking && (gateway?.canLinkGoogle ?? false);
  var _selectionRevision = 0;
  String? _selectedAccountId;
  Future<void>? _selectionPending;
  Future<ProtectedPlayerIdentity?>? _gatewayPending;
  Timer? _slowTimer;
  bool _disposed = false, _suspended = false;
  bool get isChecking => _selectionPending != null;
  Future<void> retryConnection() => selectAccount(_selectedAccountId);

  Future<void> pauseForSaveImport() async {
    _suspended = true;
    _selectionRevision++;
    _slowTimer?.cancel();
    await _selectionPending;
    await _gatewayPending;
  }

  Future<void> initialize({String? accountId}) async {
    if (_isInitialized) {
      await selectAccount(accountId);
      return;
    }
    await selectAccount(accountId);
    _isInitialized = true;
  }

  Future<void> selectAccount(String? accountId) {
    if (_disposed || _suspended) return Future.value();
    if (accountId != null &&
        _selectedAccountId == accountId &&
        _selectionPending != null) {
      return _selectionPending!;
    }
    final revision = ++_selectionRevision;
    _slowTimer?.cancel();
    final samePlayer = accountId == _selectedAccountId;
    _selectedAccountId = accountId;
    if (accountId == null) {
      _setState(const AccountProtectionState.localOnly());
      return Future.value();
    }
    final completion = Completer<void>();
    _selectionPending = completion.future;
    if (!samePlayer || _state.protectedPlayerId == null) {
      _setState(
        const AccountProtectionState(
          status: AccountProtectionStatus.starting,
          message: 'Checking cloud identity. Local play does not need to wait.',
        ),
      );
    }
    unawaited(
      _selectAccount(accountId, revision)
          .catchError((Object _) {
            _setStateIfCurrent(
              revision,
              const AccountProtectionState(
                status: AccountProtectionStatus.error,
                message:
                    'Cloud identity could not be checked. Local play is still available.',
              ),
            );
          })
          .whenComplete(() {
            if (identical(_selectionPending, completion.future)) {
              _selectionPending = null;
            }
            completion.complete();
            if (!_disposed) notifyListeners();
          }),
    );
    return completion.future;
  }

  Future<void> _selectAccount(String accountId, int revision) async {
    bool current() =>
        !_disposed && !_suspended && revision == _selectionRevision;
    final configuredGateway = gateway;
    if (configuredGateway == null || !configuredGateway.isConfigured) {
      _setStateIfCurrent(revision, const AccountProtectionState.localOnly());
      return;
    }

    final slowTimer = Timer(
      slowAfter,
      () => _setStateIfCurrent(
        revision,
        const AccountProtectionState(
          status: AccountProtectionStatus.error,
          message:
              'Cloud identity is taking longer than expected. You can keep playing locally while the check finishes.',
        ),
      ),
    );
    _slowTimer = slowTimer;
    try {
      // Firebase identity operations cannot safely overlap. A timed-out UI does
      // not cancel a request or authorize a replacement anonymous identity.
      try {
        await _gatewayPending;
      } catch (_) {
        /* Earlier selection owns its result. */
      }
      if (!current()) return;
      final slot = await _guestSlots.read();
      if (!current()) return;
      if (slot == null || slot.accountId != accountId) {
        _setStateIfCurrent(
          revision,
          const AccountProtectionState(
            status: AccountProtectionStatus.localOnly,
            message: 'This local profile is not connected to a cloud identity.',
          ),
        );
        return;
      }

      final request = configuredGateway.restoreIdentity(
        accountId: accountId,
        expectedPlayerId: slot.firebaseUid,
      );
      _gatewayPending = request;
      final ProtectedPlayerIdentity? identity;
      try {
        identity = await request;
      } finally {
        if (identical(_gatewayPending, request)) _gatewayPending = null;
      }
      if (!current()) return;
      final latest = await _guestSlots.read();
      if (!current()) return;
      if (latest?.accountId != slot.accountId ||
          latest?.generation != slot.generation ||
          latest?.firebaseUid != slot.firebaseUid ||
          slot.firebaseUid != null &&
              identity != null &&
              identity.playerId != slot.firebaseUid) {
        throw StateError('Device identity ownership changed during restore');
      }
      if (identity != null) {
        await _guestSlots.bindFirebaseUid(
          accountId: accountId,
          firebaseUid: identity.playerId,
          expectedGeneration: slot.generation,
          stillCurrent: current,
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
                message: configuredGateway.canLinkGoogle
                    ? 'Device guest identity connected. Check cloud-save status below; link Google for recovery on other devices.'
                    : 'Device guest identity connected. Check cloud-save status below. Keep a save export before changing browsers or devices.',
              )
            : AccountProtectionState(
                status: AccountProtectionStatus.protected,
                protectedPlayerId: identity.playerId,
                providerIds: identity.providerIds,
                message: 'Progress protection is active.',
              ),
      );
    } catch (error) {
      debugPrint('Account protection startup failed (${error.runtimeType}).');
      _setStateIfCurrent(
        revision,
        const AccountProtectionState(
          status: AccountProtectionStatus.error,
          message:
              'Cloud identity could not be checked. Local play is still available. Keep a save export before changing devices.',
        ),
      );
    } finally {
      slowTimer.cancel();
    }
  }

  Future<AccountProtectionAttempt> protectWithGoogle({
    required String accountId,
  }) async {
    if (_disposed || _suspended || isChecking) {
      return const AccountProtectionAttempt(
        status: AccountProtectionAttemptStatus.failed,
        message:
            'Wait for the current identity check before connecting Google.',
      );
    }
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
    if (!_disposed && !_suspended && revision == _selectionRevision) {
      _setState(value);
    }
  }

  void _setState(AccountProtectionState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _slowTimer?.cancel();
    _selectionRevision++;
    super.dispose();
  }
}
