import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_egg.dart';
import 'account_storage.dart';

/// Persists player-created custom eggs in shared_preferences.
class CustomEggService extends ChangeNotifier {
  static const _storageKey = 'customEggs';

  final List<CustomEgg> _eggs = [];
  String? _accountId;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<CustomEgg> get allEggs => List.unmodifiable(_eggs);

  /// Enabled custom eggs with hatchable animals for the shop.
  List<CustomEgg> shopEggs(int lifetimeCoinsEarned, {int rebirthLevel = 0}) =>
      _eggs
          .where(
            (egg) => egg.isShopValid(
              lifetimeCoinsEarned,
              rebirthLevel: rebirthLevel,
            ),
          )
          .toList();

  Future<void> initialize({
    String? accountId,
    bool migrateLegacyData = false,
  }) async {
    _accountId = accountId;
    final prefs = await SharedPreferences.getInstance();
    _eggs.clear();

    final storageKey = AccountStorage.key(_storageKey, accountId);
    var saved = prefs.getString(storageKey);
    if (saved == null && accountId != null && migrateLegacyData) {
      saved = prefs.getString(_storageKey);
    }
    if (saved != null) {
      _eggs.addAll(CustomEgg.listFromJsonString(saved));
    }
    if (accountId != null && !prefs.containsKey(storageKey)) {
      await prefs.setString(storageKey, CustomEgg.listToJsonString(_eggs));
    }

    _isInitialized = true;
    notifyListeners();
  }

  CustomEgg? getById(String id) {
    for (final egg in _eggs) {
      if (egg.id == id) return egg;
    }
    return null;
  }

  Future<void> saveEgg(CustomEgg egg) async {
    var toSave = egg;
    final index = _eggs.indexWhere((e) => e.id == egg.id);

    if (index >= 0) {
      _eggs[index] = toSave;
    } else {
      while (_eggs.any((e) => e.id == toSave.id)) {
        toSave = toSave.copyWith(id: CustomEgg.generateUniqueId());
      }
      _eggs.add(toSave);
    }

    notifyListeners();
    await _persist();
  }

  Future<void> deleteEgg(String id) async {
    _eggs.removeWhere((egg) => egg.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AccountStorage.key(_storageKey, _accountId),
      CustomEgg.listToJsonString(_eggs),
    );
  }
}
