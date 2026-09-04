import 'package:flutter/foundation.dart';

import '../models/account_protection_state.dart';

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

  Future<ProtectedPlayerIdentity?> restoreIdentity();
}

/// Owns the app-wide distinction between a device profile and a protected
/// player identity. Progress synchronization remains in the dedicated sync
/// services and must not infer cloud authority from a local username.
class AccountProtectionService extends ChangeNotifier {
  AccountProtectionService({this.gateway});

  final AccountProtectionGateway? gateway;
  AccountProtectionState _state = const AccountProtectionState(
    status: AccountProtectionStatus.starting,
  );
  var _isInitialized = false;

  AccountProtectionState get state => _state;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final configuredGateway = gateway;
    if (configuredGateway == null || !configuredGateway.isConfigured) {
      _setState(const AccountProtectionState.localOnly());
      _isInitialized = true;
      return;
    }

    try {
      final identity = await configuredGateway.restoreIdentity();
      _setState(
        identity == null
            ? const AccountProtectionState(
                status: AccountProtectionStatus.guest,
                message: 'Progress is not protected across devices yet.',
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
      _setState(
        const AccountProtectionState(
          status: AccountProtectionStatus.error,
          message:
              'Progress is still safe on this device. Cloud protection could not be checked.',
        ),
      );
    }
    _isInitialized = true;
  }

  void _setState(AccountProtectionState value) {
    _state = value;
    notifyListeners();
  }
}
