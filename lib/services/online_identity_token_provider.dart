import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

abstract interface class OnlineIdentityTokenProvider {
  Future<String?> getIdToken();
}

/// Supplies the currently restored Firebase identity to Nestarium's hosted
/// services. It never creates, replaces, links, or signs out an identity.
final class FirebaseOnlineIdentityTokenProvider
    implements OnlineIdentityTokenProvider {
  FirebaseOnlineIdentityTokenProvider({this.auth});

  final FirebaseAuth? auth;

  @override
  Future<String?> getIdToken() async {
    if (auth == null && Firebase.apps.isEmpty) return null;
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    var user = firebaseAuth.currentUser;
    if (user == null) {
      try {
        user = await firebaseAuth
            .authStateChanges()
            .firstWhere((candidate) => candidate != null)
            .timeout(const Duration(seconds: 8));
      } on TimeoutException {
        return null;
      }
    }
    return user?.getIdToken();
  }
}
