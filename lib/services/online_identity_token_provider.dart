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
    return (auth ?? FirebaseAuth.instance).currentUser?.getIdToken();
  }
}
