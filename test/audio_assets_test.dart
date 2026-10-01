import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:egg_hatchers/data/audio_assets.dart';

List<int> _headerFor(File file) => file.readAsBytesSync().take(4).toList();

bool _isWaveOrMp3Header(List<int> header) {
  final isWave = header.toString() == [82, 73, 70, 70].toString();
  final isMp3 =
      (header.length >= 2 && header[0] == 0xFF && header[1] >= 0xE0) ||
      (header.length >= 3 &&
          header[0] == 0x49 &&
          header[1] == 0x44 &&
          header[2] == 0x33);
  return isWave || isMp3;
}

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
      expect(
        _isWaveOrMp3Header(_headerFor(file)),
        isTrue,
        reason: '${sound.name} format',
      );
    }
  });

  test('registered music tracks are complete and release-sized', () {
    for (final track in MusicTrack.values) {
      final file = File('assets/${track.assetPath}');
      expect(file.lengthSync(), greaterThan(100 * 1024), reason: track.name);
      expect(file.lengthSync(), lessThan(7 * 1024 * 1024), reason: track.name);
      expect(
        _isWaveOrMp3Header(_headerFor(file)),
        isTrue,
        reason: '${track.name} format',
      );
    }
  });

  test('every shipped audio file is registered', () {
    final registeredPaths = {
      ...MusicTrack.values.map((track) => 'assets/${track.assetPath}'),
      ...Sfx.values.map((sound) => 'assets/${sound.assetPath}'),
    };
    final shippedFiles = [
      ...Directory('assets/sounds/music').listSync().whereType<File>(),
      ...Directory('assets/sounds/sfx').listSync().whereType<File>(),
    ];

    expect(shippedFiles, isNotEmpty);
    for (final file in shippedFiles) {
      final path = file.path.replaceAll(r'\', '/');
      expect(registeredPaths, contains(path), reason: path);
    }
  });

  test('recorded effects have cooldowns long enough to avoid self-overlap', () {
    expect(Sfx.eggCrack.assetPath, endsWith('.mp3'));
    expect(Sfx.eggCrack.cooldownMs, greaterThanOrEqualTo(1000));
    expect(Sfx.purchase.assetPath, endsWith('.mp3'));
    expect(Sfx.purchase.cooldownMs, greaterThanOrEqualTo(2750));
    expect(Sfx.finisherSlash.assetPath, endsWith('.mp3'));
    expect(Sfx.finisherSlash.cooldownMs, greaterThanOrEqualTo(165));
  });
}
