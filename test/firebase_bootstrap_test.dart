import 'package:egg_hatchers/firebase_options.dart';
import 'package:egg_hatchers/services/firebase_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase registrations belong only to Egg Hatchers development', () {
    expect(FirebaseBootstrap.projectId, 'egg-hatchers-dev');
    expect(DefaultFirebaseOptions.web.projectId, FirebaseBootstrap.projectId);
    expect(
      DefaultFirebaseOptions.android.projectId,
      FirebaseBootstrap.projectId,
    );
    expect(DefaultFirebaseOptions.ios.projectId, FirebaseBootstrap.projectId);
    expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.egghatchers.game');
  });

  test('Firebase bootstrap is limited to currently registered platforms', () {
    expect(
      FirebaseBootstrap.supportsPlatform(
        isWeb: true,
        platform: TargetPlatform.windows,
      ),
      isTrue,
    );
    expect(
      FirebaseBootstrap.supportsPlatform(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      FirebaseBootstrap.supportsPlatform(
        isWeb: false,
        platform: TargetPlatform.iOS,
      ),
      isTrue,
    );
    expect(
      FirebaseBootstrap.supportsPlatform(
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      isFalse,
    );
  });
}
