import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'account_protection_service.dart';

/// Establishes Firebase identity only. It never reads or writes player data.
final class FirebaseAnonymousAuthGateway implements AccountProtectionGateway {
  FirebaseAnonymousAuthGateway({this.auth});

  final FirebaseAuth? auth;

  FirebaseAuth get _firebaseAuth => auth ?? FirebaseAuth.instance;

  @override
  bool get isConfigured => auth != null || Firebase.apps.isNotEmpty;

  @override
  Future<ProtectedPlayerIdentity?> restoreIdentity({
    required String accountId,
    required String? expectedPlayerId,
  }) async {
    final auth = _firebaseAuth;
    // The first stream event is emitted only after persisted credentials have
    // been restored, which avoids replacing a valid web session during startup.
    var user = await auth.authStateChanges().first;

    if (expectedPlayerId != null) {
      if (user == null || user.uid != expectedPlayerId) {
        throw StateError(
          'The restored Firebase identity does not match the device guest.',
        );
      }
    } else {
      if (user != null && !user.isAnonymous) {
        throw StateError(
          'A linked Firebase identity cannot be reassigned automatically.',
        );
      }
      if (user != null) await auth.signOut();
      user = (await auth.signInAnonymously()).user;
    }

    if (user == null) return null;
    return ProtectedPlayerIdentity(
      playerId: user.uid,
      providerIds: user.providerData
          .map((provider) => provider.providerId)
          .where((providerId) => providerId.isNotEmpty)
          .toSet(),
    );
  }
}
