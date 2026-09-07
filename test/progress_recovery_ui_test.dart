import 'dart:convert';
import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/screens/account_onboarding_screen.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/screens/saved_player_recovery_screen.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/account_session_store.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/progress_recovery_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/widgets/local_backup_review_dialog.dart';
import 'package:egg_hatchers/widgets/save_import_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/save_import_fixture.dart';

const _id = 'mock-recovery';
final _key = ProgressRecoveryService.primaryKey(_id);
String _good() => jsonEncode(
  GameData.startingPlayerState()
      .copyWith(
        coins: 7654,
        tutorialCompleted: true,
        tutorialVersionCompleted: 999,
        lastSavedTime: DateTime.utc(2026),
      )
      .toJson(),
);
ProgressReadException _review() => ProgressReadException(
  failure: ProgressReadFailure.backupAvailable,
  accountId: _id,
  primary: '{damaged',
  backup: _good(),
  backupSnapshot: SaveService.decodeSnapshot(_good()),
);
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    writeActiveAccountId(null);
  });
  for (final config in [
    (320.0, 640.0, 1.0),
    (390.0, 844.0, 1.0),
    (430.0, 932.0, 1.0),
    (1440.0, 900.0, 1.0),
    (320.0, 360.0, 2.0),
  ]) {
    testWidgets(
      'backup preview and confirmation fit $config without auto-restore',
      (tester) async {
        tester.view.physicalSize = Size(config.$1, config.$2);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var stages = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(config.$3)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => LocalBackupReviewDialog(
                      review: _review(),
                      stage: (_) async {
                        stages++;
                      },
                      restart: () {},
                    ),
                  ),
                  child: const Text('Review'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();
        expect(find.textContaining('7,654 coins'), findsOneWidget);
        await tester.ensureVisible(find.text('Continue'));
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Cancel'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(stages, 0);
        expect(find.byType(LocalBackupReviewDialog), findsNothing);
      },
    );
  }
  testWidgets(
    'Enter cancels by default; failed confirmed restore requires restart',
    (tester) async {
      var stages = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => LocalBackupReviewDialog(
                    review: _review(),
                    stage: (_) async {
                      stages++;
                      throw StateError('private raw error');
                    },
                    restart: () {},
                  ),
                ),
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(LocalBackupReviewDialog), findsNothing);
      expect(stages, 0);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore & restart'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(stages, 1);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Restart game'), findsOneWidget);
      expect(find.textContaining('private raw error'), findsNothing);
    },
  );
  testWidgets(
    'bootstrap applies backup before identity/game and requires acknowledgment',
    (tester) async {
      final storage = ImportMemoryStorage({
        _key: '{damaged',
        '${_key}_backup': _good(),
      });
      await ProgressRecoveryService(storage: storage).stage(_review());
      var cloud = 0, games = 0;
      final leases = <bool>[];
      await tester.pumpWidget(
        SaveImportBootstrap(
          transfer: SaveTransferService(storage: storage),
          acquireLease: ({bool exclusive = false}) async {
            leases.add(exclusive);
            return () async {};
          },
          initializeCloud: () async {
            cloud++;
          },
          appBuilder: () {
            games++;
            return const SizedBox();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(leases, [false, true]);
      expect(cloud, 0);
      expect(games, 0);
      expect(storage.values[_key], _good());
      expect(find.text('Local backup restored'), findsOneWidget);
      await tester.tap(find.text('Open game'));
      await tester.pumpAndSettle();
      expect(cloud, 1);
      expect(games, 1);
    },
  );
  testWidgets('blocked exclusive lease cannot alter progress or start cloud', (
    tester,
  ) async {
    final storage = ImportMemoryStorage({
      _key: '{damaged',
      '${_key}_backup': _good(),
    });
    await ProgressRecoveryService(storage: storage).stage(_review());
    final before = {...storage.values};
    var cloud = 0;
    await tester.pumpWidget(
      SaveImportBootstrap(
        transfer: SaveTransferService(storage: storage),
        acquireLease: ({bool exclusive = false}) async {
          if (exclusive) throw StateError('another tab');
          return () async {};
        },
        initializeCloud: () async {
          cloud++;
        },
        appBuilder: () => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.values, before);
    expect(cloud, 0);
    expect(find.text('Keep original saves'), findsOneWidget);
  });
  for (final backup in [false, true]) {
    testWidgets(
      'root pauses damaged progress (readable backup=$backup), keeps data, then retries',
      (tester) async {
        final accounts = AccountService();
        await accounts.initialize();
        final id = accounts.account!.id,
            key = ProgressRecoveryService.primaryKey(accounts.account!.id);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, '{damaged progress');
        if (backup) await prefs.setString('${key}_backup', _good());
        final game = GameService(), identity = _Identity();
        await tester.pumpWidget(
          NestariumApp(
            accounts: accounts,
            game: game,
            accountProtection: identity,
            onlineLobby: _OfflineLobby(),
          ),
        );
        await _frames(tester);
        expect(find.byType(SavedPlayerRecoveryScreen), findsOneWidget);
        expect(find.byType(MainGameShell), findsNothing);
        expect(identity.starts, 0);
        expect(game.isInitialized, false);
        await game.save();
        await tester.pump(const Duration(seconds: 3));
        expect(prefs.getString(key), '{damaged progress');
        if (backup) expect(prefs.getString('${key}_backup'), _good());
        // Explicit disposable fixture repair, never a production-player action.
        await prefs.setString(key, _good());
        final recovery = tester.widget<SavedPlayerRecoveryScreen>(
          find.byType(SavedPlayerRecoveryScreen),
        );
        await recovery.onRetry();
        await _frames(tester);
        expect(find.byType(MainGameShell), findsOneWidget);
        expect(accounts.account!.id, id);
        expect(identity.starts, 1);
        expect(game.coins, 7654);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'recovery can open player picker without loading a default save',
    (tester) async {
      final accounts = AccountService();
      await accounts.initialize();
      final key = ProgressRecoveryService.primaryKey(accounts.account!.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, '{damaged');
      final identity = _Identity();
      await tester.pumpWidget(
        NestariumApp(
          accounts: accounts,
          accountProtection: identity,
          onlineLobby: _OfflineLobby(),
        ),
      );
      await _frames(tester);
      tester
          .widget<SavedPlayerRecoveryScreen>(
            find.byType(SavedPlayerRecoveryScreen),
          )
          .onChoosePlayer!();
      await _frames(tester);
      expect(find.byType(AccountOnboardingScreen), findsOneWidget);
      expect(prefs.getString(key), '{damaged');
      expect(
        prefs.containsKey(ProgressRecoveryService.primaryKey(null)),
        false,
      );
      expect(identity.starts, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('runtime damage replaces gameplay with recovery screen', (
    tester,
  ) async {
    final accounts = AccountService();
    await accounts.initialize();
    final key = ProgressRecoveryService.primaryKey(accounts.account!.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _good());
    final game = GameService();
    await tester.pumpWidget(
      NestariumApp(
        accounts: accounts,
        game: game,
        accountProtection: _Identity(),
        onlineLobby: _OfflineLobby(),
      ),
    );
    await _frames(tester);
    expect(find.byType(MainGameShell), findsOneWidget);
    await prefs.setString(key, '{runtime-damage');
    await game.save();
    await _frames(tester);
    expect(find.byType(SavedPlayerRecoveryScreen), findsOneWidget);
    expect(find.byType(MainGameShell), findsNothing);
    expect(prefs.getString(key), '{runtime-damage');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Identity extends AccountProtectionService {
  int starts = 0;
  @override
  Future<void> initialize({String? accountId}) async {
    starts++;
    await super.initialize(accountId: accountId);
  }
}

class _OfflineLobby extends OnlineLobbyService {
  @override
  void updatePresence(OnlinePresenceSnapshot presence) {}
}
