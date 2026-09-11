import 'dart:async';

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
  static Future<void>? _activeMutation;

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
  ) => _serialize(() async {
    final guests = accounts.where((account) => account.isGuest).toList();
    final current = await read();
    if (current != null &&
        guests.any((account) => account.id == current.accountId)) {
      return current;
    }
    if (guests.length == 1) {
      return _activate(guests.single.id);
    }
    await _clearReadableSlot();
    return null;
  });

  Future<DeviceGuestSlot> activate(String accountId) =>
      _serialize(() => _activate(accountId));

  Future<DeviceGuestSlot> _activate(String accountId) async {
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
    if (!await preferences.remove(_firebaseUidKey) ||
        !await preferences.setInt(_generationKey, slot.generation) ||
        !await preferences.setString(_accountIdKey, slot.accountId)) {
      throw StateError('Device guest identity could not be saved');
    }
    final verified = await read();
    if (verified?.accountId != slot.accountId ||
        verified?.generation != slot.generation ||
        verified?.firebaseUid != null) {
      throw StateError('Device guest identity could not be verified');
    }
    return verified!;
  }

  Future<DeviceGuestSlot> bindFirebaseUid({
    required String accountId,
    required String firebaseUid,
    int? expectedGeneration,
    bool Function()? stillCurrent,
  }) => _serialize(() async {
    final uid = firebaseUid.trim();
    if (uid.isEmpty) {
      throw ArgumentError.value(firebaseUid, 'firebaseUid', 'UID is empty.');
    }
    final current = await read();
    if (current == null || current.accountId != accountId) {
      throw StateError('Only the designated device guest may bind a UID.');
    }
    final preferences = await SharedPreferences.getInstance();
    if (expectedGeneration != null &&
            preferences.getInt(_generationKey) != expectedGeneration ||
        preferences.getString(_accountIdKey) != accountId ||
        stillCurrent != null && !stillCurrent()) {
      throw StateError('Device guest changed before identity binding');
    }
    if (!await preferences.setString(_firebaseUidKey, uid)) {
      throw StateError('Device identity could not be saved');
    }
    final verified = await read();
    if (verified?.accountId != current.accountId ||
        verified?.generation != current.generation ||
        verified?.firebaseUid != uid ||
        stillCurrent != null && !stillCurrent()) {
      if (verified?.accountId == current.accountId &&
          verified?.generation == current.generation &&
          verified?.firebaseUid == uid) {
        await preferences.remove(_firebaseUidKey);
      }
      throw StateError('Device identity could not be verified');
    }
    return verified!;
  });

  /// Invalidates identity ownership when an import replaces local accounts.
  /// The monotonic generation survives the replacement as a local tombstone.
  Future<void> invalidateForAccountReplacement({
    required int previousGeneration,
  }) => _serialize(() async {
    final preferences = await SharedPreferences.getInstance();
    final nextGeneration = previousGeneration + 1;
    final storedGeneration = preferences.getInt(_generationKey) ?? 0;
    final targetGeneration = storedGeneration > nextGeneration
        ? storedGeneration
        : nextGeneration;
    if (!await preferences.remove(_firebaseUidKey) ||
        !await preferences.remove(_accountIdKey) ||
        !await preferences.setInt(_generationKey, targetGeneration)) {
      throw StateError('Device guest identity could not be invalidated');
    }
    if (await read() != null ||
        preferences.getInt(_generationKey) != targetGeneration) {
      throw StateError('Device guest invalidation could not be verified');
    }
  });

  Future<void> _clearReadableSlot() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(_firebaseUidKey) ||
        !await preferences.remove(_accountIdKey) ||
        await read() != null) {
      throw StateError('Device guest identity could not be cleared');
    }
    // Keep the generation counter so replacing a slot cannot reuse an older
    // identity generation after an ambiguous legacy import.
  }

  static Future<T> _serialize<T>(Future<T> Function() operation) async {
    while (_activeMutation != null) {
      await _activeMutation;
    }
    final released = Completer<void>();
    _activeMutation = released.future;
    try {
      return await operation();
    } finally {
      if (identical(_activeMutation, released.future)) {
        _activeMutation = null;
      }
      released.complete();
    }
  }
}
