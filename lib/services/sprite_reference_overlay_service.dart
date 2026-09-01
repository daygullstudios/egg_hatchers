import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_storage.dart';

/// Persists per-animal reference overlay unlocks in shared_preferences.
class SpriteReferenceOverlayService extends ChangeNotifier {
  static const _unlocksKey = 'spriteReferenceOverlayUnlocks';

  final Map<String, bool> _unlockedByAnimal = {};
  String? _accountId;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  bool isUnlocked(String animalId) => _unlockedByAnimal[animalId] ?? false;

  Future<void> initialize({
    String? accountId,
    bool migrateLegacyData = false,
  }) async {
    _accountId = accountId;
    _unlockedByAnimal.clear();
    final prefs = await SharedPreferences.getInstance();
    final unlocksKey = AccountStorage.key(_unlocksKey, accountId);
    var raw = prefs.getString(unlocksKey);
    if (raw == null && accountId != null && migrateLegacyData) {
      raw = prefs.getString(_unlocksKey);
    }
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value == true) {
              _unlockedByAnimal[entry.key] = true;
            }
          }
        }
      } catch (_) {
        // Ignore corrupt unlock data.
      }
    }
    if (accountId != null && !prefs.containsKey(unlocksKey)) {
      await _persist();
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> unlock(String animalId) async {
    if (isUnlocked(animalId)) return true;

    _unlockedByAnimal[animalId] = true;
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> _persist() async {
    final encoded = <String, dynamic>{
      for (final entry in _unlockedByAnimal.entries)
        if (entry.value) entry.key: true,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AccountStorage.key(_unlocksKey, _accountId),
      jsonEncode(encoded),
    );
  }
}
