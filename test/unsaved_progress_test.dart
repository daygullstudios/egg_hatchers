import 'dart:async';
import 'dart:convert';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/screens/unsaved_progress_screen.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/services/tutorial_service.dart';
import 'package:egg_hatchers/widgets/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/save_import_fixture.dart';

const _id = 'guest_write_test';
const _key = 'egg_hatchers_player_state_account_$_id';
const _backup = '${_key}_backup';
PlayerState _state(int coins) => GameData.startingPlayerState().copyWith(
  coins: coins,
  lastSavedTime: DateTime.utc(2026),
  tutorialCompleted: true,
  tutorialVersionCompleted: 999,
);
String _raw(int coins) => jsonEncode(_state(coins).toJson());
PlayerAccount _account(String id) => PlayerAccount(
  id: id,
  displayName: 'Mock player',
  username: 'mock',
  avatarColorValue: 0xFF123456,
  createdAt: DateTime.utc(2026),
  isGuest: true,
);
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final at in [1, 2]) {
    for (final behavior in ['reject', 'throw', 'apply-false', 'lie']) {
      test(
        '$behavior at write $at is not acknowledged; retry preserves progress',
        () async {
          final storage =
              _FailureStorage({
                  _key: _raw(300),
                  _backup: _raw(200),
                  'other': 'keep',
                })
                ..failureAt = at
                ..behavior = behavior;
          final saves = SaveService(accountId: _id, storage: storage);
          await saves.load();
          await expectLater(
            saves.save(_state(999)),
            throwsA(isA<ProgressWriteException>()),
          );
          if (at == 1) expect(storage.values[_key], _raw(300));
          if (at == 2) expect(storage.values[_backup], _raw(300));
          final before = Map.of(storage.values);
          await expectLater(
            saves.save(_state(1111)),
            throwsA(isA<ProgressWriteException>()),
          );
          expect(storage.values, before);
          storage.failureAt = null;
          await saves.retrySave(_state(999));
          expect((await saves.load())!.coins, 999);
          expect(
            SaveService.decodeSnapshot(storage.values[_backup])!.state.coins,
            300,
          );
          expect(storage.values['other'], 'keep');
        },
      );
    }
  }
  test(
    'stale retry refuses another valid save without changing either copy',
    () async {
      final storage = _FailureStorage({_key: _raw(300), _backup: _raw(200)})
        ..failureAt = 2;
      final saves = SaveService(accountId: _id, storage: storage);
      await saves.load();
      await expectLater(
        saves.save(_state(999)),
        throwsA(isA<ProgressWriteException>()),
      );
      storage.values[_key] = _raw(777);
      storage.failureAt = null;
      final before = Map.of(storage.values);
      await expectLater(
        saves.retrySave(_state(999)),
        throwsA(
          isA<ProgressWriteException>().having(
            (e) => e.failure,
            'failure',
            ProgressWriteFailure.changed,
          ),
        ),
      );
      expect(storage.values, before);
    },
  );
  test(
    'a loaded stale player cannot overwrite a newer primary on an ordinary save',
    () async {
      final storage = _FailureStorage({_key: _raw(300)});
      final saves = SaveService(accountId: _id, storage: storage);
      await saves.load();
      storage.values[_key] = _raw(888);
      await expectLater(
        saves.save(_state(900)),
        throwsA(isA<ProgressWriteException>()),
      );
      expect(storage.values[_key], _raw(888));
      expect(storage.calls, 0);
    },
  );
  test(
    'queued writes serialize backup rotation and revision increments',
    () async {
      final storage = _FailureStorage();
      final saves = SaveService(accountId: _id, storage: storage);
      await Future.wait([
        saves.save(_state(1)),
        saves.save(_state(2)),
        saves.save(_state(3)),
      ]);
      final current = await saves.loadSnapshot();
      expect(current!.revision, 3);
      expect(current.state.coins, 3);
      expect(
        SaveService.decodeSnapshot(storage.values[_backup])!.state.coins,
        2,
      );
    },
  );
  test(
    'storage read outage pauses a write and retry requires the loaded baseline',
    () async {
      final storage = _FailureStorage({_key: _raw(300)});
      final saves = SaveService(accountId: _id, storage: storage);
      await saves.load();
      storage.failReads = true;
      await expectLater(
        saves.save(_state(900)),
        throwsA(isA<ProgressWriteException>()),
      );
      expect(storage.calls, 0);
      storage.failReads = false;
      await saves.retrySave(_state(900));
      expect((await saves.load())!.coins, 900);
    },
  );
  test(
    'complete recovery export substitutes memory only, preserves other data and excludes identity',
    () async {
      final account = _account(_id), other = _account('guest_other');
      final storage = _FailureStorage({
        'playerAccounts': jsonEncode([account.toJson(), other.toJson()]),
        _key: _raw(300),
        'egg_hatchers_player_state_account_guest_other': _raw(222),
        'musicEnabled': false,
        'egg_hatchers.device_guest_slot.firebase_uid': 'mock-identity',
      });
      final original = Map.of(storage.values);
      final transfer = SaveTransferService(storage: storage);
      final source = await transfer.exportWithUnsavedProgress(
        account: account,
        progress: _state(999),
      );
      final preview = transfer.inspectSave(source);
      expect(preview.progress[_id]!.coins, 999);
      expect(preview.progress['guest_other']!.coins, 222);
      expect(source, isNot(contains('mock-identity')));
      expect(storage.values, original);
      expect(storage.calls, 0);
    },
  );
  test(
    'emergency snapshot retains held progress but cannot masquerade as a complete import',
    () {
      final source = SaveTransferService.emergencyProgressSnapshot(
        account: _account(_id),
        progress: _state(999),
      );
      expect(jsonDecode(source)['playerState']['coins'], 999);
      expect(
        () => SaveTransferService().inspectSave(source),
        throwsA(isA<SaveTransferException>()),
      );
    },
  );

  testWidgets(
    'failed live save freezes mutations, cloud acknowledgment, import and switching; retry resumes same memory',
    (tester) async {
      final storage = _FailureStorage({_key: _raw(300)});
      final game = GameService(
        saveFactory: (id) => SaveService(accountId: id, storage: storage),
      );
      await game.initialize(accountId: _id);
      await game.save();
      var published = 0;
      game.onProgressSaved = (_) => published++;
      storage.failureAt = storage.calls + 1;
      game.setCoins(999);
      await _frames(tester);
      expect(game.saveNeedsAttention, true);
      expect(game.coins, 999);
      expect(published, 0);
      game.setCoins(5);
      await game.save();
      expect(game.coins, 999);
      await expectLater(game.switchAccount('guest_other'), throwsStateError);
      await expectLater(game.pauseForSaveImport(), throwsStateError);
      expect(await game.replaceProgressFromCloud(_id, _state(7)), false);
      storage.failureAt = null;
      await game.retryProgressSave();
      expect(game.saveNeedsAttention, false);
      expect(game.coins, 999);
      expect(published, 1);
      expect(
        (await SaveService(accountId: _id, storage: storage).load())!.coins,
        999,
      );
      await game.suspendProgressWrites();
      game.dispose();
    },
  );
  testWidgets(
    'slow write is single-flight and latest coalesced memory wins after success',
    (tester) async {
      final storage = _FailureStorage({_key: _raw(300)});
      final game = GameService(
        saveFactory: (id) => SaveService(accountId: id, storage: storage),
      );
      await game.initialize(accountId: _id);
      await game.save();
      storage.gate = Completer<void>();
      game.setCoins(400);
      await _frames(tester);
      game.setCoins(500);
      final writes = storage.calls;
      await tester.pump(const Duration(seconds: 9));
      expect(game.saveNeedsAttention, true);
      expect(game.saveInFlight, true);
      game.retryProgressSave();
      game.setCoins(10);
      expect(storage.calls, writes);
      expect(game.coins, 500);
      storage.gate!.complete();
      await _frames(tester);
      expect(game.saveNeedsAttention, false);
      expect(
        (await SaveService(accountId: _id, storage: storage).load())!.coins,
        500,
      );
      await game.suspendProgressWrites();
      game.dispose();
    },
  );
  testWidgets(
    'root covers a pushed dialog and preserves the same player after retry',
    (tester) async {
      final accounts = AccountService();
      await accounts.initialize();
      final id = accounts.account!.id;
      final storage = _FailureStorage({
        'egg_hatchers_player_state_account_$id': _raw(300),
      });
      final game = GameService(
        saveFactory: (id) => SaveService(accountId: id, storage: storage),
      );
      await tester.pumpWidget(
        NestariumApp(
          accounts: accounts,
          game: game,
          accountProtection: AccountProtectionService(),
          onlineLobby: _OfflineLobby(),
        ),
      );
      await _frames(tester);
      expect(find.byType(MainGameShell), findsOneWidget);
      TutorialService.instance.showWelcome(isReplay: true);
      await _frames(tester);
      expect(find.byType(TutorialSpotlightOverlay), findsOneWidget);
      final context = tester.element(find.byType(MainGameShell));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('Old game dialog')),
        ),
      );
      await _frames(tester);
      storage.failureAt = storage.calls + 1;
      game.setCoins(789);
      await _frames(tester);
      expect(find.byType(UnsavedProgressScreen), findsOneWidget);
      expect(find.byType(TutorialSpotlightOverlay), findsNothing);
      expect(find.text('Old game dialog'), findsNothing);
      expect(find.byType(MainGameShell), findsNothing);
      storage.failureAt = null;
      await tester.tap(find.text('Retry saving'));
      await _frames(tester);
      expect(find.byType(UnsavedProgressScreen), findsNothing);
      expect(game.coins, 789);
      expect(accounts.account!.id, id);
      TutorialService.instance.skipTutorial();
      await _frames(tester);
      await game.suspendProgressWrites();
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(320, 360),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'recovery controls and memory fallback fit $size at 200% text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final storage = _FailureStorage({_key: _raw(300)});
        final game = GameService(
          saveFactory: (id) => SaveService(accountId: id, storage: storage),
        );
        await game.initialize(accountId: _id);
        await game.save();
        storage.failureAt = storage.calls + 1;
        game.setCoins(999);
        await _frames(tester);
        String? copied;
        final neverRead = _HangingReadStorage();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: UnsavedProgressScreen(
              game: game,
              account: _account(_id),
              onRetry: game.retryProgressSave,
              web: false,
              copy: (text) async {
                copied = text;
              },
              transfer: SaveTransferService(storage: neverRead),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Copy recovery backup'));
        await tester.tap(find.text('Copy recovery backup'));
        await tester.pump();
        await tester.ensureVisible(find.text('Copy emergency snapshot'));
        await tester.tap(find.text('Copy emergency snapshot'));
        await tester.pumpAndSettle();
        expect(jsonDecode(copied!)['playerState']['coins'], 999);
        expect(tester.takeException(), isNull);
        neverRead.gate.completeError(StateError('private storage detail'));
        await _frames(tester);
        expect(find.textContaining('private storage detail'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        game.dispose();
      },
    );
  }
}

class _FailureStorage extends ImportMemoryStorage {
  _FailureStorage([super.initial]);
  int calls = 0;
  int? failureAt;
  String behavior = 'reject';
  bool failReads = false;
  Completer<void>? gate;
  @override
  Future<Map<String, Object>> readAll() async {
    if (failReads) throw StateError('private failure');
    return super.readAll();
  }

  @override
  Future<bool> write(String key, Object value) async {
    final call = ++calls;
    await gate?.future;
    if (call == failureAt) {
      if (behavior == 'throw') throw StateError('private quota error');
      if (behavior == 'apply-false') values[key] = value;
      return behavior == 'lie';
    }
    values[key] = value;
    return true;
  }
}

class _HangingReadStorage extends ImportMemoryStorage {
  final gate = Completer<Map<String, Object>>();
  @override
  Future<Map<String, Object>> readAll() => gate.future;
}

class _OfflineLobby extends OnlineLobbyService {
  @override
  void updatePresence(OnlinePresenceSnapshot presence) {}
}
