import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_account.dart';
import 'account_session_store.dart';
import 'account_storage.dart';
import 'device_guest_slot_store.dart';
import 'save_service.dart';
import 'saved_player_directory.dart';
import 'save_import_storage.dart';

class AccountService extends ChangeNotifier {
  AccountService({SaveImportStorage? startupStorage})
    : _startupStorage = startupStorage ?? PreferencesImportStorage();

  final SaveImportStorage _startupStorage;
  static const _accountsKey = SavedPlayerDirectory.key;

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
  Future<void>? _initializing;

  PlayerAccount? get account => _account;
  List<PlayerAccount> get accounts => List.unmodifiable(_accounts);
  bool get hasAccount => _account != null;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    return _initializing ??= _initialize().whenComplete(
      () => _initializing = null,
    );
  }

  Future<void> _initialize() async {
    try {
      // Retry must read the actual storage, not a failed attempt's cached value.
      final values = await _startupStorage.readAll();
      final players = SavedPlayerDirectory.read(values);
      final originalCount = values[_accountsKey] == null
          ? 0
          : (jsonDecode(values[_accountsKey] as String) as List).length;
      if (players.isEmpty) players.add(_createGuestAccount());
      final encoded = jsonEncode(
        players.map((player) => player.toJson()).toList(),
      );
      if (originalCount != players.length) {
        if (!await _startupStorage.write(_accountsKey, encoded)) {
          throw StateError('Player directory could not be saved');
        }
        if ((await _startupStorage.readAll())[_accountsKey] != encoded) {
          throw StateError('Player directory could not be verified');
        }
      }
      await DeviceGuestSlotStore().ensureForAccounts(players);
      await SaveService.migrateLegacyRottenShellTutorial(
        players.map((account) => account.id),
      );
      PlayerAccount? selected;
      final forceAccountPicker =
          kIsWeb && Uri.base.queryParameters['account'] == 'choose';
      if (!forceAccountPicker) {
        final activeId = readActiveAccountId();
        for (final account in players) {
          if (account.id == activeId) selected = account;
        }
        selected ??= players.length == 1 ? players.first : null;
      }
      writeActiveAccountId(selected?.id);
      _accounts = players;
      _account = selected;
      _isInitialized = true;
      notifyListeners();
    } on AccountStartupException {
      rethrow;
    } catch (_) {
      throw const AccountStartupException(
        AccountStartupFailure.storageUnavailable,
      );
    }
  }

  Future<void> createAccount({
    required String displayName,
    required String username,
    required Color avatarColor,
  }) async {
    _requireInitialized();
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
    _requireInitialized();
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
    _requireInitialized();
    _account = null;
    writeActiveAccountId(null);
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    _requireInitialized();
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
    await DeviceGuestSlotStore().ensureForAccounts(_accounts);
    await AccountStorage.deleteAccountData(id);
    notifyListeners();
  }

  bool isUsernameAvailable(String username) {
    final clean = normalizeUsername(username);
    return _accounts.every((account) => account.username != clean);
  }

  void _requireInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'Saved players must be checked before changing profiles.',
      );
    }
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
