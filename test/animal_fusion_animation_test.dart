import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/utils/animal_fusion_logic.dart';
import 'package:egg_hatchers/widgets/animal_fusion_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skip reveals the fusion result immediately', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimalFusionAnimation(
            theme: BackgroundThemes.hatcheryDefault,
            customSprites: CustomSpriteService(),
            outcome: const AnimalFusionOutcome(
              animalId: 'chicken',
              inputMutationId: 'none',
              succeeded: true,
              inputDisplayName: 'Chicken',
              resultMutationId: 'golden',
              displayName: 'Golden Chicken',
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(AnimalFusionAnimation.skipButtonKey), findsOneWidget);
    expect(find.text('Fusion Success!'), findsNothing);

    await tester.tap(find.byKey(AnimalFusionAnimation.skipButtonKey));
    await tester.pump();

    expect(find.byKey(AnimalFusionAnimation.skipButtonKey), findsNothing);
    expect(find.text('Fusion Success!'), findsOneWidget);
    expect(find.text('Created Golden Chicken!'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
