import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release asset rights audit covers shipped media roots', () {
    final audit = File('docs/ASSET_RIGHTS_RELEASE_AUDIT.md').readAsStringSync();

    const mediaRoots = [
      'assets/images/animals/',
      'assets/images/animal_themes/retro_pixel/',
      'assets/images/animal_themes/realistic/',
      'assets/images/eggs/',
      'assets/images/egg_themes/retro_pixel/',
      'assets/images/egg_themes/realistic/',
      'assets/images/bosses/',
      'assets/images/boss_backgrounds/realistic/',
      'assets/images/hatched_egg_heads/',
      'assets/images/projectiles/',
      'assets/images/ui/',
      'assets/sounds/music/',
      'assets/sounds/sfx/',
    ];

    for (final root in mediaRoots) {
      expect(audit, contains(root), reason: root);
    }
  });

  test(
    'release asset rights audit tracks music and external sound records',
    () {
      final audit = File(
        'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
      ).readAsStringSync();
      final soundSources = File('assets/sounds/SOURCES.md').readAsStringSync();

      for (final file
          in Directory('assets/sounds/music').listSync().whereType<File>().map(
            (file) => file.path.replaceAll(r'\', '/'),
          )) {
        expect(audit, contains(file), reason: file);
        expect(
          audit,
          contains('need owner confirmation'),
          reason: 'Music is not release-cleared until source is confirmed.',
        );
      }

      const externalEffects = [
        'assets/sounds/sfx/purchase_real.mp3',
        'assets/sounds/sfx/finisher_slash_real.mp3',
        'assets/sounds/sfx/egg_crack_reference.mp3',
      ];
      for (final file in externalEffects) {
        expect(audit, contains(file), reason: file);
        expect(soundSources, contains(file.split('/').last), reason: file);
      }
    },
  );
}
