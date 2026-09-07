import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_state.dart';
import 'save_import_storage.dart';
import 'progress_payload_validation.dart';

enum ProgressReadFailure { unreadable, backupAvailable, storageUnavailable }

class ProgressReadException implements Exception {
  const ProgressReadException({
    required this.failure,
    required this.accountId,
    this.primary,
    this.backup,
    this.backupSnapshot,
  });
  final ProgressReadFailure failure;
  final String? accountId;
  final Object? primary, backup;
  final ProgressSaveSnapshot? backupSnapshot;
}

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
  SaveService({this.accountId, SaveImportStorage? storage})
    : _storage =
          storage ??
          PreferencesProgressStorage(
            accountId == null
                ? _legacySaveKey
                : '${_legacySaveKey}_account_$accountId',
          );
  final SaveImportStorage _storage;

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
    return _checkPair(await _readPair());
  }

  Future<Map<String, Object>> _readPair() async {
    try {
      return await _storage.readAll();
    } catch (_) {
      throw ProgressReadException(
        failure: ProgressReadFailure.storageUnavailable,
        accountId: accountId,
      );
    }
  }

  ProgressSaveSnapshot? _checkPair(Map<String, Object> values) {
    final primary = values[_saveKey], backup = values[_backupKey];
    if (primary == null && backup == null) return null;
    final snapshot = decodeSnapshot(primary);
    if (snapshot != null) return snapshot;
    final backupSnapshot = decodeSnapshot(backup);
    throw ProgressReadException(
      failure: backupSnapshot == null
          ? ProgressReadFailure.unreadable
          : ProgressReadFailure.backupAvailable,
      accountId: accountId,
      primary: primary,
      backup: backup,
      backupSnapshot: backupSnapshot,
    );
  }

  static ProgressSaveSnapshot? decodeSnapshot(Object? jsonString) {
    if (jsonString is! String) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      if (json.containsKey('format')) {
        if (json['format'] != progressFormat ||
            json['schemaVersion'] != progressSchemaVersion ||
            json['revision'] is! int ||
            (json['revision'] as int) < 0 ||
            (json.containsKey('savedAt') &&
                (json['savedAt'] is! String ||
                    DateTime.tryParse(json['savedAt'] as String) == null)) ||
            json['playerState'] is! Map<String, dynamic>) {
          return null;
        }
        final state = parseProgressPayload(
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
      final state = parseProgressPayload(json);
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

  Future<void> save(PlayerState state) => _write(state);

  Future<void> saveForTransfer(PlayerState state) =>
      _write(state, verify: true);

  Future<void> _write(PlayerState state, {bool verify = false}) async {
    // Never let an autosave, migration, or cloud callback overwrite unreadable
    // progress by treating it as an empty slot. Recovery is a separate action.
    final prefs = await SharedPreferences.getInstance();
    final values = await _readPair();
    final current = _checkPair(values);
    final currentJson = values[_saveKey] as String?;
    if (current != null) {
      final accepted = await prefs.setString(_backupKey, currentJson!);
      if (verify && !accepted) throw StateError('Backup write rejected');
    }
    final jsonString = jsonEncode({
      'format': progressFormat,
      'schemaVersion': progressSchemaVersion,
      'revision': (current?.revision ?? 0) + 1,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'contentFingerprint': contentFingerprint(state),
      'playerState': state.toJson(),
    });
    final accepted = await prefs.setString(_saveKey, jsonString);
    if (verify) {
      await prefs.reload();
      if (!accepted || prefs.getString(_saveKey) != jsonString) {
        throw StateError('Final local save could not be verified');
      }
    }
  }

  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove(_backupKey);
  }

  static Future<PlayerState?> applyLegacyTutorialChoice(
    PlayerState? state,
  ) async {
    if (state == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_legacyRottenShellTutorialKey) == true
        ? state.copyWith(rottenShellFinalBattleTutorialCompleted: true)
        : state;
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
      final states = <PlayerState?>[];
      try {
        // Preflight all reads before changing any save or consuming the flag.
        for (final service in saveServices) {
          states.add(await service.load());
        }
      } on ProgressReadException {
        return;
      }
      for (var i = 0; i < saveServices.length; i++) {
        final service = saveServices[i], state = states[i];
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
