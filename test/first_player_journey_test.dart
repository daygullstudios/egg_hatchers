import 'dart:math';

import 'package:egg_hatchers/data/tutorial_data.dart';
import 'package:egg_hatchers/main.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/navigation/app_page_route.dart';
import 'package:egg_hatchers/screens/main_game_shell.dart';
import 'package:egg_hatchers/services/account_protection_service.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/progress_sync_service.dart';
import 'package:egg_hatchers/services/tutorial_service.dart';
import 'package:egg_hatchers/widgets/hatch_dialog.dart';
import 'package:egg_hatchers/widgets/tutorial_overlay.dart';
import 'package:egg_hatchers/widgets/tutorial_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('fresh player completes and reopens the journey at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({});
      _mockAudio();
      final tutorial = TutorialService.instance;
      final accounts = AccountService();
      final game = GameService(random: _FirstOutcomeRandom());
      await tester.pumpWidget(_app(accounts, game));
      await _frames(tester);
      expect(find.byType(MainGameShell), findsOneWidget);
      expect(tutorial.phase, TutorialPhase.welcome);
      expect(game.state.ownedAnimals, isEmpty);
      expect(game.coins, 250);
      final playerId = accounts.account!.id;

      await _tapVisible(tester, find.text('Start'), size);
      // Drive only rendered controls: no direct navigation, progress seeding,
      // tutorial advancement, purchases, or reward grants in this journey.
      for (final step in TutorialData.steps) {
        expect(tutorial.currentStep?.id, step.id);
        expect(
          AppNavigationTracker.instance.topRouteName,
          step.requiredRoute,
          reason: '${step.id} must stay connected to the visible screen',
        );
        final overlay = find.byType(TutorialSpotlightOverlay);
        expect(overlay, findsOneWidget);
        if (step.isBackStep) {
          expect(
            find.descendant(of: overlay, matching: find.text('Next')),
            findsNothing,
            reason: 'Back must navigate, not abandon the next step offscreen',
          );
        }
        if (step.id == 'buyEgg') {
          final buyRect = tester.getRect(
            find.byKey(TutorialTargets.basicEggBuyButton),
          );
          expect(
            buyRect.intersect(Offset.zero & size),
            buyRect,
            reason:
                'Route notifications must not consume auto-scroll before it runs',
          );
        }
        expect(
          find
              .descendant(of: overlay, matching: find.text('Exit'))
              .hitTestable(),
          findsOneWidget,
          reason: '${step.id}: exit must remain reachable',
        );
        final actionLabels = [
          if (step.isFinish) TutorialData.finishButtonLabel,
          if (step.isBackStep) TutorialData.returnToHatcheryFallbackLabel,
          if (step.fallbackActionLabel != null) step.fallbackActionLabel!,
          'Next',
        ];
        Finder? action;
        for (final label in actionLabels) {
          final candidate = find.descendant(
            of: overlay,
            matching: find.text(label),
          );
          if (candidate.evaluate().isNotEmpty) {
            action = candidate;
            break;
          }
        }
        if (action != null) {
          await _tapVisible(tester, action, size);
        } else {
          final target = find.byKey(TutorialTargets.keyFor(step.targetId)!);
          final rect = tester.getRect(target);
          expect(
            (Offset.zero & size).contains(rect.center),
            isTrue,
            reason: '${step.id}: highlighted action must be in view',
          );
          // The spotlight intentionally proxies a tap over the real target.
          await tester.tapAt(rect.center);
          await _frames(tester);
        }
        if (step.id == 'buyEgg') {
          expect(find.byType(HatchDialog), findsOneWidget);
          expect(game.state.ownedAnimals.single.quantity, 1);
          expect(game.coinsPerSecond, greaterThan(0));
          await _tapVisible(
            tester,
            find.byKey(const ValueKey('skip-single-hatch-animation')),
            size,
          );
          await tester.pump(const Duration(milliseconds: 600));
          // A short phone may scroll the reveal, but the closing action must
          // be reachable within the dialog rather than outside the viewport.
          final close = find.text('Awesome!');
          await tester.ensureVisible(close);
          await _tapVisible(tester, close, size);
          final before = game.coins;
          await tester.pump(const Duration(seconds: 2));
          await _frames(tester);
          expect(game.coins, greaterThan(before));
        }
        if (step.id == 'upgrade') {
          expect(game.state.ownedAnimals.single.level, 2);
        }
      }
      expect(tutorial.isActive, isFalse);
      expect(game.state.tutorialCompleted, isTrue);
      final animals = game.state.ownedAnimals.map((a) => a.toJson()).toList();
      await tester.runAsync(game.save);
      final savedCoins = game.coins;
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);

      final reopenedAccounts = AccountService();
      final reopened = GameService();
      await tester.pumpWidget(_app(reopenedAccounts, reopened));
      await _frames(tester);
      expect(reopenedAccounts.account!.id, playerId);
      expect(
        reopened.state.ownedAnimals.map((a) => a.toJson()).toList(),
        animals,
      );
      expect(reopened.coins, greaterThanOrEqualTo(savedCoins));
      expect(reopened.state.tutorialCompleted, isTrue);
      expect(reopened.shouldAutoStartTutorial, isFalse);
      expect(tutorial.isActive, isFalse);
      expect(find.byType(MainGameShell), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(AccountService accounts, GameService game) => NestariumApp(
  accounts: accounts,
  game: game,
  accountProtection: AccountProtectionService(), // Deliberately device-only.
  onlineLobby: _OfflineLobby(),
  progressSync: _OfflineSync(),
);

Future<void> _frames(WidgetTester tester) async {
  // Bounded pumping: the idle game's continuous animations never settle.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder, Size size) async {
  expect(finder.hitTestable(), findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.intersect(Offset.zero & size), rect);
  await tester.tap(finder);
  await _frames(tester);
}

class _OfflineLobby extends OnlineLobbyService {
  @override
  void updatePresence(OnlinePresenceSnapshot presence) {}
}

class _OfflineSync extends ProgressSyncService {
  @override
  Future<void> selectAccount({
    required String? accountId,
    required String? protectedPlayerId,
    CloudProgressRepository? cloud,
    ApplyCloudProgress? applyCloud,
  }) async {}
}

class _FirstOutcomeRandom implements Random {
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void _mockAudio() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
  }
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers/events/$id'),
          (_) async => null,
        );
      }
      return null;
    },
  );
}
