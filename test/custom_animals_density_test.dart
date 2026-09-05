import 'package:egg_hatchers/screens/custom_sprites_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/services/sprite_rating_service.dart';
import 'package:egg_hatchers/services/sprite_reference_overlay_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('custom animals keeps tools compact and filters the catalog', (
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
    final spriteRating = SpriteRatingService();
    final referenceOverlay = SpriteReferenceOverlayService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      customSprites.initialize(),
      spriteRating.initialize(),
      referenceOverlay.initialize(),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomSpritesScreen(
          preferences: preferences,
          customSprites: customSprites,
          game: game,
          spriteRating: spriteRating,
          referenceOverlay: referenceOverlay,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Show Custom Animals'), findsNothing);
    expect(find.text('Reset All Custom Animals'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('custom-animal-tools-toggle')));
    await tester.pump();
    expect(find.text('Show Custom Animals'), findsOneWidget);
    expect(find.text('Reset All Custom Animals'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-animal-search')),
      'Nebula Hydra',
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Nebula Hydra' &&
            widget.style?.fontSize == 17,
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('custom-animal-search')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('custom-animal-filter')));
    await tester.pump();
    await tester.tap(find.text('Customized').last);
    await tester.pump();

    expect(find.text('No animals match these filters.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    game.dispose();
    customSprites.dispose();
    spriteRating.dispose();
    referenceOverlay.dispose();
  });
}
