import 'package:shared_preferences/shared_preferences.dart';

abstract final class AccountStorage {
  static String key(String baseKey, String? accountId) {
    if (accountId == null || accountId.isEmpty) return baseKey;
    return '$baseKey.account.$accountId';
  }

  static String itemKey(String baseKey, String itemId, String? accountId) {
    if (accountId == null || accountId.isEmpty) return '${baseKey}_$itemId';
    return '$baseKey.account.$accountId.$itemId';
  }

  static Future<void> deleteAccountData(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final marker = '.account.$accountId';
    final keys = prefs
        .getKeys()
        .where((key) => key.endsWith(marker) || key.contains('$marker.'))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
