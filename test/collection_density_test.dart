import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/screens/collection_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/tutorial_service.dart';
import 'package:egg_hatchers/widgets/animal_fusion_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'fusion income preview fits a narrow phone without spending animals',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      final preferences = PreferencesService();
      final sprites = CustomSpriteService();
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
      ]);
      game.skipTutorial();
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 2),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnimalFusionPanel(
                game: game,
                theme: preferences.selectedTheme,
                customSprites: sprites,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuse 2').first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Hatchery income:'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(game.ownedAnimals.single.quantity, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      game.dispose();
      preferences.dispose();
      sprites.dispose();
    },
  );

  testWidgets('collection separates animal management from fusion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final game = GameService();
    final preferences = PreferencesService();
    final customSprites = CustomSpriteService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      customSprites.initialize(),
    ]);
    game.skipTutorial();
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 1),
      OwnedAnimal(animalId: 'mouse', quantity: 2, mutationId: 'golden'),
      OwnedAnimal(animalId: 'rabbit', quantity: 3),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: CollectionScreen(
          game: game,
          preferences: preferences,
          customSprites: customSprites,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('collection-controls')), findsOneWidget);
    expect(
      find.text(
        'Fuse 2 matching animals with the same mutation to upgrade them.',
      ),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('collection-search')),
      'mouse',
    );
    await tester.pump();
    expect(find.text('Golden Mouse'), findsOneWidget);
    expect(find.text('Chicken'), findsNothing);

    await tester.tap(find.textContaining('Fusion').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('collection-controls')), findsNothing);
    expect(
      find.text(
        'Fuse 2 matching animals with the same mutation to upgrade them.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    game.dispose();
  });

  testWidgets('fusion tutorial opens the fusion mode automatically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final game = GameService();
    final preferences = PreferencesService();
    final customSprites = CustomSpriteService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      customSprites.initialize(),
    ]);

    final tutorial = TutorialService.instance;
    tutorial.attach(game: game, theme: preferences.selectedTheme);
    tutorial.showWelcome(isReplay: true);
    tutorial.startGuided();
    for (var i = 0; i < 7; i++) {
      tutorial.advanceNext(force: true);
    }
    expect(tutorial.currentStep?.id, 'fusion');

    await tester.pumpWidget(
      MaterialApp(
        home: CollectionScreen(
          game: game,
          preferences: preferences,
          customSprites: customSprites,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('collection-controls')), findsNothing);
    expect(
      find.text(
        'Fuse 2 matching animals with the same mutation to upgrade them.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tutorial.skipTutorial();
    game.dispose();
  });
}
