import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'save_import_storage.dart';
import 'save_service.dart';

/// Stages a ONE-player backup recovery, never a full-account import. Bootstrap
/// owns exclusive storage access. Identity, session and the backup never change.
class ProgressRecoveryService {
  ProgressRecoveryService({SaveImportStorage? storage})
    : _storage = storage ?? PreferencesImportStorage();
  final SaveImportStorage _storage;
  static const pendingKey = 'nestarium.progress_recovery.pending.v1';
  static const archivePrefix = 'nestarium.progress_recovery.archive.';
  static String primaryKey(String? id) => id == null
      ? 'egg_hatchers_player_state'
      : 'egg_hatchers_player_state_account_$id';

  Future<bool> hasPending() async =>
      (await _storage.readAll()).containsKey(pendingKey);

  Future<void> stage(ProgressReadException review) async {
    if (review.failure != ProgressReadFailure.backupAvailable ||
        SaveService.decodeSnapshot(review.backup) == null) {
      throw StateError('No readable backup');
    }
    final values = await _storage.readAll();
    if (values.containsKey(pendingKey) ||
        values.keys.any((key) => key.startsWith('nestarium.import.'))) {
      throw StateError('Another save operation needs a restart');
    }
    final key = primaryKey(review.accountId);
    if (!deepEquals(values[key], review.primary) ||
        values['${key}_backup'] != review.backup ||
        SaveService.decodeSnapshot(values[key]) != null) {
      throw StateError('Saved copies changed; review again');
    }
    final record = jsonEncode({
      'version': 1,
      'accountId': review.accountId,
      'primary': review.primary,
      'backup': review.backup,
    });
    await _writeChecked(pendingKey, record);
  }

  /// Idempotent single-key replacement. A checked permanent archive is saved
  /// first, so cancellation/restart/write uncertainty never loses the raw pair.
  Future<void> finish({bool cancel = false}) async {
    final values = await _storage.readAll();
    final source = values[pendingKey];
    if (source == null) return;
    final raw = jsonDecode(source as String) as Map<String, dynamic>;
    if (raw['version'] != 1 ||
        raw['accountId'] != null && raw['accountId'] is! String ||
        SaveService.decodeSnapshot(raw['backup']) == null ||
        SaveService.decodeSnapshot(raw['primary']) != null) {
      throw StateError('Unreadable recovery request');
    }
    final key = primaryKey(raw['accountId'] as String?);
    final archiveKey = '$archivePrefix${sha256.convert(utf8.encode(source))}';
    final unchanged = deepEquals(values[key], raw['primary']);
    final applied =
        values[key] == raw['backup'] && values[archiveKey] == source;
    if (values['${key}_backup'] != raw['backup'] || (!unchanged && !applied)) {
      throw StateError('Saved copies changed; originals were not replaced');
    }
    if (cancel) {
      if (applied && !unchanged) {
        final original = raw['primary'];
        if (original == null) {
          await _removeChecked(key);
        } else {
          await _writeChecked(
            key,
            original is List ? List<String>.from(original) : original as Object,
          );
        }
      }
    } else {
      if (values[archiveKey] != null && values[archiveKey] != source) {
        throw StateError('Recovery archive mismatch');
      }
      await _writeChecked(archiveKey, source);
      // Recheck the exact reviewed pair immediately before replacing a value.
      final fresh = await _storage.readAll();
      if (!deepEquals(fresh[key], values[key]) ||
          fresh['${key}_backup'] != raw['backup']) {
        throw StateError('Saved copies changed');
      }
      await _writeChecked(key, raw['backup'] as String);
    }
    await _removeChecked(pendingKey);
  }

  Future<void> _writeChecked(String key, Object value) async {
    if (!await _storage.write(key, value) ||
        !deepEquals((await _storage.readAll())[key], value)) {
      throw StateError('Recovery write could not be verified');
    }
  }

  Future<void> _removeChecked(String key) async {
    if (!await _storage.remove(key) ||
        (await _storage.readAll()).containsKey(key)) {
      throw StateError('Recovery removal could not be verified');
    }
  }

  static bool deepEquals(Object? a, Object? b) =>
      a is List && b is List ? listEquals(a, b) : a == b;
}
