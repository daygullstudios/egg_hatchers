import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_sync_checkpoint.dart';
import 'account_storage.dart';

/// Device-local proof of the last progress revision confirmed by both sides.
///
/// A checkpoint is written only after a future cloud repository confirms a
/// synchronization. It is ancestry metadata, not gameplay progress or cloud
/// authority.
class ProgressSyncCheckpointStore {
  ProgressSyncCheckpointStore({required this.accountId})
    : assert(accountId != '');

  static const _storageKey = 'egg_hatchers.sync_checkpoint.v1';

  final String accountId;

  String get _key => AccountStorage.key(_storageKey, accountId);

  Future<ProgressSyncCheckpoint?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key);
    if (encoded == null) return null;
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
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(checkpoint.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
