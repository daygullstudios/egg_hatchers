import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/screens/multiplayer_lobby_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final account = PlayerAccount(
    id: 'player_1',
    displayName: 'Egg Hero',
    username: 'egg_hero',
    avatarColorValue: 0xFF5271FF,
    createdAt: DateTime.utc(2026, 8, 27),
  );

  Future<
    ({
      GameService game,
      PreferencesService preferences,
      CustomSpriteService sprites,
    })
  >
  services() async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    await Future.wait([
      game.initialize(),
      preferences.initialize(),
      sprites.initialize(),
    ]);
    game.devSetOwnedAnimalsForTesting(const [
      OwnedAnimal(animalId: 'chicken', quantity: 1, level: 20),
      OwnedAnimal(animalId: 'fox', quantity: 1, level: 12),
      OwnedAnimal(animalId: 'dragon', quantity: 1, level: 4),
    ]);
    return (game: game, preferences: preferences, sprites: sprites);
  }

  testWidgets('online lobby fits a narrow phone and identifies the account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final setup = await services();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerLobbyScreen(
          game: setup.game,
          preferences: setup.preferences,
          customSprites: setup.sprites,
          account: account,
          onFindMatch: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Online Arena'), findsOneWidget);
    expect(find.text('Egg Hero'), findsOneWidget);
    expect(find.text('@egg_hero'), findsOneWidget);
    expect(find.text('Match server connected'), findsOneWidget);
    expect(tester.takeException(), isNull);
    setup.game.dispose();
  });

  testWidgets('find match sends the selected three-animal player snapshot', (
    tester,
  ) async {
    final setup = await services();
    MultiplayerPlayerSnapshot? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerLobbyScreen(
          game: setup.game,
          preferences: setup.preferences,
          customSprites: setup.sprites,
          account: account,
          onFindMatch: (snapshot) async => submitted = snapshot,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('find-online-match-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.playerId, account.id);
    expect(submitted!.team, hasLength(3));
    setup.game.dispose();
  });
}
