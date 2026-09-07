import 'dart:convert';

import '../models/player_account.dart';
import 'device_guest_slot_store.dart';

enum AccountStartupFailure { unreadableProfiles, storageUnavailable }

class AccountStartupException implements Exception {
  const AccountStartupException(this.failure);
  final AccountStartupFailure failure;
}

/// Read-only preflight. Never infer that an unreadable directory is a new install.
/// Keep older names/IDs as stored rather than applying today's creation rules.
abstract final class SavedPlayerDirectory {
  static const key = 'playerAccounts';
  static const _legacyKeys = [
    'playerAccountId',
    'playerAccountDisplayName',
    'playerAccountUsername',
    'playerAccountAvatarColor',
    'playerAccountCreatedAt',
  ];

  static List<PlayerAccount> read(Map<String, Object> values) {
    try {
      final players = <PlayerAccount>[];
      if (values.containsKey(key)) {
        final decoded = jsonDecode(values[key] as String) as List;
        for (final item in decoded) {
          final player = PlayerAccount.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          _validate(player);
          if (players.any((other) => other.id == player.id)) {
            throw const FormatException('Ambiguous player');
          }
          players.add(player);
        }
      }

      if (_legacyKeys.any(values.containsKey)) {
        final legacy = PlayerAccount(
          id: values[_legacyKeys[0]] as String,
          displayName: values[_legacyKeys[1]] as String,
          username: values[_legacyKeys[2]] as String,
          avatarColorValue: values[_legacyKeys[3]] as int? ?? 0xFF5271FF,
          createdAt: DateTime.parse(values[_legacyKeys[4]] as String),
        );
        _validate(legacy);
        if (!players.any((player) => player.id == legacy.id)) {
          players.add(legacy);
        }
      }

      // Wrong-type identity metadata must not cause a partly written guest
      // directory or silently rotate a cloud identity during initialization.
      const prefix = DeviceGuestSlotStore.keyPrefix;
      for (final suffix in ['account_id', 'firebase_uid']) {
        if (values.containsKey('$prefix$suffix') &&
            values['$prefix$suffix'] is! String) {
          throw const FormatException('Unreadable device identity');
        }
      }
      final generation = values['${prefix}generation'];
      if (generation != null && (generation is! int || generation < 0)) {
        throw const FormatException('Unreadable device generation');
      }

      if (players.isEmpty &&
          values.keys.any(
            (key) =>
                key.startsWith('egg_hatchers_player_state_account_') ||
                key.contains('.account.') ||
                key == '${prefix}account_id' ||
                key == '${prefix}firebase_uid',
          )) {
        throw const FormatException('Saved player ownership is missing');
      }
      // A device-wide pre-account save is intentionally allowed: the established
      // legacy migration gives it its first guest without replacing that save.
      return players;
    } catch (_) {
      throw const AccountStartupException(
        AccountStartupFailure.unreadableProfiles,
      );
    }
  }

  static void _validate(PlayerAccount player) {
    if (player.id.trim().isEmpty ||
        player.displayName.trim().isEmpty ||
        player.username.trim().isEmpty ||
        (player.isGuest && !player.id.startsWith('guest_'))) {
      throw const FormatException('Unreadable player');
    }
  }
}
