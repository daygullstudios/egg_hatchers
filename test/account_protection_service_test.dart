import 'package:egg_hatchers/models/account_protection_state.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unconfigured builds report device-only progress', () async {
    final service = AccountProtectionService();

    await service.initialize();

    expect(service.isInitialized, isTrue);
    expect(service.state.status, AccountProtectionStatus.localOnly);
    expect(service.state.isProtected, isFalse);
  });

  test('configured signed-out builds report an unprotected guest', () async {
    final service = AccountProtectionService(gateway: _Gateway(identity: null));

    await service.initialize();

    expect(service.state.status, AccountProtectionStatus.guest);
    expect(service.state.canProtect, isTrue);
  });

  test('restored provider identity reports protected progress', () async {
    final service = AccountProtectionService(
      gateway: const _Gateway(
        identity: ProtectedPlayerIdentity(
          playerId: 'player-123',
          providerIds: {'google.com'},
        ),
      ),
    );

    await service.initialize();

    expect(service.state.status, AccountProtectionStatus.protected);
    expect(service.state.protectedPlayerId, 'player-123');
    expect(service.state.providerIds, {'google.com'});
  });

  test('identity restore failure cannot claim progress is protected', () async {
    final service = AccountProtectionService(
      gateway: const _Gateway(error: true),
    );

    await service.initialize();

    expect(service.state.status, AccountProtectionStatus.error);
    expect(service.state.isProtected, isFalse);
  });
}

final class _Gateway implements AccountProtectionGateway {
  const _Gateway({this.identity, this.error = false});

  final ProtectedPlayerIdentity? identity;
  final bool error;

  @override
  bool get isConfigured => true;

  @override
  Future<ProtectedPlayerIdentity?> restoreIdentity() async {
    if (error) throw StateError('offline');
    return identity;
  }
}
