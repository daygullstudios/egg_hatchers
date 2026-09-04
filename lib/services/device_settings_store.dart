import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_settings.dart';

/// Versioned persistence boundary for device-owned settings.
///
/// Reads fall back to the original sandbox keys so upgrades retain every
/// preference. New writes use namespaced keys and leave legacy data untouched.
final class DeviceSettingsStore {
  const DeviceSettingsStore();

  static const backgroundThemeKey =
      'egg_hatchers.settings.visual.background_theme.v1';
  static const animalSpriteThemeKey =
      'egg_hatchers.settings.visual.animal_style.v1';
  static const showBattleBackgroundsKey =
      'egg_hatchers.settings.visual.battle_backgrounds.v1';
  static const reducedBattleEffectsKey =
      'egg_hatchers.settings.accessibility.reduced_battle_effects.v1';
  static const hapticsEnabledKey =
      'egg_hatchers.settings.feedback.haptics_enabled.v1';
  static const showCustomSpritesKey =
      'egg_hatchers.settings.visual.show_custom_sprites.v1';
  static const musicEnabledKey = 'egg_hatchers.settings.audio.music_enabled.v1';
  static const sfxEnabledKey = 'egg_hatchers.settings.audio.sfx_enabled.v1';
  static const musicVolumeKey = 'egg_hatchers.settings.audio.music_volume.v1';
  static const sfxVolumeKey = 'egg_hatchers.settings.audio.sfx_volume.v1';

  static const _legacyBackgroundThemeKey = 'selectedBackgroundThemeId';
  static const _legacyAnimalSpriteThemeKey = 'animalSpriteTheme';
  static const _legacyShowBattleBackgroundsKey = 'showBattleBackgrounds';
  static const _legacyReducedBattleEffectsKey = 'reducedBattleEffects';
  static const _legacyHapticsEnabledKey = 'hapticsEnabled';
  static const _legacyShowCustomSpritesKey = 'showCustomSprites';
  static const _legacyMusicEnabledKey = 'audioMusicEnabled';
  static const _legacySfxEnabledKey = 'audioSfxEnabled';
  static const _legacyMusicVolumeKey = 'audioMusicVolume';
  static const _legacySfxVolumeKey = 'audioSfxVolume';

  Future<DeviceSettings> read() async {
    final preferences = await SharedPreferences.getInstance();
    return DeviceSettings(
      backgroundThemeId:
          preferences.getString(backgroundThemeKey) ??
          preferences.getString(_legacyBackgroundThemeKey),
      animalSpriteThemeId:
          preferences.getString(animalSpriteThemeKey) ??
          preferences.getString(_legacyAnimalSpriteThemeKey),
      showBattleBackgrounds:
          preferences.getBool(showBattleBackgroundsKey) ??
          preferences.getBool(_legacyShowBattleBackgroundsKey) ??
          DeviceSettings.defaults.showBattleBackgrounds,
      reducedBattleEffects:
          preferences.getBool(reducedBattleEffectsKey) ??
          preferences.getBool(_legacyReducedBattleEffectsKey) ??
          DeviceSettings.defaults.reducedBattleEffects,
      hapticsEnabled:
          preferences.getBool(hapticsEnabledKey) ??
          preferences.getBool(_legacyHapticsEnabledKey) ??
          DeviceSettings.defaults.hapticsEnabled,
      showCustomSprites:
          preferences.getBool(showCustomSpritesKey) ??
          preferences.getBool(_legacyShowCustomSpritesKey) ??
          DeviceSettings.defaults.showCustomSprites,
      musicEnabled:
          preferences.getBool(musicEnabledKey) ??
          preferences.getBool(_legacyMusicEnabledKey) ??
          DeviceSettings.defaults.musicEnabled,
      sfxEnabled:
          preferences.getBool(sfxEnabledKey) ??
          preferences.getBool(_legacySfxEnabledKey) ??
          DeviceSettings.defaults.sfxEnabled,
      musicVolume: _volume(
        preferences.getDouble(musicVolumeKey) ??
            preferences.getDouble(_legacyMusicVolumeKey),
        DeviceSettings.defaults.musicVolume,
      ),
      sfxVolume: _volume(
        preferences.getDouble(sfxVolumeKey) ??
            preferences.getDouble(_legacySfxVolumeKey),
        DeviceSettings.defaults.sfxVolume,
      ),
    );
  }

  Future<void> writeBackgroundTheme(String value) =>
      _writeString(backgroundThemeKey, value);

  Future<void> writeAnimalSpriteTheme(String value) =>
      _writeString(animalSpriteThemeKey, value);

  Future<void> writeShowBattleBackgrounds(bool value) =>
      _writeBool(showBattleBackgroundsKey, value);

  Future<void> writeReducedBattleEffects(bool value) =>
      _writeBool(reducedBattleEffectsKey, value);

  Future<void> writeHapticsEnabled(bool value) =>
      _writeBool(hapticsEnabledKey, value);

  Future<void> writeShowCustomSprites(bool value) =>
      _writeBool(showCustomSpritesKey, value);

  Future<void> writeMusicEnabled(bool value) =>
      _writeBool(musicEnabledKey, value);

  Future<void> writeSfxEnabled(bool value) => _writeBool(sfxEnabledKey, value);

  Future<void> writeMusicVolume(double value) =>
      _writeDouble(musicVolumeKey, _volume(value, 0.6));

  Future<void> writeSfxVolume(double value) =>
      _writeDouble(sfxVolumeKey, _volume(value, 0.8));

  /// Resets only device settings. Accounts, progress, and content are untouched.
  Future<void> resetToDefaults() async {
    const defaults = DeviceSettings.defaults;
    await Future.wait([
      _remove(backgroundThemeKey),
      _remove(_legacyBackgroundThemeKey),
      _remove(animalSpriteThemeKey),
      _remove(_legacyAnimalSpriteThemeKey),
      writeShowBattleBackgrounds(defaults.showBattleBackgrounds),
      writeReducedBattleEffects(defaults.reducedBattleEffects),
      writeHapticsEnabled(defaults.hapticsEnabled),
      writeShowCustomSprites(defaults.showCustomSprites),
      writeMusicEnabled(defaults.musicEnabled),
      writeSfxEnabled(defaults.sfxEnabled),
      writeMusicVolume(defaults.musicVolume),
      writeSfxVolume(defaults.sfxVolume),
    ]);
  }

  static double _volume(double? value, double fallback) {
    final candidate = value ?? fallback;
    if (!candidate.isFinite) return fallback;
    return candidate.clamp(0.0, 1.0).toDouble();
  }

  Future<void> _writeString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<void> _writeBool(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  Future<void> _writeDouble(String key, double value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(key, value);
  }

  Future<void> _remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
