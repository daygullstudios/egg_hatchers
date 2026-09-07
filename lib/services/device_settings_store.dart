import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device_settings.dart';
import 'save_import_storage.dart';
import 'save_storage_lease.dart';

/// Versioned persistence boundary for device-owned settings.
///
/// Reads fall back to the original sandbox keys so upgrades retain every
/// preference. New writes use namespaced keys and leave legacy data untouched.
final class DeviceSettingsStore extends ChangeNotifier {
  DeviceSettingsStore({SaveImportStorage? storage})
    : _storage = storage ?? PreferencesKeyStorage(_labels.keys.toSet());

  final SaveImportStorage _storage;
  final Map<String, _SettingIntent> _pending = {};
  final Set<Timer> _watches = {};
  static final Map<String, Future<void>> _writes = {};
  var _operations = 0;
  var _revision = 0;
  var _disposed = false;

  bool get hasUnsavedChanges => _pending.isNotEmpty;
  bool get isSaving => _operations != 0;
  bool get needsAttention =>
      _pending.values.any((intent) => intent.failed || intent.slow);
  List<String> get unsavedLabels =>
      _pending.keys.map((key) => _labels[key]!).toSet().toList();

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

  static const _labels = {
    backgroundThemeKey: 'Background',
    animalSpriteThemeKey: 'Animal style',
    showBattleBackgroundsKey: 'Battle backgrounds',
    reducedBattleEffectsKey: 'Reduced battle effects',
    hapticsEnabledKey: 'Haptic feedback',
    showCustomSpritesKey: 'Custom animal visibility',
    musicEnabledKey: 'Music',
    sfxEnabledKey: 'Sound effects',
    musicVolumeKey: 'Music volume',
    sfxVolumeKey: 'Sound effects volume',
    _legacyBackgroundThemeKey: 'Background',
    _legacyAnimalSpriteThemeKey: 'Animal style',
    _legacyShowBattleBackgroundsKey: 'Battle backgrounds',
    _legacyReducedBattleEffectsKey: 'Reduced battle effects',
    _legacyHapticsEnabledKey: 'Haptic feedback',
    _legacyShowCustomSpritesKey: 'Custom animal visibility',
    _legacyMusicEnabledKey: 'Music',
    _legacySfxEnabledKey: 'Sound effects',
    _legacyMusicVolumeKey: 'Music volume',
    _legacySfxVolumeKey: 'Sound effects volume',
  };

  /// Fresh installed-backend values by default. Runtime reinitialization can
  /// explicitly keep this session's unsaved choices without calling them saved.
  Future<DeviceSettings> read({bool includePending = false}) async {
    Map<String, Object> values;
    while (true) {
      final revision = _revision;
      values = Map<String, Object>.from(await _storage.readAll());
      // A write can finish between the backend snapshot and this continuation.
      // Re-read then; do not replace a just-saved runtime choice with that old
      // snapshot after its pending entry has already been acknowledged.
      if (!includePending || revision == _revision) break;
    }
    if (includePending) {
      for (final entry in _pending.entries) {
        final value = entry.value.value;
        if (value == null) {
          values.remove(entry.key);
        } else {
          values[entry.key] = value;
        }
      }
    }
    T? value<T>(String key) => values[key] is T ? values[key] as T : null;
    return DeviceSettings(
      backgroundThemeId:
          value<String>(backgroundThemeKey) ??
          value<String>(_legacyBackgroundThemeKey),
      animalSpriteThemeId:
          value<String>(animalSpriteThemeKey) ??
          value<String>(_legacyAnimalSpriteThemeKey),
      showBattleBackgrounds:
          value<bool>(showBattleBackgroundsKey) ??
          value<bool>(_legacyShowBattleBackgroundsKey) ??
          DeviceSettings.defaults.showBattleBackgrounds,
      reducedBattleEffects:
          value<bool>(reducedBattleEffectsKey) ??
          value<bool>(_legacyReducedBattleEffectsKey) ??
          DeviceSettings.defaults.reducedBattleEffects,
      hapticsEnabled:
          value<bool>(hapticsEnabledKey) ??
          value<bool>(_legacyHapticsEnabledKey) ??
          DeviceSettings.defaults.hapticsEnabled,
      showCustomSprites:
          value<bool>(showCustomSpritesKey) ??
          value<bool>(_legacyShowCustomSpritesKey) ??
          DeviceSettings.defaults.showCustomSprites,
      musicEnabled:
          value<bool>(musicEnabledKey) ??
          value<bool>(_legacyMusicEnabledKey) ??
          DeviceSettings.defaults.musicEnabled,
      sfxEnabled:
          value<bool>(sfxEnabledKey) ??
          value<bool>(_legacySfxEnabledKey) ??
          DeviceSettings.defaults.sfxEnabled,
      musicVolume: _volume(
        value<num>(musicVolumeKey)?.toDouble() ??
            value<num>(_legacyMusicVolumeKey)?.toDouble(),
        DeviceSettings.defaults.musicVolume,
      ),
      sfxVolume: _volume(
        value<num>(sfxVolumeKey)?.toDouble() ??
            value<num>(_legacySfxVolumeKey)?.toDouble(),
        DeviceSettings.defaults.sfxVolume,
      ),
    );
  }

