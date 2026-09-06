import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'account_protection_service.dart';

/// Establishes Firebase identity only. It never reads or writes player data.
final class FirebaseAnonymousAuthGateway implements AccountProtectionGateway {
  FirebaseAnonymousAuthGateway({this.auth});

  final FirebaseAuth? auth;

  FirebaseAuth get _firebaseAuth => auth ?? FirebaseAuth.instance;
  static Future<void>? _googleInitialization;

  @override
  bool get isConfigured => auth != null || Firebase.apps.isNotEmpty;

  // The playtest Web registration can use Firebase's provider popup directly.
  // Native clients remain fail-closed until their OAuth client IDs and Android
  // signing fingerprints are provisioned in the development project.
  @override
  bool get canLinkGoogle => kIsWeb;

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

  @override
  Future<ProtectedPlayerIdentity?> linkGoogle({
    required String expectedPlayerId,
  }) async {
    final auth = _firebaseAuth;
    final current = auth.currentUser;
    if (current == null ||
        current.uid != expectedPlayerId ||
        !current.isAnonymous) {
      throw StateError('The expected anonymous guest is not active.');
    }

    try {
      final UserCredential result;
      if (kIsWeb) {
        result = await _linkWebGoogle(auth, current);
      } else {
        final credential = await _requestNativeGoogleCredential();
        if (credential == null) return null;
        result = await _linkCredentialOrOpenExisting(auth, current, credential);
      }
      final user = result.user ?? auth.currentUser;
      if (user == null) return null;
      await user.reload();
      return _identity(auth.currentUser ?? user);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  Future<UserCredential> _linkWebGoogle(FirebaseAuth auth, User current) async {
    try {
      return await current.linkWithPopup(GoogleAuthProvider());
    } on FirebaseAuthException catch (error) {
      if (!_isExistingAccountCollision(error.code)) rethrow;
      final credential = error.credential;
      return credential == null
          ? auth.signInWithPopup(GoogleAuthProvider())
          : auth.signInWithCredential(credential);
    }
  }

  Future<AuthCredential?> _requestNativeGoogleCredential() async {
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;
    final account = await GoogleSignIn.instance.authenticate();
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an identity token.');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  Future<UserCredential> _linkCredentialOrOpenExisting(
    FirebaseAuth auth,
    User current,
    AuthCredential credential,
  ) async {
    try {
      return await current.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (!_isExistingAccountCollision(error.code)) rethrow;
      return auth.signInWithCredential(error.credential ?? credential);
    }
  }

  static bool _isExistingAccountCollision(String code) =>
      code == 'credential-already-in-use' ||
      code == 'account-exists-with-different-credential' ||
      code == 'email-already-in-use';

  static ProtectedPlayerIdentity _identity(User user) =>
      ProtectedPlayerIdentity(
        playerId: user.uid,
        providerIds: user.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toSet(),
      );
}
