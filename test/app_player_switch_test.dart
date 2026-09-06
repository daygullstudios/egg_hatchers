import 'dart:async';

import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/models/account_protection_state.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/screens/account_onboarding_screen.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/account_storage.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/widgets/save_import_scope.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/utils/daily_system_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/controlled_lobby_channel.dart';
import 'helpers/save_import_fixture.dart';

void main() {
  testWidgets(
    'root import freeze prevents lifecycle sync and account reload after preparation failure',
    (tester) async {
      final fixture = await _openFixture(tester, multiplePlayers: true);
      final context = tester.element(find.byType(MainGameShell));
      final stage = SaveImportScope.maybeOf(context)!.stageImport;
      // Native test stub deliberately rejects browser coordination, after the
      // actual root has paused/drained its real game and sync services.
      await expectLater(
        stage(SaveTransferService().inspectSave(importFixture())),
        throwsUnsupportedError,
      );
      final selections = fixture.sync.selections.length;
      final presence = fixture.lobby.presences.length;
      final currentCoins = fixture.game.coins;
      fixture.accounts.selectAccount(fixture.accounts.accounts.first.id);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _pumpFrames(tester);
      expect(fixture.game.loads, isEmpty);
      expect(fixture.game.coins, currentCoins);
      expect(fixture.sync.selections.length, selections);
      expect(fixture.lobby.presences.length, presence);
      expect(await SaveTransferService().hasPendingImport(), false);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('picker round trip opens the same save without socket close', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final accounts = AccountService();
    final game = GameService();
    final channels = <ControlledLobbyChannel>[];
    final lobby = OnlineLobbyService(
      channelFactory: (_) {
        final channel = ControlledLobbyChannel();
        channels.add(channel);
        return channel;
      },
    );
    await tester.runAsync(() async {
      await accounts.initialize();
      await SaveService(accountId: accounts.account!.id).save(
        PlayerState(
          coins: 7654,
          ownedAnimals: const [],
          lastSavedTime: DateTime.now(),
          lifetimeCoinsEarned: 500,
          tutorialCompleted: true,
          tutorialVersionCompleted: 999,
          lastDailyRewardPopupDismissDate: DailySystemLogic.todayKey(),
        ),
      );
    });
    final player = accounts.account!;
    await tester.pumpWidget(
      NestariumApp(
        accounts: accounts,
        game: game,
        accountProtection: AccountProtectionService(),
        onlineLobby: lobby,
      ),
    );
    await _pumpFrames(tester);
    expect(find.byType(MainGameShell), findsOneWidget);
    await tester.tap(find.text('More'));
    await _pumpFrames(tester);
    await tester.tap(find.text('Settings'));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const ValueKey('settings-panel-account')));
    await _pumpFrames(tester);
    await tester.ensureVisible(find.text('Switch Account'));
    await _pumpFrames(tester);
    await tester.tap(find.text('Switch Account'));
    await _pumpFrames(tester);
    expect(find.byType(AccountOnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Create another player'));
    await _pumpFrames(tester);
    await tester.ensureVisible(find.text('Back to players'));
    await _pumpFrames(tester);
    await tester.tap(find.text('Back to players'));
    await _pumpFrames(tester);
    await tester.ensureVisible(find.text(player.displayName));
    await _pumpFrames(tester);
    await tester.tap(find.text(player.displayName));
    await _pumpFrames(tester);
    final reopened = find.byType(MainGameShell).evaluate().isNotEmpty;
    final savedCoins = game.coins;
    await tester.pumpWidget(const SizedBox.shrink());
    for (final channel in channels) {
      channel.finish();
    }
    await _pumpFrames(tester);
    expect(tester.takeException(), isNull);
    expect(
      reopened,
      isTrue,
      reason: 'Local play must not wait for WebSocket close.',
    );
    expect(savedCoins, 7654);
    expect(accounts.account!.id, player.id);
    expect(accounts.accounts, hasLength(1));
  });

  testWidgets(
    'overlapping selections load serially and publish only the latest player',
    (tester) async {
      final fixture = await _openFixture(tester, multiplePlayers: true);
      final first = fixture.accounts.accounts.first;
      final last = fixture.accounts.accounts.last;
      final gate = Completer<void>();
      fixture.game.nextLoad = gate.future;
      fixture.lobby.presences.clear();
      fixture.sync.selections.clear();
      fixture.accounts.selectAccount(first.id);
      await _pumpFrames(tester);
      expect(fixture.game.loads, [first.id]);
      fixture.accounts.selectAccount(last.id);
      await _pumpFrames(tester);
      expect(fixture.game.loads, [first.id]);
      expect(find.byType(MainGameShell), findsNothing);
      expect(fixture.lobby.presences, isEmpty);
      expect(
        fixture.sync.selections.every((value) => value.$1 == null),
        isTrue,
      );
      gate.complete();
      await _pumpFrames(tester);
      expect(fixture.game.maxConcurrentLoads, 1);
      expect(fixture.game.loads, [first.id, last.id]);
      expect(fixture.game.coins, 2222);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(
        fixture.lobby.presences.every((value) => value.account.id == last.id),
        isTrue,
      );
      expect(fixture.lobby.presences, isNotEmpty);
      expect(fixture.sync.selections.where((value) => value.$1 != null), [
        (last.id, 'cloud-${last.id}'),
      ]);
      await tester.runAsync(() async {
        expect((await SaveService(accountId: first.id).load())!.coins, 1111);
        expect((await SaveService(accountId: last.id).load())!.coins, 2222);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'return to picker while loading never reopens the stale selection',
    (tester) async {
      final fixture = await _openFixture(tester, multiplePlayers: true);
      final gate = Completer<void>();
      fixture.game.nextLoad = gate.future;
      fixture.lobby.presences.clear();
      fixture.sync.selections.clear();
      fixture.accounts.selectAccount(fixture.accounts.accounts.first.id);
      await _pumpFrames(tester);
      fixture.accounts.chooseAnotherAccount();
      gate.complete();
      await _pumpFrames(tester);
      expect(find.byType(AccountOnboardingScreen), findsOneWidget);
      expect(find.byType(MainGameShell), findsNothing);
      expect(fixture.accounts.account, isNull);
      expect(fixture.lobby.presences, isEmpty);
      expect(
        fixture.sync.selections.every((value) => value.$1 == null),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unreadable custom eggs stay untouched and another player can open',
    (tester) async {
      final fixture = await _openFixture(tester, multiplePlayers: true);
      final first = fixture.accounts.accounts.first;
      final last = fixture.accounts.accounts.last;
      final key = AccountStorage.key('customEggs', first.id);
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(key, 7); // Wrong stored type: the local read throws.
      });
      fixture.accounts.selectAccount(first.id);
      await _pumpFrames(tester);
      expect(find.text('Couldn’t open this player'), findsOneWidget);
      expect(find.byType(MainGameShell), findsNothing);
      await tester.ensureVisible(find.text('Choose local player'));
      await tester.tap(find.text('Choose local player'));
      await _pumpFrames(tester);
      await tester.ensureVisible(find.text(last.displayName));
      await tester.tap(find.text(last.displayName));
      await _pumpFrames(tester);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(fixture.game.coins, 2222);
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(key), 7);
        expect((await SaveService(accountId: first.id).load())!.coins, 1111);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  for (final retry in [true, false]) {
    testWidgets(
      'failed load has reachable recovery at 320px and 200% text (retry=$retry)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 360);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = await _openFixture(tester);
        final id = fixture.accounts.account!.id;
        fixture.game.failNextLoad = true;
        fixture.accounts.chooseAnotherAccount();
        fixture.accounts.selectAccount(id);
        await _pumpFrames(tester);
        expect(find.text('Couldn’t open this player'), findsOneWidget);
        expect(find.byType(MainGameShell), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        for (final label in ['Try again', 'Choose local player']) {
          await tester.ensureVisible(find.text(label));
          await _pumpFrames(tester);
          expect(find.text(label).hitTestable(), findsOneWidget);
          final button = find.ancestor(
            of: find.text(label),
            matching: find.bySubtype<ButtonStyleButton>(),
          );
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        final action = find.text(retry ? 'Try again' : 'Choose local player');
        await tester.ensureVisible(action);
        await _pumpFrames(tester);
        await tester.tap(action);
        await _pumpFrames(tester);
        expect(
          find.byType(retry ? MainGameShell : AccountOnboardingScreen),
          findsOneWidget,
        );
        expect(fixture.game.coins, 1111);
        expect(fixture.accounts.accounts, hasLength(1));
        await tester.runAsync(() async {
          expect((await SaveService(accountId: id).load())!.coins, 1111);
        });
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'disposing during a load cannot continue into disposed app services',
    (tester) async {
      final fixture = await _openFixture(tester);
      final gate = Completer<void>();
      fixture.game.nextLoad = gate.future;
      fixture.accounts.chooseAnotherAccount();
      fixture.accounts.selectAccount(fixture.accounts.accounts.single.id);
      await _pumpFrames(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await _pumpFrames(tester);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<
  ({
    AccountService accounts,
    _ControlledGame game,
    _PresenceRecorder lobby,
    _SyncRecorder sync,
  })
>
_openFixture(WidgetTester tester, {bool multiplePlayers = false}) async {
  SharedPreferences.setMockInitialValues({});
  final accounts = AccountService();
  final game = _ControlledGame();
  final lobby = _PresenceRecorder();
  final sync = _SyncRecorder();
  await tester.runAsync(() async {
    await accounts.initialize();
    if (multiplePlayers) {
      await accounts.createAccount(
        displayName: 'Second',
        username: 'second',
        avatarColor: Colors.blue,
      );
    }
    for (var i = 0; i < accounts.accounts.length; i++) {
      await SaveService(accountId: accounts.accounts[i].id).save(
        PlayerState(
          coins: (i + 1) * 1111,
          ownedAnimals: const [],
          lastSavedTime: DateTime.now(),
          lifetimeCoinsEarned: 0,
          tutorialCompleted: true,
          tutorialVersionCompleted: 999,
          lastDailyRewardPopupDismissDate: DailySystemLogic.todayKey(),
        ),
      );
    }
  });
  await tester.pumpWidget(
    NestariumApp(
      accounts: accounts,
      game: game,
      accountProtection: _IdentityForSelectedPlayer(),
      onlineLobby: lobby,
      progressSync: sync,
    ),
  );
  await _pumpFrames(tester);
  expect(find.byType(MainGameShell), findsOneWidget);
  return (accounts: accounts, game: game, lobby: lobby, sync: sync);
}

class _ControlledGame extends GameService {
  Future<void>? nextLoad;
  var failNextLoad = false;
  var concurrentLoads = 0;
  var maxConcurrentLoads = 0;
  var disposed = false;
  final loads = <String>[];

  @override
  Future<void> switchAccount(
    String accountId, {
    bool migrateLegacySave = false,
  }) async {
    loads.add(accountId);
    concurrentLoads++;
    if (concurrentLoads > maxConcurrentLoads) {
      maxConcurrentLoads = concurrentLoads;
    }
    try {
      final wait = nextLoad;
      nextLoad = null;
      await wait;
      if (disposed) return;
      if (failNextLoad) {
        failNextLoad = false;
        throw StateError('controlled read failure');
      }
      await super.switchAccount(
        accountId,
        migrateLegacySave: migrateLegacySave,
      );
    } finally {
      concurrentLoads--;
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class _PresenceRecorder extends OnlineLobbyService {
  final presences = <OnlinePresenceSnapshot>[];
  @override
  void updatePresence(OnlinePresenceSnapshot presence) =>
      presences.add(presence);
}

class _SyncRecorder extends ProgressSyncService {
  final selections = <(String?, String?)>[];
  @override
  Future<void> selectAccount({
    required String? accountId,
    required String? protectedPlayerId,
    CloudProgressRepository? cloud,
    ApplyCloudProgress? applyCloud,
  }) async {
    selections.add((accountId, protectedPlayerId));
  }
}

class _IdentityForSelectedPlayer extends AccountProtectionService {
  AccountProtectionState current = const AccountProtectionState.localOnly();
  @override
  AccountProtectionState get state => current;
  @override
  bool get isInitialized => true;
  @override
  Future<void> initialize({String? accountId}) => selectAccount(accountId);
  @override
  Future<void> selectAccount(String? accountId) async {
    current = AccountProtectionState(
      status: AccountProtectionStatus.guest,
      protectedPlayerId: accountId == null ? null : 'cloud-$accountId',
    );
    notifyListeners();
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
