import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_state.dart';

/// Persists and restores player progress using shared_preferences.
class SaveService {
  SaveService({this.accountId});

  static const _legacySaveKey = 'egg_hatchers_player_state';
  static const progressFormat = 'egg_hatchers_player_progress';
  static const progressSchemaVersion = 1;
  final String? accountId;

  String get _saveKey => accountId == null
      ? _legacySaveKey
      : '${_legacySaveKey}_account_$accountId';

  String get _backupKey => '${_saveKey}_backup';

  Future<PlayerState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final primary = _decode(prefs.getString(_saveKey));
    if (primary != null) return primary;

    final backupJson = prefs.getString(_backupKey);
    final backup = _decode(backupJson);
    if (backup != null && backupJson != null) {
      await prefs.setString(_saveKey, backupJson);
    }
    return backup;
  }

  static PlayerState? _decode(String? jsonString) {
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      if (json['format'] == progressFormat) {
        if (json['schemaVersion'] != progressSchemaVersion ||
            json['playerState'] is! Map<String, dynamic>) {
          return null;
        }
        return PlayerState.fromJson(
          json['playerState'] as Map<String, dynamic>,
        );
      }

      // Saves written before the progress envelope are the PlayerState JSON.
      return PlayerState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static int _revision(String? jsonString) {
    if (jsonString == null) return 0;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      if (json['format'] != progressFormat ||
          json['schemaVersion'] != progressSchemaVersion) {
        return 0;
      }
      return (json['revision'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> save(PlayerState state) async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_saveKey);
    if (_decode(currentJson) != null) {
      await prefs.setString(_backupKey, currentJson!);
    }
    final jsonString = jsonEncode({
      'format': progressFormat,
      'schemaVersion': progressSchemaVersion,
      'revision': _revision(currentJson) + 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'playerState': state.toJson(),
    });
    await prefs.setString(_saveKey, jsonString);
  }

  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove(_backupKey);
  }
}
