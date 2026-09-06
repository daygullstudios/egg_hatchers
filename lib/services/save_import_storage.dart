import 'package:shared_preferences/shared_preferences.dart';

/// Storage seam for checked import writes and failure-injection tests.
abstract interface class SaveImportStorage {
  Future<Map<String, Object>> readAll();
  Future<bool> write(String key, Object value);
  Future<bool> remove(String key);
}

class PreferencesImportStorage implements SaveImportStorage {
  @override
  Future<Map<String, Object>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return {
      for (final key in prefs.getKeys())
        if (prefs.get(key) != null) key: prefs.get(key)!,
    };
  }

  @override
  Future<bool> write(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) return prefs.setString(key, value);
    if (value is bool) return prefs.setBool(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);
    throw StateError('Unsupported preference type.');
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }
}
