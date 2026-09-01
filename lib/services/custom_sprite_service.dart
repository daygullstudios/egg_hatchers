import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_data.dart';
import '../models/custom_sprite_data.dart';
import 'account_storage.dart';

/// Persists per-animal custom pixel sprites in shared_preferences.
class CustomSpriteService extends ChangeNotifier {
  static const _showCustomSpritesKey = 'showCustomSprites';
  static const _spriteKey = 'customSprite';
  static const _migrationKey = 'customSpriteMigrationComplete';

  final Map<String, CustomSpriteData> _sprites = {};
  String? _accountId;
  bool _showCustomSprites = true;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Whether saved custom sprites are shown in gameplay UI (default ON).
  bool get showCustomSprites => _showCustomSprites;

  bool getShowCustomSprites() => _showCustomSprites;

  Future<void> initialize({
    String? accountId,
    bool migrateLegacyData = false,
  }) async {
    _accountId = accountId;
    final prefs = await SharedPreferences.getInstance();
    _sprites.clear();
    _showCustomSprites = prefs.getBool(_showCustomSpritesKey) ?? true;
    final migrationKey = AccountStorage.key(_migrationKey, accountId);
    final shouldMigrate =
        accountId != null &&
        migrateLegacyData &&
        prefs.getBool(migrationKey) != true;

    for (final animal in GameData.animals) {
      final spriteKey = AccountStorage.itemKey(
        _spriteKey,
        animal.id,
        accountId,
      );
      var saved = prefs.getString(spriteKey);
      if (saved == null && shouldMigrate) {
        saved = prefs.getString('${_spriteKey}_${animal.id}');
      }
      if (saved == null) continue;

      try {
        final sprite = CustomSpriteData.fromJsonString(saved);
        if (sprite.hasVisiblePixels) {
          _sprites[animal.id] = sprite;
          if (accountId != null && !prefs.containsKey(spriteKey)) {
            await prefs.setString(spriteKey, saved);
          }
        }
      } catch (_) {
        // Ignore corrupt entries.
      }
    }
    if (accountId != null) {
      await prefs.setBool(migrationKey, true);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Saved custom sprite data (ignores visibility toggle).
  CustomSpriteData? getSprite(String animalId) => _sprites[animalId];

  /// Custom sprite for gameplay display; null when [showCustomSprites] is OFF.
  CustomSpriteData? getDisplaySprite(String animalId) {
    if (!_showCustomSprites) return null;
    return _sprites[animalId];
  }

  bool hasCustomSprite(String animalId) => _sprites.containsKey(animalId);

  Future<void> setShowCustomSprites(bool value) async {
    if (_showCustomSprites == value) return;

    _showCustomSprites = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCustomSpritesKey, value);
  }

  Future<void> resetAllCustomSprites() async {
    _sprites.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    for (final animal in GameData.animals) {
      await prefs.remove(
        AccountStorage.itemKey(_spriteKey, animal.id, _accountId),
      );
    }
  }

  Future<void> saveSprite(String animalId, CustomSpriteData data) async {
    if (!data.hasVisiblePixels) {
      await resetSprite(animalId);
      return;
    }

    _sprites[animalId] = data;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AccountStorage.itemKey(_spriteKey, animalId, _accountId),
      data.toJsonString(),
    );
  }

  Future<void> resetSprite(String animalId) async {
    _sprites.remove(animalId);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      AccountStorage.itemKey(_spriteKey, animalId, _accountId),
    );
  }
}
