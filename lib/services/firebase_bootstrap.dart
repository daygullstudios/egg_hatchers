import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initializes the isolated Egg Hatchers development Firebase project.
///
/// This bootstrap deliberately enables no authentication, Firestore, or cloud
/// progress behavior. Local saves remain the sole gameplay authority until the
/// later identity and conflict-safe synchronization phases are implemented.
abstract final class FirebaseBootstrap {
  static const projectId = 'egg-hatchers-dev';

  static bool get isSupportedPlatform =>
      supportsPlatform(isWeb: kIsWeb, platform: defaultTargetPlatform);

  static bool supportsPlatform({
    required bool isWeb,
    required TargetPlatform platform,
  }) =>
      isWeb ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;

  static Future<bool> initialize() async {
    if (!isSupportedPlatform) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('Firebase development bootstrap failed: $error\n$stackTrace');
      return false;
    }
  }
}
