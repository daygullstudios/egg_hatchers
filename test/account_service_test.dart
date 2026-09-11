import 'dart:convert';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/saved_player_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/save_import_fixture.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('new players enter immediately with a device guest account', () async {
    final accounts = AccountService();
    await accounts.initialize();
    expect(accounts.isInitialized, isTrue);
    expect(accounts.hasAccount, isTrue);
    expect(accounts.account!.isGuest, isTrue);
    expect(accounts.account!.displayName, 'Guest Hatcher');
    expect(accounts.account!.identityLabel, 'Guest · saved on this device');
    expect(
      (await DeviceGuestSlotStore().read())?.accountId,
      accounts.account!.id,
    );

    final restored = AccountService();
    await restored.initialize();
    expect(restored.account!.id, accounts.account!.id);
    expect(restored.account!.isGuest, isTrue);
  });

  test(
    'deleting the only guest immediately creates a fresh guest slot',
    () async {
      final accounts = AccountService();
      await accounts.initialize();
      final originalId = accounts.account!.id;
      final slots = DeviceGuestSlotStore();
      await slots.bindFirebaseUid(
        accountId: originalId,
        firebaseUid: 'old-firebase-user',
      );

      await accounts.deleteAccount(originalId);

      expect(accounts.hasAccount, isTrue);
      expect(accounts.accounts, hasLength(1));
      expect(accounts.account!.isGuest, isTrue);
      expect(accounts.account!.id, isNot(originalId));
      final replacementSlot = await slots.read();
      expect(replacementSlot?.accountId, accounts.account!.id);
      expect(replacementSlot?.generation, 2);
      expect(replacementSlot?.firebaseUid, isNull);
    },
  );

  test('automatic guest can safely claim a pre-account legacy save', () async {
    await SaveService().save(
      GameData.startingPlayerState().copyWith(coins: 4321),
    );
    final accounts = AccountService();
    await accounts.initialize();
    final game = GameService();

    await game.initialize(
      accountId: accounts.account!.id,
      migrateLegacySave: true,
    );

    expect(accounts.account!.isGuest, isTrue);
    expect(game.coins, 4321);
    game.dispose();
  });

  test(
    'legacy device tutorial choice migrates into existing account saves',
    () async {
      final accounts = AccountService();
      await accounts.initialize();
      final accountId = accounts.account!.id;
      await SaveService(
        accountId: accountId,
      ).save(GameData.startingPlayerState().copyWith(coins: 987));
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(
        'rottenShellFinalBattleTutorialCompleted',
        true,
      );

      final migratedAccounts = AccountService();
      await migratedAccounts.initialize();
      final migrated = await SaveService(accountId: accountId).load();

      expect(migrated!.coins, 987);
      expect(migrated.rottenShellFinalBattleTutorialCompleted, isTrue);
      expect(
        preferences.containsKey('rottenShellFinalBattleTutorialCompleted'),
        isFalse,
      );
    },
  );

  test('created accounts persist and reload', () async {
    final accounts = AccountService();
    await accounts.initialize();
    await accounts.createAccount(
      displayName: 'Puzzle Fox',
      username: 'Puzzle_Fox',
      avatarColor: const Color(0xFF8B4DFF),
    );

    expect(accounts.account!.displayName, 'Puzzle Fox');
    expect(accounts.account!.username, 'puzzle_fox');

    final restored = AccountService();
    await restored.initialize();
    expect(restored.account!.id, accounts.account!.id);
    expect(
      restored.account!.avatarColorValue,
      const Color(0xFF8B4DFF).toARGB32(),
    );
  });

  test('account validation rejects unsafe usernames', () {
    expect(AccountService.isUsernameValid('player_one'), isTrue);
    expect(AccountService.isUsernameValid('no spaces'), isFalse);
    expect(AccountService.isUsernameValid('ab'), isFalse);
    expect(AccountService.normalizeUsername(' Egg Hero! '), 'egghero');
  });

  test('multiple local profiles can be selected independently', () async {
    final accounts = AccountService();
    await accounts.initialize();
    await accounts.createAccount(
      displayName: 'First Player',
      username: 'first_player',
      avatarColor: AccountService.avatarColors.first,
    );
    final firstId = accounts.account!.id;
    accounts.chooseAnotherAccount();
    await accounts.createAccount(
      displayName: 'Second Player',
      username: 'second_player',
      avatarColor: AccountService.avatarColors.last,
    );

    expect(accounts.accounts, hasLength(3));
    accounts.selectAccount(firstId);
    expect(accounts.account!.username, 'first_player');
  });

  test('duplicate usernames on one device are rejected', () async {
    final accounts = AccountService();
    await accounts.initialize();
    await accounts.createAccount(
      displayName: 'First Player',
      username: 'same_name',
      avatarColor: AccountService.avatarColors.first,
    );

    expect(
      () => accounts.createAccount(
        displayName: 'Second Player',
        username: 'same_name',
        avatarColor: AccountService.avatarColors.last,
      ),
      throwsArgumentError,
    );
  });

  test('failed profile creation does not publish a phantom player', () async {
    final original = _storedPlayer('guest_original', isGuest: true);
    final storage = _RejectDirectoryWrites({
      SavedPlayerDirectory.key: jsonEncode([original.toJson()]),
    });
    final accounts = AccountService(startupStorage: storage);
    await accounts.initialize();
    storage.rejectWrites = true;

    await expectLater(
      accounts.createAccount(
        displayName: 'Unsaved Player',
        username: 'unsaved_player',
        avatarColor: AccountService.avatarColors.last,
      ),
      throwsStateError,
    );

    expect(accounts.accounts.map((account) => account.id), [original.id]);
    expect(accounts.account?.id, original.id);
  });

  test('failed profile removal keeps the existing player directory', () async {
    final first = _storedPlayer('guest_first', isGuest: true);
    final second = _storedPlayer('player_second');
    final storage = _RejectDirectoryWrites({
      SavedPlayerDirectory.key: jsonEncode([first.toJson(), second.toJson()]),
    });
    final accounts = AccountService(startupStorage: storage);
    await accounts.initialize();
    accounts.selectAccount(second.id);
    storage.rejectWrites = true;
    var progressDeleted = false;

    await expectLater(
      accounts.deleteAccount(
        second.id,
        deleteProgress: () async => progressDeleted = true,
      ),
      throwsStateError,
    );

    expect(accounts.accounts.map((account) => account.id), [
      first.id,
      second.id,
    ]);
    expect(accounts.account?.id, second.id);
    expect(progressDeleted, isFalse);
  });

  test(
    'profile removal deletes progress only after directory commit',
    () async {
      final first = _storedPlayer('guest_first', isGuest: true);
      final second = _storedPlayer('player_second');
      final storage = ImportMemoryStorage({
        SavedPlayerDirectory.key: jsonEncode([first.toJson(), second.toJson()]),
      });
      final accounts = AccountService(startupStorage: storage);
      await accounts.initialize();
      accounts.selectAccount(second.id);
      final events = <String>[];
      accounts.addListener(() => events.add('published'));

      await accounts.deleteAccount(
        second.id,
        deleteProgress: () async {
          final saved =
              jsonDecode(storage.values[SavedPlayerDirectory.key]! as String)
                  as List<dynamic>;
          expect(saved.single['id'], first.id);
          events.add('progress');
        },
      );

      expect(events, ['progress', 'published']);
      expect(accounts.accounts.map((account) => account.id), [first.id]);
    },
  );

  test('account save slots preserve progress independently', () async {
    final game = GameService();
    await game.initialize(accountId: 'first');
    game.setCoins(9999);
    await game.save();

    await game.switchAccount('second');
    expect(game.coins, 250);
    game.setCoins(777);
    await game.save();

    await game.switchAccount('first');
    expect(game.coins, 9999);
    await game.deleteAccountSave('first');
    await game.switchAccount('second');
    expect(game.coins, 777);
    game.dispose();
  });

  test('deleting one profile leaves other profiles available', () async {
    final accounts = AccountService();
    await accounts.initialize();
    await accounts.createAccount(
      displayName: 'First Player',
      username: 'first_player',
      avatarColor: AccountService.avatarColors.first,
    );
    final firstId = accounts.account!.id;
    await accounts.createAccount(
      displayName: 'Second Player',
      username: 'second_player',
      avatarColor: AccountService.avatarColors.last,
    );

    await accounts.deleteAccount(firstId);
    expect(accounts.accounts, hasLength(2));
    expect(
      accounts.accounts.any((account) => account.username == 'second_player'),
      isTrue,
    );
    expect(accounts.accounts.any((account) => account.isGuest), isTrue);
  });
}

PlayerAccount _storedPlayer(String id, {bool isGuest = false}) => PlayerAccount(
  id: id,
  displayName: isGuest ? 'Guest Hatcher' : 'Saved Player',
  username: id,
  avatarColorValue: AccountService.avatarColors.first.toARGB32(),
  createdAt: DateTime.utc(2026, 9, 10),
  isGuest: isGuest,
);

final class _RejectDirectoryWrites extends ImportMemoryStorage {
  _RejectDirectoryWrites(super.initial);

  bool rejectWrites = false;

  @override
  Future<bool> write(String key, Object value) async {
    if (rejectWrites && key == SavedPlayerDirectory.key) return false;
    return super.write(key, value);
  }
}
