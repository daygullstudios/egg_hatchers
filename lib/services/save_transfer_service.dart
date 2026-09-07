import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/player_account.dart';
import '../models/player_state.dart';
import 'account_session_store.dart';
import 'device_guest_slot_store.dart';
import 'save_import_storage.dart';
import 'save_import_validation.dart';
import 'saved_player_directory.dart';
import 'progress_recovery_service.dart';

class SaveTransferException implements Exception {
  const SaveTransferException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SaveImportPreview {
  SaveImportPreview._(
    this.source,
    this.exportedAt,
    List<PlayerAccount> players,
    Map<String, PlayerState> progress,
    this.hasLegacyProgress,
  ) : players = List.unmodifiable(players),
      progress = Map.unmodifiable(progress);
  final String source;
  final DateTime? exportedAt;
  final List<PlayerAccount> players;
  final Map<String, PlayerState> progress;
  final bool hasLegacyProgress;
}

enum SaveImportBootResult { none, imported, originalRestored, backupRestored }

/// Review/stage while running; replace only at bootstrap under an exclusive
/// storage lease, before game/auth services start.
class SaveTransferService {
  SaveTransferService({SaveImportStorage? storage})
    : _storage = storage ?? PreferencesImportStorage();
  final SaveImportStorage _storage;
  static const formatName = 'egg_hatchers_save';
  static const formatVersion = 1;
  static const pendingKey = 'nestarium.import.pending.v1';
  static const recoveryKey = 'nestarium.import.recovery.v1';
  static const _guestGenerationKey =
      '${DeviceGuestSlotStore.keyPrefix}generation';
  static bool _internalKey(String key) => key.startsWith('nestarium.import.');
  static bool _nonTransferable(String key) =>
      _internalKey(key) ||
      key == ProgressRecoveryService.pendingKey ||
      DeviceGuestSlotStore.ownsKey(key) ||
      key.startsWith('egg_hatchers.sync_checkpoint.');

  Future<String> exportSave({String? activeAccountId}) async {
    final all = await _storage.readAll();
    return _encodeDocument({
      for (final entry in all.entries)
        if (!_nonTransferable(entry.key)) entry.key: entry.value,
    }, activeAccountId);
  }

  /// Export stored profiles/customizations with this player's latest in-memory
  /// progress. Read-only: never flush a failing save to make a backup.
  Future<String> exportWithUnsavedProgress({
    required PlayerAccount account,
    required PlayerState progress,
  }) async {
    final all = await _storage.readAll();
    final players = SavedPlayerDirectory.read(all);
    if (!players.any((player) => player.id == account.id)) {
      throw const SaveTransferException(
        'The player directory changed. Keep an emergency snapshot instead.',
      );
    }
    final key = ProgressRecoveryService.primaryKey(account.id);
    final values = {
      for (final entry in all.entries)
        if (!_nonTransferable(entry.key)) entry.key: entry.value,
      key: jsonEncode(progress.toJson()),
    };
    final source = _encodeDocument(values, account.id);
    inspectSave(source);
    return source;
  }

  /// Always available from memory when the storage backend cannot be read.
  /// Deliberately not a normal import: that would erase omitted players/art.
  static String emergencyProgressSnapshot({
    required PlayerAccount? account,
    required PlayerState progress,
  }) => const JsonEncoder.withIndent('  ').convert({
    'format': 'nestarium_emergency_progress',
    'version': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'notice':
        'Progress snapshot only. Not a full save import. Keep original app/browser data; restoring may require support. Other players, settings, custom art and sign-in are not included.',
    'player': account?.toJson(),
    'playerState': progress.toJson(),
  });

  SaveImportPreview inspectSave(String source) {
    try {
      final document = _decodeDocument(source);
      final values = _values(document['preferences']);
      final players = SavedPlayerDirectory.read(values);
      final states = <String, PlayerState>{};
      var legacy = false;
      for (final entry in values.entries) {
        final state = validateTransferredValue(entry.key, entry.value);
        if (state == null || entry.key.endsWith('_backup')) continue;
        if (entry.key == 'egg_hatchers_player_state') {
          legacy = true;
        } else {
          const prefix = 'egg_hatchers_player_state_account_';
          if (!entry.key.startsWith(prefix)) {
            throw const FormatException('Progress key');
          }
          final id = entry.key.substring(prefix.length);
          if (!players.any((player) => player.id == id)) {
            throw const FormatException('Orphan progress');
          }
          states[id] = state;
        }
      }
      if (players.isEmpty && !legacy) throw const FormatException('Empty save');
      return SaveImportPreview._(
        source,
        DateTime.tryParse(document['exportedAt']?.toString() ?? ''),
        players,
        states,
        legacy,
      );
    } on SaveTransferException {
      rethrow;
    } catch (_) {
      throw const SaveTransferException(
        'This file contains unreadable players, progress or custom data. Nothing was imported.',
      );
    }
  }

