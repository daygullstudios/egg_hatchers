import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

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

/// Progress guards run while settings/customization writes may be in flight.
/// Read the existing legacy backend directly: reload() would replace the shared
/// preference cache with an older snapshot and hide those concurrent writes.
/// Keep the installed backend and its historical `flutter.` prefix; this is not
/// a migration to SharedPreferencesAsync (different Android backend by default).
class PreferencesProgressStorage extends PreferencesImportStorage {
  PreferencesProgressStorage(this.primaryKey);
  final String primaryKey;
  @override
  Future<Map<String, Object>> readAll() async {
    const prefix = 'flutter.';
    final values = await SharedPreferencesStorePlatform.instance
        .getAllWithParameters(
          GetAllParameters(
            filter: PreferencesFilter(
              prefix: prefix,
              allowList: {'$prefix$primaryKey', '$prefix${primaryKey}_backup'},
            ),
          ),
        );
    return {
      for (final entry in values.entries)
        entry.key.substring(prefix.length): entry.value,
    };
  }
}
