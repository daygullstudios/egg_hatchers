import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_account.dart';
import 'account_session_store.dart';
import 'account_storage.dart';
import 'save_service.dart';

class AccountService extends ChangeNotifier {
  static const _idKey = 'playerAccountId';
  static const _displayNameKey = 'playerAccountDisplayName';
  static const _usernameKey = 'playerAccountUsername';
  static const _avatarColorKey = 'playerAccountAvatarColor';
  static const _createdAtKey = 'playerAccountCreatedAt';
  static const _accountsKey = 'playerAccounts';

  static const avatarColors = [
    Color(0xFF5271FF),
    Color(0xFF8B4DFF),
    Color(0xFF00A6A6),
    Color(0xFFE14B67),
    Color(0xFFF09A28),
    Color(0xFF3B9B54),
  ];

  PlayerAccount? _account;
  List<PlayerAccount> _accounts = [];
  bool _isInitialized = false;

  PlayerAccount? get account => _account;
  List<PlayerAccount> get accounts => List.unmodifiable(_accounts);
  bool get hasAccount => _account != null;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final preferences = await SharedPreferences.getInstance();
    final savedAccounts = preferences.getString(_accountsKey);
    if (savedAccounts != null) {
      try {
        _accounts = (jsonDecode(savedAccounts) as List<dynamic>)
            .map(
              (item) => PlayerAccount.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      } catch (_) {
        _accounts = [];
      }
    }
    final id = preferences.getString(_idKey);
    final displayName = preferences.getString(_displayNameKey);
    final username = preferences.getString(_usernameKey);
    final createdAt = DateTime.tryParse(
      preferences.getString(_createdAtKey) ?? '',
    );

    if (id != null &&
        displayName != null &&
        username != null &&
        createdAt != null) {
      final legacyAccount = PlayerAccount(
        id: id,
        displayName: displayName,
        username: username,
        avatarColorValue:
            preferences.getInt(_avatarColorKey) ??
            avatarColors.first.toARGB32(),
        createdAt: createdAt,
      );
      if (_accounts.every((account) => account.id != legacyAccount.id)) {
        _accounts.add(legacyAccount);
        await _saveAccounts(preferences);
      }
    }

    if (_accounts.isEmpty) {
      _accounts.add(_createGuestAccount());
      await _saveAccounts(preferences);
    }

    await SaveService.migrateLegacyRottenShellTutorial(
      _accounts.map((account) => account.id),
    );

    final forceAccountPicker =
        kIsWeb && Uri.base.queryParameters['account'] == 'choose';
    if (!forceAccountPicker) {
      final activeId = readActiveAccountId();
      for (final account in _accounts) {
        if (account.id == activeId) {
          _account = account;
          break;
        }
      }
      _account ??= _accounts.length == 1 ? _accounts.first : null;
    }
    writeActiveAccountId(_account?.id);

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> createAccount({
    required String displayName,
    required String username,
    required Color avatarColor,
  }) async {
    final cleanDisplayName = displayName.trim();
    final cleanUsername = normalizeUsername(username);
    if (!isDisplayNameValid(cleanDisplayName) ||
        !isUsernameValid(cleanUsername)) {
      throw ArgumentError('Invalid player account details.');
    }
    if (_accounts.any((account) => account.username == cleanUsername)) {
      throw ArgumentError('That username already exists on this device.');
    }

    final createdAt = DateTime.now().toUtc();
    final randomPart = math.Random.secure().nextInt(0x7FFFFFFF);
    final account = PlayerAccount(
      id: 'player_${createdAt.microsecondsSinceEpoch}_$randomPart',
      displayName: cleanDisplayName,
      username: cleanUsername,
      avatarColorValue: avatarColor.toARGB32(),
      createdAt: createdAt,
    );

    final preferences = await SharedPreferences.getInstance();
    _accounts.add(account);
    await _saveAccounts(preferences);
    _account = account;
    writeActiveAccountId(account.id);
    notifyListeners();
  }

  void selectAccount(String id) {
    PlayerAccount? selected;
    for (final account in _accounts) {
      if (account.id == id) {
        selected = account;
        break;
      }
    }
    if (selected == null) return;
    _account = selected;
    writeActiveAccountId(selected.id);
    notifyListeners();
  }

  void chooseAnotherAccount() {
    _account = null;
    writeActiveAccountId(null);
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    final index = _accounts.indexWhere((account) => account.id == id);
    if (index < 0) return;
    _accounts.removeAt(index);
    if (_account?.id == id) {
      _account = null;
      writeActiveAccountId(null);
    }
    if (_accounts.isEmpty) {
      final guest = _createGuestAccount();
      _accounts.add(guest);
      _account = guest;
      writeActiveAccountId(guest.id);
    }
    final preferences = await SharedPreferences.getInstance();
    await _saveAccounts(preferences);
    await AccountStorage.deleteAccountData(id);
    notifyListeners();
  }

  bool isUsernameAvailable(String username) {
    final clean = normalizeUsername(username);
    return _accounts.every((account) => account.username != clean);
  }

  Future<void> _saveAccounts(SharedPreferences preferences) {
    return preferences.setString(
      _accountsKey,
      jsonEncode(_accounts.map((account) => account.toJson()).toList()),
    );
  }

  PlayerAccount _createGuestAccount() {
    final createdAt = DateTime.now().toUtc();
    var randomPart = math.Random.secure().nextInt(0x7FFFFFFF);
    var username = 'guest_${randomPart.toRadixString(36)}';
    while (_accounts.any((account) => account.username == username)) {
      randomPart = math.Random.secure().nextInt(0x7FFFFFFF);
      username = 'guest_${randomPart.toRadixString(36)}';
    }
    return PlayerAccount(
      id: 'guest_${createdAt.microsecondsSinceEpoch}_$randomPart',
      displayName: 'Guest Hatcher',
      username: username,
      avatarColorValue: avatarColors.first.toARGB32(),
      createdAt: createdAt,
      isGuest: true,
    );
  }

  static String normalizeUsername(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');

  static bool isDisplayNameValid(String value) {
    final length = value.trim().length;
    return length >= 2 && length <= 20;
  }

  static bool isUsernameValid(String value) {
    return RegExp(r'^[a-z0-9_]{3,16}$').hasMatch(value);
  }
}
