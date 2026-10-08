import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform branding readiness documents source and generator', () {
    final evidence = File(
      'docs/PLATFORM_BRANDING_READINESS.md',
    ).readAsStringSync();
    final brandingReadme = File('assets/branding/README.md').readAsStringSync();
    final generator = File('tool/generate_brand_assets.dart').readAsStringSync();

    for (final path in [
      'assets/branding/nestarium_source.png',
      'assets/images/ui/app_logo.png',
      'tool/generate_brand_assets.dart',
      'web/favicon.png',
      'web/icons/*.png',
      'android/app/src/main/res/drawable-nodpi/launch_image.png',
      'android/app/src/main/res/mipmap-*/ic_launcher.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png',
      'windows/runner/resources/app_icon.ico',
    ]) {
      expect(evidence, contains(path), reason: path);
    }

    expect(brandingReadme, contains('nestarium_source.png'));
    expect(brandingReadme, contains('NESTARIUM'));
    expect(generator, contains('nestarium_source.png'));
    expect(generator, contains("'web/icons'"));
    expect(generator, contains("path.contains('maskable')"));
    expect(generator, contains('image.encodeIco'));
  });

  test('roadmap records final logo approval after owner approval', () {
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final decisionPacket = File(
      'docs/RELEASE_DECISION_PACKET.md',
    ).readAsStringSync();

    expect(
      roadmap,
      contains('[x] Approve the final Nestarium logo and regenerate platform branding assets.'),
    );
    expect(decisionPacket, contains('Final logo approved: yes'));
    expect(decisionPacket, contains('Final logo and platform branding approval'));
  });
}

