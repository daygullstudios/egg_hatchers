import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/screens/battles_screen.dart';
import 'package:egg_hatchers/services/account_service.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/widgets/account_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('battle sections keep only one detailed panel open', (
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
    final accounts = AccountService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      customSprites.initialize(),
      accounts.initialize(),
    ]);
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 1, level: 10),
    ]);
    await tester.pumpWidget(
      AccountScope(
        accounts: accounts,
        child: MaterialApp(
          home: BattlesScreen(
            game: game,
            preferences: preferences,
            customSprites: customSprites,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auto Battle'), findsOneWidget);
    expect(find.text('Egg Homing'), findsNothing);
    expect(find.text('Battle Limit Break'), findsNothing);

    final upgrades = find.byKey(const ValueKey('battle-section-upgrades'));
    await tester.ensureVisible(upgrades);
    await tester.tap(upgrades);
    await tester.pumpAndSettle();

    expect(find.text('Auto Battle'), findsNothing);
    expect(find.text('Egg Homing'), findsOneWidget);
    expect(find.text('Battle Limit Break'), findsNothing);

    final shards = find.byKey(const ValueKey('battle-section-shard-upgrades'));
    tester.widget<InkWell>(shards).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Egg Homing'), findsNothing);
    expect(find.text('Battle Limit Break'), findsOneWidget);
    expect(tester.takeException(), isNull);
    game.dispose();
    accounts.dispose();
  });
}
