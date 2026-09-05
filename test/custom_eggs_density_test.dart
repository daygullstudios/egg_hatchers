import 'package:egg_hatchers/models/custom_egg.dart';
import 'package:egg_hatchers/screens/custom_eggs_screen.dart';
import 'package:egg_hatchers/services/custom_egg_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('custom eggs use searchable single-open summaries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final game = GameService();
    final preferences = PreferencesService();
    final customEggs = CustomEggService();
    final customSprites = CustomSpriteService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      customEggs.initialize(),
      customSprites.initialize(),
    ]);
    await customEggs.saveEgg(
      const CustomEgg(
        id: 'alpha',
        name: 'Alpha Egg',
        emoji: '⭐',
        cost: 500,
        selectedAnimalIds: ['chicken'],
      ),
    );
    await customEggs.saveEgg(
      const CustomEgg(
        id: 'beta',
        name: 'Beta Egg',
        emoji: '🌙',
        cost: 900,
        selectedAnimalIds: ['mouse'],
        isEnabled: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomEggsScreen(
          game: game,
          preferences: preferences,
          customEggs: customEggs,
          customSprites: customSprites,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alpha Egg'), findsOneWidget);
    expect(find.text('Beta Egg'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('custom-egg-toggle-alpha')));
    await tester.pump();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('custom-egg-toggle-beta')));
    await tester.pump();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-egg-search')),
      'Alpha',
    );
    await tester.pump();
    expect(find.text('Alpha Egg'), findsOneWidget);
    expect(find.text('Beta Egg'), findsNothing);
    expect(tester.takeException(), isNull);

    game.dispose();
    customEggs.dispose();
    customSprites.dispose();
  });
}