  /// Cannot replace progress. Bootstrap revalidates the exact staged file.
  Future<void> stageImport(SaveImportPreview preview) async {
    inspectSave(preview.source);
    final values = await _storage.readAll();
    if (values.containsKey(pendingKey) ||
        values.containsKey(recoveryKey) ||
        values.containsKey(ProgressRecoveryService.pendingKey)) {
      throw const SaveTransferException(
        'A previous import needs a restart first.',
      );
    }
    await _checkedWrite(pendingKey, preview.source);
    if ((await _storage.readAll())[pendingKey] != preview.source) {
      throw const SaveTransferException(
        'Could not verify the staged file. Restart to check it.',
      );
    }
  }

  Future<bool> hasPendingImport() async {
    final all = await _storage.readAll();
    return all.containsKey(pendingKey) ||
        all.containsKey(recoveryKey) ||
        all.containsKey(ProgressRecoveryService.pendingKey);
  }

  /// Bootstrap only, under an exclusive storage lease. A retained journal
  /// restores originals first; never guess whether an interrupted import won.
  Future<SaveImportBootResult> finishPendingImport() async {
    final all = await _storage.readAll();
    if (all.containsKey(ProgressRecoveryService.pendingKey)) {
      if (all.containsKey(pendingKey) || all.containsKey(recoveryKey)) {
        throw const SaveTransferException(
          'Conflicting save operations need attention. Do not clear browser data.',
        );
      }
      await ProgressRecoveryService(storage: _storage).finish();
      return SaveImportBootResult.backupRestored;
    }
    if (all.containsKey(recoveryKey)) {
      await _restoreOriginal(all[recoveryKey]);
      return SaveImportBootResult.originalRestored;
    }
    final source = all[pendingKey];
    if (source == null) return SaveImportBootResult.none;
    if (source is! String) {
      throw const SaveTransferException(
        'The staged import is unreadable. Cancel this import to keep your local saves.',
      );
    }
    final preview = inspectSave(source);
    final document = _decodeDocument(source);
    final incoming = _values(document['preferences']);
    incoming[_guestGenerationKey] = (all[_guestGenerationKey] as int? ?? 0) + 1;
    final original = {
      for (final entry in all.entries)
        if (!_internalKey(entry.key)) entry.key: entry.value,
    };
    final journal = jsonEncode({
      'version': 1,
      'activeAccountId': readActiveAccountId(),
      'preferences': _encodedValues(original),
    });
    // Check the on-device recovery copy before the first destructive write.
    await _checkedWrite(recoveryKey, journal);
    if ((await _storage.readAll())[recoveryKey] != journal) {
      throw const SaveTransferException(
        'Could not verify the recovery copy. Original saves have not been replaced.',
      );
    }
    try {
      await _replaceValues(incoming);
      final ids = preview.players.map((player) => player.id).toSet();
      final requested = document['activeAccountId'];
      final activeId = requested is String && ids.contains(requested)
          ? requested
          : ids.length == 1
          ? ids.single
          : null;
      writeActiveAccountId(activeId);
      if (readActiveAccountId() != activeId) {
        throw StateError('Session write failed');
      }
      await _checkedRemove(pendingKey);
    } catch (_) {
      await _restoreOriginal(journal);
      return SaveImportBootResult.originalRestored;
    }
    // Commit last, outside rollback handling: an ambiguous removal must never
    // start destructive recovery without a durable journal. On restart an
    // existing journal restores originals; an absent one means commit won.
    await _checkedRemove(recoveryKey);
    return SaveImportBootResult.imported;
  }

