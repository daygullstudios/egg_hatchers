import 'dart:convert';

import '../models/progress_sync_checkpoint.dart';
import 'account_storage.dart';
import 'save_import_storage.dart';
import 'save_storage_lease.dart';

enum CheckpointStorageFailure { unavailable, changed }

class CheckpointStorageException implements Exception {
  const CheckpointStorageException(this.failure);
  final CheckpointStorageFailure failure;
}

/// Device-local proof of the last progress revision confirmed by both sides.
///
/// A checkpoint is written only after a future cloud repository confirms a
/// synchronization. It is ancestry metadata, not gameplay progress or cloud
/// authority.
class ProgressSyncCheckpointStore {
  ProgressSyncCheckpointStore({
    required this.accountId,
    SaveImportStorage? storage,
  }) : assert(accountId != ''),
       _storage =
           storage ??
           PreferencesKeyStorage({AccountStorage.key(_storageKey, accountId)});

  static const _storageKey = 'egg_hatchers.sync_checkpoint.v1';

  final String accountId;
  final SaveImportStorage _storage;
  // Coordinate store instances as well as repeated operations in one service.
  static final Map<String, Future<void>> _writes = {};
  Object? _observed;
  bool _hasObserved = false;

  String get _key => AccountStorage.key(_storageKey, accountId);

  Future<ProgressSyncCheckpoint?> read() async {
    final encoded = await _readValue();
    _observed = encoded;
    _hasObserved = true;
    if (encoded is! String) return null;
    try {
      final json = jsonDecode(encoded);
      if (json is! Map) return null;
      return ProgressSyncCheckpoint.tryFromJson(
        Map<String, dynamic>.from(json),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(ProgressSyncCheckpoint checkpoint) async {
    if (!checkpoint.isValid) {
      throw ArgumentError('Invalid progress sync checkpoint.');
    }
    await _mutate(jsonEncode(checkpoint.toJson()));
  }

  Future<void> clear() => _mutate(null);

  Future<Object?> _readValue() async {
    try {
      return (await _storage.readAll())[_key];
    } catch (_) {
      throw const CheckpointStorageException(
        CheckpointStorageFailure.unavailable,
      );
    }
  }

  Future<void> _mutate(String? encoded) {
    final work = (_writes[_key] ?? Future<void>.value()).then((_) async {
      Future<void> Function()? release;
      try {
        release = await acquireProgressWriteLease(_key);
        final before = await _readValue();
        // A prior attempt may have applied before returning false/throwing.
        // Fresh backend equality is sufficient; do not issue a duplicate write.
        if (before == encoded) {
          _observed = before;
          _hasObserved = true;
          return;
        }
        if (_hasObserved && before != _observed) {
          throw const CheckpointStorageException(
            CheckpointStorageFailure.changed,
          );
        }
        _observed = before;
        _hasObserved = true;
        final accepted = encoded == null
            ? await _storage.remove(_key)
            : await _storage.write(_key, encoded);
        if (!accepted) {
          throw const CheckpointStorageException(
            CheckpointStorageFailure.unavailable,
          );
        }
        final checked = await _readValue();
        if (checked != encoded) {
          throw CheckpointStorageException(
            checked == before
                ? CheckpointStorageFailure.unavailable
                : CheckpointStorageFailure.changed,
          );
        }
        _observed = encoded;
      } catch (error) {
        if (error is CheckpointStorageException) rethrow;
        throw const CheckpointStorageException(
          CheckpointStorageFailure.unavailable,
        );
      } finally {
        await release?.call();
      }
    });
    final settled = work.catchError((Object _) {});
    _writes[_key] = settled;
    settled.then((_) {
      if (identical(_writes[_key], settled)) _writes.remove(_key);
    });
    return work;
  }
}