  Future<bool> writeBackgroundTheme(String value) =>
      _write(backgroundThemeKey, value);

  Future<bool> writeAnimalSpriteTheme(String value) =>
      _write(animalSpriteThemeKey, value);

  Future<bool> writeShowBattleBackgrounds(bool value) =>
      _write(showBattleBackgroundsKey, value);

  Future<bool> writeReducedBattleEffects(bool value) =>
      _write(reducedBattleEffectsKey, value);

  Future<bool> writeHapticsEnabled(bool value) =>
      _write(hapticsEnabledKey, value);

  Future<bool> writeShowCustomSprites(bool value) =>
      _write(showCustomSpritesKey, value);

  Future<bool> writeMusicEnabled(bool value) => _write(musicEnabledKey, value);

  Future<bool> writeSfxEnabled(bool value) => _write(sfxEnabledKey, value);

  Future<bool> writeMusicVolume(double value) =>
      _write(musicVolumeKey, _volume(value, 0.6));

  Future<bool> writeSfxVolume(double value) =>
      _write(sfxVolumeKey, _volume(value, 0.8));

  /// Resets only device settings. Accounts, progress, and content are untouched.
  // This is a checked multi-key reset, not an atomic transaction. Failed keys
  // remain listed for retry; it never reports a partially applied reset saved.
  Future<bool> resetToDefaults() async {
    const defaults = DeviceSettings.defaults;
    final results = await Future.wait([
      _write(backgroundThemeKey, null),
      _write(_legacyBackgroundThemeKey, null),
      _write(animalSpriteThemeKey, null),
      _write(_legacyAnimalSpriteThemeKey, null),
      writeShowBattleBackgrounds(defaults.showBattleBackgrounds),
      writeReducedBattleEffects(defaults.reducedBattleEffects),
      writeHapticsEnabled(defaults.hapticsEnabled),
      writeShowCustomSprites(defaults.showCustomSprites),
      writeMusicEnabled(defaults.musicEnabled),
      writeSfxEnabled(defaults.sfxEnabled),
      writeMusicVolume(defaults.musicVolume),
      writeSfxVolume(defaults.sfxVolume),
    ]);
    return results.every((saved) => saved);
  }

  static double _volume(double? value, double fallback) {
    final candidate = value ?? fallback;
    if (!candidate.isFinite) return fallback;
    return candidate.clamp(0.0, 1.0).toDouble();
  }

  Future<bool> _write(String key, Object? value) {
    if (_disposed) return Future.value(false);
    final intent = _SettingIntent(value);
    _revision++;
    _pending[key] = intent;
    return _enqueue(key, intent);
  }

  Future<void> retry() async {
    if (_disposed || isSaving) return;
    await Future.wait([
      for (final entry in _pending.entries.toList())
        _enqueue(entry.key, entry.value),
    ]);
  }

  Future<bool> _enqueue(String key, _SettingIntent intent) {
    _operations++;
    intent.failed = false;
    intent.slow = false;
    final watch = Timer(const Duration(seconds: 8), () {
      if (_disposed || !identical(_pending[key], intent)) return;
      intent.slow = true;
      notifyListeners();
    });
    _watches.add(watch);
    final work = (_writes[key] ?? Future<void>.value()).then((_) async {
      Future<void> Function()? release;
      try {
        if (_disposed || !identical(_pending[key], intent)) return false;
        release = await acquireProgressWriteLease(key);
        final before = (await _storage.readAll())[key];
        if (_disposed || !identical(_pending[key], intent)) return false;
        // A previous uncertain write may already be present. Verify that value
        // without a second mutation. Settings choices are explicit last-intent
        // wins; these are not progress records or cloud authority.
        if (before != intent.value) {
          final accepted = intent.value == null
              ? await _storage.remove(key)
              : await _storage.write(key, intent.value!);
          if (!accepted || (await _storage.readAll())[key] != intent.value) {
            intent.failed = true;
            return false;
          }
        }
        if (_disposed || !identical(_pending[key], intent)) return false;
        _pending.remove(key);
        _revision++;
        return true;
      } catch (_) {
        intent.failed = true;
        return false;
      } finally {
        try {
          await release?.call();
        } catch (_) {
          // The backend result above is still authoritative if lease cleanup
          // itself fails. Never leak platform exception details into UI.
        } finally {
          watch.cancel();
          _watches.remove(watch);
          _operations--;
          if (!_disposed) notifyListeners();
        }
      }
    });
    final settled = work.then<void>((_) {}, onError: (Object _) {});
    _writes[key] = settled;
    settled.then((_) {
      if (identical(_writes[key], settled)) _writes.remove(key);
    });
    notifyListeners();
    return work;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final watch in _watches) {
      watch.cancel();
    }
    _watches.clear();
    super.dispose();
  }
}

class _SettingIntent {
  _SettingIntent(this.value);
  final Object? value;
  bool failed = false;
  bool slow = false;
}
