import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _releaseImageDirectories = [
  'assets/images/animals',
  'assets/images/hatched_egg_heads',
  'assets/images/animal_themes/retro_pixel',
  'assets/images/animal_themes/realistic',
  'assets/images/boss_backgrounds/realistic',
  'assets/images/eggs',
  'assets/images/egg_themes/retro_pixel',
  'assets/images/egg_themes/realistic',
  'assets/images/ui',
  'assets/images/projectiles',
  'assets/images/bosses',
];

void main() {
  test('app logo and install icons stay valid and release-sized', () {
    const expectedSizes = {
      'assets/images/ui/app_logo.png': 512,
      'web/favicon.png': 64,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
    };
    var totalBytes = 0;

    for (final entry in expectedSizes.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      totalBytes += file.lengthSync();

      final image = img.decodePng(file.readAsBytesSync());
      expect(image, isNotNull, reason: entry.key);
      expect(image!.width, entry.value, reason: entry.key);
      expect(image.height, entry.value, reason: entry.key);
    }

    expect(
      totalBytes,
      lessThan(1500000),
      reason: 'Logo and install icons should remain optimized for downloads.',
    );
  });

  test('release image assets decode and stay optimized', () {
    var checked = 0;

    for (final directoryPath in _releaseImageDirectories) {
      final directory = Directory(directoryPath);
      expect(directory.existsSync(), isTrue, reason: directoryPath);

      for (final file in directory.listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll(r'\', '/');
        if (path.split('/').last.startsWith('.')) continue;

        final extension = path.split('.').last.toLowerCase();
        expect({'png', 'jpg', 'jpeg'}, contains(extension), reason: path);
        expect(
          path.toLowerCase(),
          isNot(contains('placeholder')),
          reason: path,
        );
        expect(
          path.toLowerCase(),
          isNot(contains('reference')),
          reason: path,
        );

        final image = img.decodeImage(file.readAsBytesSync());
        expect(image, isNotNull, reason: path);
        expect(image!.width, greaterThan(0), reason: path);
        expect(image.height, greaterThan(0), reason: path);
        expect(
          file.lengthSync(),
          lessThan(750 * 1024),
          reason: '$path should remain release-sized',
        );
        checked++;
      }
    }

    expect(checked, greaterThan(200));
  });
}
