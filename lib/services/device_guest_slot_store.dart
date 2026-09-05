import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_account.dart';

class DeviceGuestSlot {
  const DeviceGuestSlot({
    required this.accountId,
    required this.generation,
    this.firebaseUid,
  });

  final String accountId;
  final int generation;
  final String? firebaseUid;
}

/// Device-owned identity metadata that must never move with a save export.
///
/// Only the designated guest slot may later receive an anonymous Firebase UID.
/// Legacy named profiles remain local profiles until an explicit linking flow is
/// implemented.
class DeviceGuestSlotStore {
  static const keyPrefix = 'egg_hatchers.device_guest_slot.';
  static const _accountIdKey = '${keyPrefix}account_id';
  static const _generationKey = '${keyPrefix}generation';
  static const _firebaseUidKey = '${keyPrefix}firebase_uid';

  static bool ownsKey(String key) => key.startsWith(keyPrefix);

  Future<int> currentGeneration() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_generationKey) ?? 0;
  }

  Future<DeviceGuestSlot?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final accountId = preferences.getString(_accountIdKey);
    final generation = preferences.getInt(_generationKey);
    if (accountId == null ||
        !accountId.startsWith('guest_') ||
        generation == null ||
        generation < 1) {
      return null;
    }
    return DeviceGuestSlot(
      accountId: accountId,
      generation: generation,
      firebaseUid: preferences.getString(_firebaseUidKey),
    );
  }

  /// Reconciles legacy local accounts without guessing when identity is
  /// ambiguous. Exactly one guest may become the durable device guest.
  Future<DeviceGuestSlot?> ensureForAccounts(
    Iterable<PlayerAccount> accounts,
  ) async {
    final guests = accounts.where((account) => account.isGuest).toList();
    final current = await read();
    if (current != null &&
        guests.any((account) => account.id == current.accountId)) {
      return current;
    }
    if (guests.length == 1) {
      return activate(guests.single.id);
    }
    await _clearReadableSlot();
    return null;
  }

  Future<DeviceGuestSlot> activate(String accountId) async {
    if (!accountId.startsWith('guest_')) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'A device guest account ID must start with guest_.',
      );
    }
    final preferences = await SharedPreferences.getInstance();
    final current = await read();
    if (current?.accountId == accountId) return current!;

    final slot = DeviceGuestSlot(
      accountId: accountId,
      generation: (preferences.getInt(_generationKey) ?? 0) + 1,
    );
    await preferences.setString(_accountIdKey, slot.accountId);
    await preferences.setInt(_generationKey, slot.generation);
    await preferences.remove(_firebaseUidKey);
    return slot;
  }

  Future<DeviceGuestSlot> bindFirebaseUid({
    required String accountId,
    required String firebaseUid,
  }) async {
    final uid = firebaseUid.trim();
    if (uid.isEmpty) {
      throw ArgumentError.value(firebaseUid, 'firebaseUid', 'UID is empty.');
    }
    final current = await read();
    if (current == null || current.accountId != accountId) {
      throw StateError('Only the designated device guest may bind a UID.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_firebaseUidKey, uid);
    return DeviceGuestSlot(
      accountId: current.accountId,
      generation: current.generation,
      firebaseUid: uid,
    );
  }

  /// Invalidates identity ownership when an import replaces local accounts.
  /// The monotonic generation survives the replacement as a local tombstone.
  Future<void> invalidateForAccountReplacement({
    required int previousGeneration,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final nextGeneration = previousGeneration + 1;
    final storedGeneration = preferences.getInt(_generationKey) ?? 0;
    await preferences.setInt(
      _generationKey,
      storedGeneration > nextGeneration ? storedGeneration : nextGeneration,
    );
    await preferences.remove(_accountIdKey);
    await preferences.remove(_firebaseUidKey);
  }

  Future<void> _clearReadableSlot() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accountIdKey);
    await preferences.remove(_firebaseUidKey);
    // Keep the generation counter so replacing a slot cannot reuse an older
    // identity generation after an ambiguous legacy import.
  }
}
