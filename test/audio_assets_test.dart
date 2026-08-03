import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:egg_hatchers/data/audio_assets.dart';

void main() {
  test('every registered audio asset exists', () {
    final assetPaths = {
      ...MusicTrack.values.map((track) => track.assetPath),
      ...Sfx.values.map((sound) => sound.assetPath),
    };

    for (final assetPath in assetPaths) {
      expect(
        File('assets/$assetPath').existsSync(),
        isTrue,
        reason: 'Missing audio asset: $assetPath',
      );
    }
  });

  test('registered effects are full layered WAV files, not tiny tones', () {
    for (final sound in Sfx.values) {
      final file = File('assets/${sound.assetPath}');
      expect(file.lengthSync(), greaterThan(10000), reason: sound.name);
      expect(
        file.readAsBytesSync().take(4).toList(),
        [82, 73, 70, 70],
        reason: '${sound.name} must be a RIFF WAV',
      );
    }
  });
}
