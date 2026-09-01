import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_state.dart';

/// Persists and restores player progress using shared_preferences.
class SaveService {
  SaveService({this.accountId});

  static const _legacySaveKey = 'egg_hatchers_player_state';
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
      return PlayerState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PlayerState state) async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_saveKey);
    if (_decode(currentJson) != null) {
      await prefs.setString(_backupKey, currentJson!);
    }
    final jsonString = jsonEncode(state.toJson());
    await prefs.setString(_saveKey, jsonString);
  }

  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove(_backupKey);
  }
}