  Future<void> cancelPendingImport() async {
    final values = await _storage.readAll();
    if (values.containsKey(ProgressRecoveryService.pendingKey)) {
      if (values.containsKey(pendingKey) || values.containsKey(recoveryKey)) {
        throw const SaveTransferException(
          'Conflicting save operations need attention. Do not clear browser data.',
        );
      }
      await ProgressRecoveryService(storage: _storage).finish(cancel: true);
      return;
    }
    if (values.containsKey(recoveryKey)) {
      await _restoreOriginal(values[recoveryKey]);
    } else {
      await _checkedRemove(pendingKey);
    }
  }

  Future<void> _restoreOriginal(Object? raw) async {
    try {
      final journal = jsonDecode(raw as String) as Map<String, dynamic>;
      if (journal['version'] != 1) throw const FormatException();
      final original = _values(journal['preferences'], includeInternal: true);
      if (original.keys.any(_internalKey)) throw const FormatException();
      await _replaceValues(original);
      final activeId = journal['activeAccountId'] as String?;
      writeActiveAccountId(activeId);
      if (readActiveAccountId() != activeId) {
        throw StateError('Session recovery failed');
      }
      await _checkedRemove(pendingKey);
      await _checkedRemove(recoveryKey);
    } catch (_) {
      throw const SaveTransferException(
        'Recovery could not finish. Do not clear browser data; free some storage and retry.',
      );
    }
  }

  Future<void> _replaceValues(Map<String, Object> values) async {
    final current = await _storage.readAll();
    for (final key in current.keys) {
      if (!_internalKey(key) && !values.containsKey(key)) {
        await _checkedRemove(key);
      }
    }
    for (final entry in values.entries) {
      await _checkedWrite(entry.key, entry.value);
    }
    final actual = await _storage.readAll();
    final visible = {
      for (final entry in actual.entries)
        if (!_internalKey(entry.key)) entry.key: entry.value,
    };
    Map<String, String> comparable(Map<String, Object> data) =>
        _encodedValues(data).map((k, v) => MapEntry(k, jsonEncode(v)));
    if (!mapEquals(comparable(visible), comparable(values))) {
      throw const SaveTransferException('Save verification failed.');
    }
  }

  Future<void> _checkedWrite(String key, Object value) async {
    if (!await _storage.write(key, value)) {
      throw const SaveTransferException(
        'Device storage did not accept a save write.',
      );
    }
  }

  Future<void> _checkedRemove(String key) async {
    if (!await _storage.remove(key) ||
        (await _storage.readAll()).containsKey(key)) {
      throw const SaveTransferException(
        'Device storage did not finish a save change.',
      );
    }
  }

  Map<String, dynamic> _decodeDocument(String source) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const SaveTransferException('That file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != formatName ||
        decoded['version'] != formatVersion ||
        decoded['preferences'] is! Map) {
      throw const SaveTransferException(
        'That file is not a supported Nestarium save file.',
      );
    }
    return decoded;
  }

  Map<String, Object> _values(Object? raw, {bool includeInternal = false}) {
    final result = <String, Object>{};
    for (final entry in (raw as Map<String, dynamic>).entries) {
      if (!includeInternal && _nonTransferable(entry.key)) continue;
      final map = entry.value as Map<String, dynamic>;
      final value = map['value'];
      switch (map['type']) {
        case 'string' when value is String:
          result[entry.key] = value;
        case 'bool' when value is bool:
          result[entry.key] = value;
        case 'int' when value is int:
          result[entry.key] = value;
        case 'double' when value is num && value.isFinite:
          result[entry.key] = value.toDouble();
        case 'stringList' when value is List && value.every((v) => v is String):
          result[entry.key] = List<String>.from(value);
        default:
          throw const FormatException('Saved value type');
      }
    }
    return result;
  }

  Map<String, Object?> _encodedValues(Map<String, Object> values) => {
    for (final entry in values.entries)
      entry.key: {
        'type': switch (entry.value) {
          String() => 'string',
          bool() => 'bool',
          int() => 'int',
          double() => 'double',
          List<String>() => 'stringList',
          _ => throw const SaveTransferException('Unsupported saved value.'),
        },
        'value': entry.value,
      },
  };
  String _encodeDocument(Map<String, Object> values, String? activeId) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': formatName,
        'version': formatVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'activeAccountId': activeId,
        'preferences': _encodedValues(values),
      });
}
