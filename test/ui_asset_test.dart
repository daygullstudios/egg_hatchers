import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

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
}
