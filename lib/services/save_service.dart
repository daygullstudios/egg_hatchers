import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_state.dart';

class ProgressSaveSnapshot {
  const ProgressSaveSnapshot({
    required this.state,
    required this.revision,
    required this.savedAt,
    required this.contentFingerprint,
    required this.isLegacyFormat,
  });

  final PlayerState state;
  final int revision;
  final DateTime savedAt;
  final String contentFingerprint;
  final bool isLegacyFormat;
}

/// Persists and restores player progress using shared_preferences.
class SaveService {
  SaveService({this.accountId});

  static const _legacySaveKey = 'egg_hatchers_player_state';
  static const _legacyRottenShellTutorialKey =
      'rottenShellFinalBattleTutorialCompleted';
  static const progressFormat = 'egg_hatchers_player_progress';
  static const progressSchemaVersion = 1;
  final String? accountId;

  String get _saveKey => accountId == null
      ? _legacySaveKey
      : '${_legacySaveKey}_account_$accountId';

  String get _backupKey => '${_saveKey}_backup';

  Future<PlayerState?> load() async {
    return (await loadSnapshot())?.state;
  }

  Future<ProgressSaveSnapshot?> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final primary = _decodeSnapshot(prefs.getString(_saveKey));
    if (primary != null) return primary;

    final backupJson = prefs.getString(_backupKey);
    final backup = _decodeSnapshot(backupJson);
    if (backup != null && backupJson != null) {
      await prefs.setString(_saveKey, backupJson);
    }
    return backup;
  }

  static ProgressSaveSnapshot? _decodeSnapshot(String? jsonString) {
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      if (json['format'] == progressFormat) {
        if (json['schemaVersion'] != progressSchemaVersion ||
            json['playerState'] is! Map<String, dynamic>) {
          return null;
        }
        final state = PlayerState.fromJson(
          json['playerState'] as Map<String, dynamic>,
        );
        final revision = (json['revision'] as num?)?.toInt() ?? 0;
        if (revision < 0) return null;
        final fingerprint = contentFingerprint(state);
        if (json.containsKey('contentFingerprint') &&
            json['contentFingerprint'] != fingerprint) {
          return null;
        }
        return ProgressSaveSnapshot(
          state: state,
          revision: revision,
          savedAt:
              DateTime.tryParse(json['savedAt'] as String? ?? '')?.toUtc() ??
              state.lastSavedTime.toUtc(),
          contentFingerprint: fingerprint,
          isLegacyFormat: false,
        );
      }

      // Saves written before the progress envelope are the PlayerState JSON.
      final state = PlayerState.fromJson(json);
      return ProgressSaveSnapshot(
        state: state,
        revision: 0,
        savedAt: state.lastSavedTime.toUtc(),
        contentFingerprint: contentFingerprint(state),
        isLegacyFormat: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Stable identity for gameplay content. Save timestamps are excluded so an
  /// otherwise unchanged local save remains equal to its cloud ancestor.
  static String contentFingerprint(PlayerState state) {
    final content = Map<String, dynamic>.from(state.toJson())
      ..remove('lastSavedTime');
    final canonicalJson = jsonEncode(_canonicalize(content));
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort(
          (left, right) => left.key.toString().compareTo(right.key.toString()),
        );
      return <String, Object?>{
        for (final entry in entries)
          entry.key.toString(): _canonicalize(entry.value),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    return value;
  }

  Future<void> save(PlayerState state) async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_saveKey);
    final current = _decodeSnapshot(currentJson);
    if (current != null) {
      await prefs.setString(_backupKey, currentJson!);
    }
    final jsonString = jsonEncode({
      'format': progressFormat,
      'schemaVersion': progressSchemaVersion,
      'revision': (current?.revision ?? 0) + 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'contentFingerprint': contentFingerprint(state),
      'playerState': state.toJson(),
    });
    await prefs.setString(_saveKey, jsonString);
  }

  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove(_backupKey);
  }

  /// Moves the old device-wide final-battle tutorial choice into every
  /// existing save before cloud sync can treat it as account-owned progress.
  ///
  /// Accounts without a save are intentionally left empty. The unscoped
  /// legacy save is included because it may be claimed by the first account
  /// immediately after this migration runs.
  static Future<void> migrateLegacyRottenShellTutorial(
    Iterable<String> accountIds,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final completed =
        preferences.getBool(_legacyRottenShellTutorialKey) ?? false;
    if (!preferences.containsKey(_legacyRottenShellTutorialKey)) return;

    if (completed) {
      final saveServices = <SaveService>[
        SaveService(),
        ...accountIds.map((accountId) => SaveService(accountId: accountId)),
      ];
      for (final service in saveServices) {
        final state = await service.load();
        if (state == null || state.rottenShellFinalBattleTutorialCompleted) {
          continue;
        }
        await service.save(
          state.copyWith(rottenShellFinalBattleTutorialCompleted: true),
        );
      }
    }

    await preferences.remove(_legacyRottenShellTutorialKey);
  }
}
