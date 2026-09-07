import 'dart:convert';

import '../models/custom_egg.dart';
import '../models/custom_sprite_data.dart';
import '../models/player_state.dart';
import '../models/sprite_rating_claim.dart';
import 'save_service.dart';
import 'device_settings_store.dart';

/// Strict inspection: never use the normal loader's fallback or repair path.
PlayerState? validateTransferredValue(String key, Object value) {
  const boolKeys = {
    DeviceSettingsStore.showBattleBackgroundsKey,
    DeviceSettingsStore.reducedBattleEffectsKey,
    DeviceSettingsStore.hapticsEnabledKey,
    DeviceSettingsStore.showCustomSpritesKey,
    DeviceSettingsStore.musicEnabledKey,
    DeviceSettingsStore.sfxEnabledKey,
    'showBattleBackgrounds',
    'reducedBattleEffects',
    'hapticsEnabled',
    'showCustomSprites',
    'audioMusicEnabled',
    'audioSfxEnabled',
    'rottenShellFinalBattleTutorialCompleted',
  };
  const stringKeys = {
    DeviceSettingsStore.backgroundThemeKey,
    DeviceSettingsStore.animalSpriteThemeKey,
    'selectedBackgroundThemeId',
    'animalSpriteTheme',
    'playerAccountId',
    'playerAccountDisplayName',
    'playerAccountUsername',
    'playerAccountCreatedAt',
  };
  const volumeKeys = {
    DeviceSettingsStore.musicVolumeKey,
    DeviceSettingsStore.sfxVolumeKey,
    'audioMusicVolume',
    'audioSfxVolume',
  };
  if ((boolKeys.contains(key) ||
              key.startsWith('customSpriteMigrationComplete')) &&
          value is! bool ||
      (stringKeys.contains(key) || key.startsWith('devForceSlot')) &&
          value is! String ||
      volumeKeys.contains(key) &&
          (value is! double || !value.isFinite || value < 0 || value > 1) ||
      key == 'playerAccountAvatarColor' && value is! int) {
    throw const FormatException('Setting type');
  }
  if (key.startsWith('egg_hatchers_player_state')) {
    final snapshot = SaveService.decodeSnapshot(value);
    if (snapshot == null) throw const FormatException('Progress payload');
    return snapshot.state;
  }
  if (key == 'customEggs' || key.startsWith('customEggs.account.')) {
    final eggs = jsonDecode(value as String) as List;
    final ids = <String>{};
    for (final raw in eggs) {
      final egg = CustomEgg.fromJson(raw as Map<String, dynamic>);
      if (egg.id.isEmpty || !ids.add(egg.id) || egg.cost < 0) {
        throw const FormatException('Custom egg');
      }
      checkTransferredShapes(raw, egg.toJson());
    }
  } else if (key.startsWith('customSprite_') ||
      key.startsWith('customSprite.account.')) {
    final raw = jsonDecode(value as String) as Map<String, dynamic>;
    final sprite = CustomSpriteData.fromJson(raw);
    if (raw['size'] != null && raw['size'] != sprite.size ||
        raw['pixels'] is! List) {
      throw const FormatException('Sprite size');
    }
    checkTransferredShapes(raw, sprite.toJson());
    if ((raw['pixels'] as List).any(
      (v) => v != null && (v is! int || v < 0 || v > 0xFFFFFFFF),
    )) {
      throw const FormatException('Sprite color');
    }
  } else if (key == 'spriteRatingClaims' ||
      key.startsWith('spriteRatingClaims.account.')) {
    for (final animal
        in (jsonDecode(value as String) as Map<String, dynamic>).values) {
      for (final claim in (animal as Map<String, dynamic>).values) {
        SpriteRatingClaim.fromJson(claim as Map<String, dynamic>);
      }
    }
  } else if (key == 'spriteReferenceOverlayUnlocks' ||
      key.startsWith('spriteReferenceOverlayUnlocks.account.')) {
    final unlocks = jsonDecode(value as String) as Map<String, dynamic>;
    if (unlocks.values.any((value) => value is! bool)) {
      throw const FormatException('Overlay unlock');
    }
  }
  return null;
}

void checkTransferredShapes(Object? raw, Object? parsed) {
  if (raw == null || parsed == null) return;
  if (parsed is bool && raw is! bool ||
      parsed is String && raw is! String ||
      parsed is num && (raw is! num || !raw.isFinite || raw < 0)) {
    throw const FormatException('Saved field type');
  }
  if (parsed is List) {
    if (raw is! List || raw.length != parsed.length) {
      throw const FormatException('Saved list');
    }
    for (var i = 0; i < raw.length; i++) {
      checkTransferredShapes(raw[i], parsed[i]);
    }
  } else if (parsed is Map) {
    if (raw is! Map) throw const FormatException('Saved map');
    for (final key in raw.keys) {
      if (parsed.containsKey(key)) {
        checkTransferredShapes(raw[key], parsed[key]);
      }
    }
  }
}
