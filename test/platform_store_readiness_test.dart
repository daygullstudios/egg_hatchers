import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform store readiness documents Android signing boundaries', () {
    final evidence = File('docs/PLATFORM_STORE_READINESS.md').readAsStringSync();
    final androidBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final androidIgnore = File('android/.gitignore').readAsStringSync();
    final keyExample = File('android/key.properties.example').readAsStringSync();

    expect(evidence, contains('android/app/build.gradle.kts'));
    expect(evidence, contains('android/key.properties.example'));
    expect(evidence, contains('android/.gitignore'));
    expect(evidence, contains('signed App'));
    expect(evidence, contains('Bundle'));

    expect(androidBuild, contains('val hasReleaseSigning'));
    expect(androidBuild, contains('rootProject.file("key.properties")'));
    expect(androidBuild, contains('signingConfigs'));
    expect(androidBuild, contains('signingConfig'));
    expect(keyExample, contains('storeFile=../upload-keystore.jks'));

    for (final ignored in ['key.properties', '**/*.keystore', '**/*.jks']) {
      expect(androidIgnore, contains(ignored), reason: ignored);
      expect(evidence, contains(ignored), reason: ignored);
    }
  });

  test('platform store readiness documents iOS and disclosure blockers', () {
    final evidence = File('docs/PLATFORM_STORE_READINESS.md').readAsStringSync();
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final template = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();

    expect(evidence, contains('ios/Runner.xcodeproj/project.pbxproj'));
    expect(evidence, contains('docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md'));
    expect(evidence, contains('Apple Developer Team'));
    expect(evidence, contains('App Store Connect'));
    expect(evidence, contains('Real-device testing'));
    expect(evidence, contains('docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md'));
    expect(iosProject, contains('PRODUCT_BUNDLE_IDENTIFIER = com.egghatchers.game'));
    expect(iosProject, contains('CODE_SIGN_STYLE = Automatic'));

    for (final item in [
      '[ ] Configure Android release signing and protect the signing credentials.',
      '[ ] Build and inspect a signed Android App Bundle if Android is selected.',
      '[ ] Configure iOS signing and run real-device testing if iOS is selected.',
      '[ ] Complete store names, descriptions, screenshots, ratings and disclosures.',
      '[ ] Complete Google Play Data Safety and Apple privacy answers from the actual',
      '[ ] Verify account-deletion and support links from each selected store.',
    ]) {
      expect(roadmap, contains(item), reason: item);
    }

    expect(template, contains('Android App Bundle path/checksum'));
    expect(template, contains('iOS archive/build identifier'));
    expect(template, contains('Store Data Safety/Privacy answers source reference'));
  });
}

