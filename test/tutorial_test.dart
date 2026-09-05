import 'dart:convert';

import 'package:egg_hatchers/data/tutorial_data.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/navigation/app_page_route.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tutorial entry language also fits manual replay', () {
    expect(TutorialData.welcomeTitle, 'Tutorial');
    expect(TutorialData.startButtonLabel, 'Start Tutorial');
    expect(TutorialData.exitButtonLabel, 'Exit Tutorial');
  });

  test('new player should auto-start tutorial', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    expect(game.shouldAutoStartTutorial, isTrue);
    expect(game.tutorialCompleted, isFalse);
    expect(game.tutorialSkipped, isFalse);

    game.dispose();
  });

  test('complete tutorial stops auto-start', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.completeTutorial();

    expect(game.shouldAutoStartTutorial, isFalse);
    expect(game.tutorialCompleted, isTrue);
    expect(game.tutorialVersionCompleted, TutorialData.currentVersion);

    game.dispose();
  });

  test('skip tutorial stops auto-start', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();

    game.skipTutorial();

    expect(game.shouldAutoStartTutorial, isFalse);
    expect(game.tutorialSkipped, isTrue);

    game.dispose();
  });

  test('advanced save does not auto-start tutorial', () async {
    final state = PlayerState.initial().copyWith(
      lifetimeCoinsEarned: 5000,
      coins: 1200,
    );
    SharedPreferences.setMockInitialValues({
      'egg_hatchers_player_state': jsonEncode(state.toJson()),
    });

    final game = GameService();
    await game.initialize();

    expect(game.shouldAutoStartTutorial, isFalse);

    game.dispose();
  });

  test('tutorial fields default safely on old saves', () {
    final restored = PlayerState.fromJson({
      'coins': 1000,
      'ownedAnimals': <dynamic>[],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 5000,
    });

    expect(restored.tutorialCompleted, isFalse);
    expect(restored.tutorialSkipped, isFalse);
    expect(restored.tutorialVersionCompleted, 0);
  });

  test('tutorial fields round-trip through json', () {
    final state = PlayerState.initial().copyWith(
      tutorialCompleted: true,
      tutorialSkipped: false,
      tutorialVersionCompleted: TutorialData.currentVersion,
    );
    final restored = PlayerState.fromJson(state.toJson());
    expect(restored.tutorialCompleted, isTrue);
    expect(restored.tutorialVersionCompleted, TutorialData.currentVersion);
  });

  test('rebirth preserves tutorial state', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.completeTutorial();
    game.setLifetimeCoinsEarned(1_000_000);

    expect(game.performRebirth(), isTrue);
    expect(game.tutorialCompleted, isTrue);
    expect(game.tutorialVersionCompleted, TutorialData.currentVersion);

    game.dispose();
  });

  test('dev reset tutorial clears completion flags', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.completeTutorial();

    game.devResetTutorial();

    expect(game.tutorialCompleted, isFalse);
    expect(game.tutorialSkipped, isFalse);
    expect(game.tutorialVersionCompleted, 0);

    game.dispose();
  });

  test('advanced secret tutorial covers late-game unlock guidance', () {
    final targetIds = TutorialData.advancedSecretSteps
        .map((step) => step.targetId)
        .toList();

    expect(targetIds, contains(TutorialTargetIds.secretStatsSection));
    expect(targetIds, contains(TutorialTargetIds.secretLateGameGuide));
    expect(targetIds, contains(TutorialTargetIds.secretRottenShellGuide));
    expect(TutorialData.advancedSecretSteps.last.isFinish, isTrue);
    expect(
      TutorialData.advancedSecretSteps.every(
        (step) => step.requiredRoute == kSecretToolsRouteName,
      ),
      isTrue,
    );
  });
}
