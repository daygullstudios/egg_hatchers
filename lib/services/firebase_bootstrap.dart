import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initializes the isolated Nestarium development Firebase project.
///
/// Optional network capability only. Local save safety/bootstrap must complete
/// first, but valid local gameplay does not wait for this future. Identity and
/// conflict-safe sync are configured separately after it succeeds.
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
