import 'dart:async';
import 'dart:convert';

import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/account_session_store.dart';
import 'package:egg_hatchers/services/device_guest_slot_store.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/saved_player_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object> player({String id = 'old_player'}) => {
  'id': id,
  'displayName': 'Older player',
  'username': 'Older.Username',
  'avatarColorValue': 0xFF5271FF,
  'createdAt': '2020-01-01T00:00:00Z',
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    writeActiveAccountId('original-session');
  });
  for (final bad in <Object>[
    '{unfinished',
    42,
    true,
    ['not-a-json-directory'],
    '{}',
    'null',
    '[null]',
    '[{}]',
    jsonEncode([player(), player()]),
    jsonEncode([
      player(),
      {...player(id: 'second'), 'createdAt': 'invalid'},
    ]),
    jsonEncode([
      {...player(), 'id': ' '},
    ]),
    jsonEncode([
      {...player(), 'isGuest': true},
    ]),
  ]) {
    test(
      'unreadable directory ${bad.runtimeType} ${bad.toString().length} preserves every value',
      () async {
        final original = <String, Object>{
          'playerAccounts': bad,
          'egg_hatchers_player_state_account_old_player': 'untouched progress',
          'egg_hatchers_player_state': 'untouched pre-account progress',
          'rottenShellFinalBattleTutorialCompleted': true,
          '${DeviceGuestSlotStore.keyPrefix}account_id': 'guest_original',
          '${DeviceGuestSlotStore.keyPrefix}firebase_uid': 'mock-identity',
          '${DeviceGuestSlotStore.keyPrefix}generation': 7,
          'customEggs.account.old_player': 'untouched artwork',
        };
        SharedPreferences.setMockInitialValues(original);
        final accounts = AccountService();
        var notifications = 0;
        accounts.addListener(() => notifications++);
        for (var attempt = 0; attempt < 2; attempt++) {
          await expectLater(
            accounts.initialize(),
            throwsA(
              isA<AccountStartupException>().having(
                (e) => e.failure,
                'failure',
                AccountStartupFailure.unreadableProfiles,
              ),
            ),
          );
          expect(accounts.isInitialized, false);
          expect(accounts.accounts, isEmpty);
          expect(accounts.account, isNull);
          expect(await PreferencesImportStorage().readAll(), original);
          expect(readActiveAccountId(), 'original-session');
        }
        expect(notifications, 0);
        expect(accounts.chooseAnotherAccount, throwsStateError);
        await expectLater(
          accounts.createAccount(
            displayName: 'New',
            username: 'new',
            avatarColor: AccountService.avatarColors.first,
          ),
          throwsStateError,
        );
        expect(await PreferencesImportStorage().readAll(), original);
        accounts.dispose();
      },
    );
  }

  for (final values in <Map<String, Object>>[
    {'playerAccountId': 'old_player'},
    {'playerAccountAvatarColor': 1},
    {
      'playerAccounts': '[]',
      'egg_hatchers_player_state_account_old_player_backup': 'original',
    },
    {'customEggs.account.old_player': 'original'},
    {'${DeviceGuestSlotStore.keyPrefix}firebase_uid': 'mock-identity'},
    {'${DeviceGuestSlotStore.keyPrefix}generation': '7'},
  ]) {
    test(
      'incomplete ownership or identity blocks a new guest: ${values.keys.first}',
      () async {
        SharedPreferences.setMockInitialValues(values);
        final accounts = AccountService();
        await expectLater(
          accounts.initialize(),
          throwsA(isA<AccountStartupException>()),
        );
        expect(await PreferencesImportStorage().readAll(), values);
        expect(readActiveAccountId(), 'original-session');
        accounts.dispose();
      },
    );
  }

  test(
    'valid legacy profile migrates once and keeps original metadata',
    () async {
      final original = <String, Object>{
        'playerAccountId': 'old_player',
        'playerAccountDisplayName': 'Older player',
        'playerAccountUsername': 'Older.Username',
        'playerAccountCreatedAt': '2020-01-01T00:00:00Z',
      };
      SharedPreferences.setMockInitialValues(original);
      final accounts = AccountService();
      await accounts.initialize();
      expect(accounts.account!.id, 'old_player');
      expect(accounts.account!.username, 'Older.Username');
      expect(accounts.account!.avatarColorValue, 0xFF5271FF);
      final stored = await PreferencesImportStorage().readAll();
      for (final entry in original.entries) {
        expect(stored[entry.key], entry.value);
      }
      final next = AccountService();
      await next.initialize();
      expect(next.accounts, hasLength(1));
      expect(await PreferencesImportStorage().readAll(), stored);
      accounts.dispose();
      next.dispose();
    },
  );

  test('valid directory retains formatting and unknown fields', () async {
    final encoded = const JsonEncoder.withIndent('  ').convert([
      {...player(), 'futureField': 'preserve'},
    ]);
    SharedPreferences.setMockInitialValues({'playerAccounts': encoded});
    final accounts = AccountService();
    await accounts.initialize();
    expect(
      (await PreferencesImportStorage().readAll())['playerAccounts'],
      encoded,
    );
    accounts.dispose();
  });

  test(
    'retry reads restored metadata rather than caching the failed parse',
    () async {
      SharedPreferences.setMockInitialValues({'playerAccounts': '{broken'});
      final accounts = AccountService();
      await expectLater(
        accounts.initialize(),
        throwsA(isA<AccountStartupException>()),
      );
      // Simulates a separately recovered mock directory, not an automatic repair.
      await (await SharedPreferences.getInstance()).setString(
        'playerAccounts',
        jsonEncode([player()]),
      );
      await accounts.initialize();
      expect(accounts.account!.id, 'old_player');
      expect(accounts.isInitialized, true);
      accounts.dispose();
    },
  );

  test(
    'read outage is not an empty directory, and overlapping retries coalesce',
    () async {
      final storage = _ControlledStorage()..failRead = true;
      final accounts = AccountService(startupStorage: storage);
      await expectLater(
        accounts.initialize(),
        throwsA(
          isA<AccountStartupException>().having(
            (e) => e.failure,
            'failure',
            AccountStartupFailure.storageUnavailable,
          ),
        ),
      );
      expect(storage.writes, 0);
      expect(readActiveAccountId(), 'original-session');
      storage.failRead = false;
      final gate = Completer<void>();
      storage.gate = gate.future;
      final a = accounts.initialize(), b = accounts.initialize();
      expect(identical(a, b), true);
      gate.complete();
      await Future.wait([a, b]);
      expect(accounts.accounts, hasLength(1));
      expect(storage.writes, 1);
      accounts.dispose();
    },
  );

  for (final falseResult in [true, false]) {
    test(
      'failed/unverified first directory write cannot publish a guest ($falseResult)',
      () async {
        final storage = _ControlledStorage()
          ..rejectWrite = falseResult
          ..ignoreWrite = !falseResult;
        final accounts = AccountService(startupStorage: storage);
        await expectLater(
          accounts.initialize(),
          throwsA(isA<AccountStartupException>()),
        );
        expect(accounts.isInitialized, false);
        expect(accounts.account, isNull);
        expect(readActiveAccountId(), 'original-session');
        expect(await PreferencesImportStorage().readAll(), isEmpty);
        storage.rejectWrite = false;
        storage.ignoreWrite = false;
        await accounts.initialize();
        expect(accounts.accounts, hasLength(1));
        accounts.dispose();
      },
    );
  }
}

class _ControlledStorage extends PreferencesImportStorage {
  bool failRead = false, rejectWrite = false, ignoreWrite = false;
  int writes = 0;
  Future<void>? gate;
  @override
  Future<Map<String, Object>> readAll() async {
    await gate;
    if (failRead) throw StateError('private platform error');
    return super.readAll();
  }

  @override
  Future<bool> write(String key, Object value) async {
    writes++;
    if (rejectWrite) return false;
    if (ignoreWrite) return true;
    return super.write(key, value);
  }
}
