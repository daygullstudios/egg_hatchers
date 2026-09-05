import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'account_session_store.dart';
import 'device_guest_slot_store.dart';

class SaveTransferException implements Exception {
  const SaveTransferException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SaveTransferService {
  static const formatName = 'egg_hatchers_save';
  static const formatVersion = 1;
  static const _accountsKey = 'playerAccounts';

  Future<String> exportSave({String? activeAccountId}) async {
    final preferences = await SharedPreferences.getInstance();
    final values = <String, Object?>{};
    final keys = preferences.getKeys().toList()..sort();
    for (final key in keys) {
      if (DeviceGuestSlotStore.ownsKey(key)) continue;
      values[key] = _encodeValue(preferences.get(key));
    }

    return const JsonEncoder.withIndent('  ').convert({
      'format': formatName,
      'version': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'activeAccountId': activeAccountId,
      'preferences': values,
    });
  }

  Future<int> importSave(String source) async {
    final decoded = _decodeDocument(source);
    final rawPreferences = decoded['preferences'] as Map<String, dynamic>;
    final restored = <String, Object>{};
    for (final entry in rawPreferences.entries) {
      if (DeviceGuestSlotStore.ownsKey(entry.key)) continue;
      restored[entry.key] = _decodeValue(entry.key, entry.value);
    }
    _validateAccounts(restored[_accountsKey]);

    final guestSlotStore = DeviceGuestSlotStore();
    final previousGuestGeneration = await guestSlotStore.currentGeneration();
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    for (final entry in restored.entries) {
      await _writeValue(preferences, entry.key, entry.value);
    }
    await guestSlotStore.invalidateForAccountReplacement(
      previousGeneration: previousGuestGeneration,
    );

    final accountIds = _accountIds(restored[_accountsKey]);
    final requestedActiveId = decoded['activeAccountId'];
    writeActiveAccountId(
      requestedActiveId is String && accountIds.contains(requestedActiveId)
          ? requestedActiveId
          : accountIds.length == 1
          ? accountIds.single
          : null,
    );
    return accountIds.length;
  }

  Map<String, dynamic> _decodeDocument(String source) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const SaveTransferException('That file is not valid JSON.');
    }
    if (decoded is! Map) {
      throw const SaveTransferException(
        'That is not an Egg Hatchers save file.',
      );
    }
    final document = Map<String, dynamic>.from(decoded);
    if (document['format'] != formatName ||
        document['version'] != formatVersion ||
        document['preferences'] is! Map) {
      throw const SaveTransferException(
        'That file is not a supported Egg Hatchers save file.',
      );
    }
    document['preferences'] = Map<String, dynamic>.from(
      document['preferences'] as Map,
    );
    return document;
  }

  Map<String, Object?> _encodeValue(Object? value) {
    if (value is String) return {'type': 'string', 'value': value};
    if (value is bool) return {'type': 'bool', 'value': value};
    if (value is int) return {'type': 'int', 'value': value};
    if (value is double) return {'type': 'double', 'value': value};
    if (value is List<String>) return {'type': 'stringList', 'value': value};
    throw SaveTransferException(
      'The game contains an unsupported saved value (${value.runtimeType}).',
    );
  }

  Object _decodeValue(String key, dynamic encoded) {
    if (encoded is! Map) {
      throw SaveTransferException('Saved value "$key" is malformed.');
    }
    final map = Map<String, dynamic>.from(encoded);
    final value = map['value'];
    switch (map['type']) {
      case 'string':
        if (value is String) return value;
      case 'bool':
        if (value is bool) return value;
      case 'int':
        if (value is int) return value;
      case 'double':
        if (value is num) return value.toDouble();
      case 'stringList':
        if (value is List && value.every((item) => item is String)) {
          return List<String>.from(value);
        }
    }
    throw SaveTransferException('Saved value "$key" has the wrong type.');
  }

  void _validateAccounts(Object? value) {
    if (value == null) return;
    if (value is! String) {
      throw const SaveTransferException('The account list is malformed.');
    }
    try {
      final accounts = jsonDecode(value);
      if (accounts is! List) throw const FormatException();
      for (final account in accounts) {
        if (account is! Map ||
            account['id'] is! String ||
            account['displayName'] is! String ||
            account['username'] is! String ||
            account['avatarColorValue'] is! int ||
            DateTime.tryParse(account['createdAt']?.toString() ?? '') == null) {
          throw const FormatException();
        }
      }
    } catch (_) {
      throw const SaveTransferException('The account list is malformed.');
    }
  }

  Set<String> _accountIds(Object? value) {
    if (value is! String) return {};
    final accounts = jsonDecode(value) as List<dynamic>;
    return accounts.map((account) => (account as Map)['id'] as String).toSet();
  }

  Future<void> _writeValue(
    SharedPreferences preferences,
    String key,
    Object value,
  ) async {
    if (value is String) {
      await preferences.setString(key, value);
    } else if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is int) {
      await preferences.setInt(key, value);
    } else if (value is double) {
      await preferences.setDouble(key, value);
    } else if (value is List<String>) {
      await preferences.setStringList(key, value);
    }
  }
}
