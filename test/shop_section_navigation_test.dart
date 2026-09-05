import 'package:egg_hatchers/screens/shop_screen.dart';
import 'package:egg_hatchers/services/custom_egg_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shop category switcher shows one catalog at a time', (
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
    game.devCompleteTutorial();

    await tester.pumpWidget(
      MaterialApp(
        home: ShopScreen(
          game: game,
          preferences: preferences,
          customSprites: customSprites,
          customEggs: customEggs,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basic Egg'), findsOneWidget);
    expect(find.text('Boss Egg'), findsNothing);
    expect(find.text('Create Custom Egg'), findsNothing);
    expect(find.byTooltip('Custom Eggs'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop-section-battle')));
    await tester.pumpAndSettle();

    expect(find.text('Basic Egg'), findsNothing);
    expect(find.text('Boss Egg'), findsOneWidget);
    expect(find.text('Create Custom Egg'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop-section-custom')));
    await tester.pumpAndSettle();

    expect(find.text('Basic Egg'), findsNothing);
    expect(find.text('Boss Egg'), findsNothing);
    expect(find.text('Create Custom Egg'), findsOneWidget);
    expect(tester.takeException(), isNull);

    game.dispose();
    customEggs.dispose();
    customSprites.dispose();
  });
}
