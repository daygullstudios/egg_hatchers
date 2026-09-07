import 'dart:async';
import 'dart:convert';

import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/screens/saved_player_recovery_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_session_store.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/services/save_import_storage.dart';
import 'package:egg_hatchers/services/save_transfer_service.dart';
import 'package:egg_hatchers/services/saved_player_directory.dart';
import 'package:egg_hatchers/widgets/app_theme_background.dart';
import 'package:egg_hatchers/widgets/save_import_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/save_import_fixture.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final config in [
    (320.0, 640.0, 1.0),
    (390.0, 844.0, 1.0),
    (430.0, 932.0, 1.0),
    (1440.0, 900.0, 1.0),
    (320.0, 360.0, 1.0),
    (320.0, 360.0, 2.0),
  ]) {
    testWidgets(
      'recovery actions fit portrait shell and cancel is read-only $config',
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
              child: PortraitAppShell(child: child!),
            ),
            home: SavedPlayerRecoveryScreen(
              failure: AccountStartupFailure.unreadableProfiles,
              onRetry: () async {},
              stageImport: (_) async {
                stages++;
              },
              web: true,
              canImport: true,
              pickFile: () async => importFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in [
          'Try again',
          'Download backup',
          'Copy backup',
          'Review saved file',
        ]) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          final button = find
              .ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              )
              .first;
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          final rect = tester.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(config.$1));
        }
        await tester.tap(find.text('Review saved file'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Cancel'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(stages, 0);
        expect(await PreferencesImportStorage().readAll(), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'backup preserves unreadable content, reports download request honestly',
    (tester) async {
      final original = <String, Object>{
        'playerAccounts': '{broken',
        'egg_hatchers_player_state_account_old': 'untouched',
      };
      SharedPreferences.setMockInitialValues(original);
      String? downloaded, copied;
      await tester.pumpWidget(
        MaterialApp(
          home: SavedPlayerRecoveryScreen(
            failure: AccountStartupFailure.unreadableProfiles,
            onRetry: () async {},
            stageImport: (_) async {},
            web: true,
            download: (data, filename) async {
              downloaded = data;
              expect(filename, startsWith('nestarium-recovery-'));
            },
            copy: (data) async {
              copied = data;
            },
          ),
        ),
      );
      await tester.ensureVisible(find.text('Download backup'));
      await tester.tap(find.text('Download backup'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Backup download requested.'), findsOneWidget);
      expect(
        (jsonDecode(downloaded!)['preferences']
            as Map)['playerAccounts']['value'],
        '{broken',
      );
      await tester.ensureVisible(find.text('Copy backup'));
      await tester.tap(find.text('Copy backup'));
      await tester.pumpAndSettle();
      expect(
        (jsonDecode(copied!)['preferences'] as Map)['playerAccounts']['value'],
        '{broken',
      );
      expect(await PreferencesImportStorage().readAll(), original);
    },
  );

  testWidgets(
    'chooser cancel, invalid file and backup failure stay actionable and private',
    (tester) async {
      String? file;
      var picks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SavedPlayerRecoveryScreen(
            failure: AccountStartupFailure.storageUnavailable,
            onRetry: () async {},
            stageImport: (_) async => fail('must not stage'),
            web: true,
            canImport: true,
            pickFile: () async {
              picks++;
              return file;
            },
            download: (_, _) async => throw StateError('PRIVATE CONTENT'),
          ),
        ),
      );
      Future<void> review() async {
        await tester.ensureVisible(find.text('Review saved file'));
        await tester.tap(find.text('Review saved file'));
        await tester.pumpAndSettle();
      }

      await review();
      expect(find.byType(SaveImportReviewDialog), findsNothing);
      file = '{invalid';
      await review();
      expect(picks, 2);
      expect(find.text('That file is not valid JSON.'), findsOneWidget);
      await tester.ensureVisible(find.text('Download backup'));
      await tester.tap(find.text('Download backup'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This action could not finish.'),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE CONTENT'), findsNothing);
      expect(await PreferencesImportStorage().readAll(), isEmpty);
    },
  );

  testWidgets(
    'root blocks identity, game startup and background saves until directory retry succeeds',
    (tester) async {
      final original = <String, Object>{
        'playerAccounts': '{broken',
        'egg_hatchers_player_state': 'do-not-overwrite',
      };
      SharedPreferences.setMockInitialValues(original);
      writeActiveAccountId('original-session');
      final accounts = AccountService();
      final game = _GameRecorder();
      final identity = _IdentityRecorder();
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
      await _backgroundAndResume(tester);
      expect(game.starts, 0);
      expect(game.saves, 0);
      expect(identity.starts, 0);
      expect(await PreferencesImportStorage().readAll(), original);
      expect(readActiveAccountId(), 'original-session');
      // Only disposable fixture data is repaired by this test setup.
      await (await SharedPreferences.getInstance()).setString(
        'playerAccounts',
        jsonEncode([
          {
            'id': 'restored',
            'displayName': 'Restored',
            'username': 'restored',
            'avatarColorValue': 0xFF5271FF,
            'createdAt': '2020-01-01T00:00:00Z',
          },
        ]),
      );
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await _frames(tester);
      expect(find.byType(SavedPlayerRecoveryScreen), findsNothing);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(accounts.account!.id, 'restored');
      expect(game.starts, 1);
      expect(identity.starts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'root recovery import never flushes an uninitialized default player',
    (tester) async {
      final original = <String, Object>{
        'playerAccounts': '{broken',
        'egg_hatchers_player_state': 'do-not-overwrite',
      };
      SharedPreferences.setMockInitialValues(original);
      final game = _GameRecorder();
      final identity = _IdentityRecorder();
      await tester.pumpWidget(
        NestariumApp(game: game, accountProtection: identity),
      );
      await _frames(tester);
      final recovery = tester.widget<SavedPlayerRecoveryScreen>(
        find.byType(SavedPlayerRecoveryScreen),
      );
      // VM coordination fails at the lock step. The root must remain frozen.
      await expectLater(
        recovery.stageImport(
          SaveTransferService().inspectSave(importFixture()),
        ),
        throwsUnsupportedError,
      );
      await recovery.onRetry();
      await _backgroundAndResume(tester);
      expect(game.starts, 0);
      expect(game.saves, 0);
      expect(game.pauses, 0);
      expect(identity.starts, 0);
      expect(await PreferencesImportStorage().readAll(), original);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'retry is single-flight and native recovery does not offer unsupported file actions',
    (tester) async {
      final gate = Completer<void>();
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SavedPlayerRecoveryScreen(
            failure: AccountStartupFailure.storageUnavailable,
            onRetry: () async {
              retries++;
              await gate.future;
            },
            stageImport: (_) async {},
            web: false,
          ),
        ),
      );
      expect(find.text('Review saved file'), findsNothing);
      expect(find.text('Download backup'), findsNothing);
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retries, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _GameRecorder extends GameService {
  int starts = 0, saves = 0, pauses = 0;
  @override
  Future<void> initialize({
    String? accountId,
    bool migrateLegacySave = false,
  }) async {
    starts++;
    await super.initialize(accountId: accountId, migrateLegacySave: false);
  }

  @override
  Future<void> save() async {
    saves++;
    await super.save();
  }

  @override
  Future<void> pauseForSaveImport() async {
    pauses++;
    await super.pauseForSaveImport();
  }
}

class _IdentityRecorder extends AccountProtectionService {
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

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _backgroundAndResume(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await _frames(tester);
}
