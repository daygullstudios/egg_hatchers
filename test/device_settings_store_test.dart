import 'package:egg_hatchers/models/device_settings.dart';
import 'package:egg_hatchers/services/device_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = DeviceSettingsStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh installs receive safe defaults', () async {
    final settings = await store.read();

    expect(settings.backgroundThemeId, isNull);
    expect(settings.animalSpriteThemeId, isNull);
    expect(settings.showBattleBackgrounds, isTrue);
    expect(settings.reducedBattleEffects, isFalse);
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.showCustomSprites, isTrue);
    expect(settings.musicEnabled, isTrue);
    expect(settings.sfxEnabled, isTrue);
    expect(settings.musicVolume, 0.6);
    expect(settings.sfxVolume, 0.8);
  });

  test('reads every legacy sandbox setting during migration', () async {
    SharedPreferences.setMockInitialValues({
      'selectedBackgroundThemeId': 'night',
      'animalSpriteTheme': 'retro',
      'showBattleBackgrounds': false,
      'reducedBattleEffects': true,
      'hapticsEnabled': false,
      'showCustomSprites': false,
      'audioMusicEnabled': false,
      'audioSfxEnabled': false,
      'audioMusicVolume': 0.25,
      'audioSfxVolume': 0.75,
    });

    final settings = await store.read();

    expect(settings.backgroundThemeId, 'night');
    expect(settings.animalSpriteThemeId, 'retro');
    expect(settings.showBattleBackgrounds, isFalse);
    expect(settings.reducedBattleEffects, isTrue);
    expect(settings.hapticsEnabled, isFalse);
    expect(settings.showCustomSprites, isFalse);
    expect(settings.musicEnabled, isFalse);
    expect(settings.sfxEnabled, isFalse);
    expect(settings.musicVolume, 0.25);
    expect(settings.sfxVolume, 0.75);
  });

  test('versioned settings override legacy values and clamp volumes', () async {
    SharedPreferences.setMockInitialValues({
      'audioMusicVolume': 0.2,
      'audioSfxVolume': 0.2,
    });

    await store.writeMusicVolume(4);
    await store.writeSfxVolume(-2);
    final settings = await store.read();

    expect(settings.musicVolume, 1);
    expect(settings.sfxVolume, 0);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getDouble(DeviceSettingsStore.musicVolumeKey), 1);
    expect(preferences.getDouble(DeviceSettingsStore.sfxVolumeKey), 0);
  });

  test(
    'reset changes settings without clearing unrelated player data',
    () async {
      SharedPreferences.setMockInitialValues({
        'playerAccounts': 'valuable account data',
        DeviceSettingsStore.musicEnabledKey: false,
        DeviceSettingsStore.reducedBattleEffectsKey: true,
        DeviceSettingsStore.backgroundThemeKey: 'night',
      });

      await store.resetToDefaults();

      final settings = await store.read();
      expect(settings.musicEnabled, DeviceSettings.defaults.musicEnabled);
      expect(
        settings.reducedBattleEffects,
        DeviceSettings.defaults.reducedBattleEffects,
      );
      expect(settings.backgroundThemeId, isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('playerAccounts'), 'valuable account data');
    },
  );
}
