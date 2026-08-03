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

  test('registered effects are complete audio files, not tiny tones', () {
    for (final sound in Sfx.values) {
      final file = File('assets/${sound.assetPath}');
      expect(file.lengthSync(), greaterThan(5000), reason: sound.name);
      final header = file.readAsBytesSync().take(4).toList();
      final isWave = header.toString() == [82, 73, 70, 70].toString();
      final isMp3 =
          header.length >= 2 && header[0] == 0xFF && header[1] >= 0xE0;
      expect(isWave || isMp3, isTrue, reason: '${sound.name} format');
    }
  });

  test('recorded effects have cooldowns long enough to avoid self-overlap', () {
    expect(Sfx.eggCrack.assetPath, endsWith('.mp3'));
    expect(Sfx.eggCrack.cooldownMs, greaterThanOrEqualTo(1585));
    expect(Sfx.purchase.assetPath, endsWith('.mp3'));
    expect(Sfx.purchase.cooldownMs, greaterThanOrEqualTo(2750));
    expect(Sfx.finisherSlash.assetPath, endsWith('.mp3'));
    expect(Sfx.finisherSlash.cooldownMs, greaterThanOrEqualTo(165));
  });
}
