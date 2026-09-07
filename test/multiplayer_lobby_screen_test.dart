import 'dart:convert';

import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/screens/multiplayer_lobby_screen.dart';
import 'package:egg_hatchers/screens/multiplayer_battle_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/multiplayer_service.dart';
import 'package:egg_hatchers/services/online_identity_token_provider.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/controlled_lobby_channel.dart';

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

  testWidgets('hosted lobby explains protected direct matchmaking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final setup = await services();
    final multiplayer = MultiplayerService(
      serverUri: Uri.parse('wss://playtest.example/ws'),
      hostedMultiplayerEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerLobbyScreen(
          game: setup.game,
          preferences: setup.preferences,
          customSprites: setup.sprites,
          account: account,
          multiplayer: multiplayer,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Protected matchmaking'), findsOneWidget);
    expect(
      find.textContaining('Player discovery and invites stay off'),
      findsOneWidget,
    );
    expect(find.text('Online Players'), findsNothing);
    multiplayer.dispose();
    setup.game.dispose();
  });

  testWidgets('hosted lobby selects only the server-owned Online Roster', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final setup = await services();
    final channel = ControlledLobbyChannel()..handshake.complete();
    final multiplayer = MultiplayerService(
      serverUri: Uri.parse('wss://playtest.example/ws'),
      identityTokenProvider: const _TokenProvider('firebase-token'),
      hostedMultiplayerEnabled: true,
      channelFactory: (uri, {protocols}) => channel,
    );
    await multiplayer.connect();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerLobbyScreen(
          game: setup.game,
          preferences: setup.preferences,
          customSprites: setup.sprites,
          account: account,
          multiplayer: multiplayer,
        ),
      ),
    );
    channel.incoming.add(
      jsonEncode({
        'type': 'onlineInventory',
        'revision': 1,
        'items': [
          {
            'animalId': 'chicken',
            'mutationId': 'none',
            'level': 1,
            'quantity': 1,
          },
          {
            'animalId': 'mouse',
            'mutationId': 'none',
            'level': 1,
            'quantity': 1,
          },
          {
            'animalId': 'rabbit',
            'mutationId': 'none',
            'level': 1,
            'quantity': 1,
          },
        ],
      }),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('online-roster-notice')), findsOneWidget);
    expect(find.text('Mouse'), findsOneWidget);
    expect(find.text('Rabbit'), findsOneWidget);
    expect(find.text('Fox'), findsNothing);
    expect(find.text('Dragon'), findsNothing);
    expect(find.text('FIND MATCH'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    multiplayer.dispose();
    channel.finish();
    setup.game.dispose();
  });

  testWidgets('a resumed hosted match reopens battle without a stale prompt', (
    tester,
  ) async {
    final setup = await services();
    final channel = ControlledLobbyChannel()..handshake.complete();
    final multiplayer = MultiplayerService(
      serverUri: Uri.parse('ws://127.0.0.1:53218/ws'),
      channelFactory: (uri, {protocols}) => channel,
    );
    await multiplayer.connect();
    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerLobbyScreen(
          game: setup.game,
          preferences: setup.preferences,
          customSprites: setup.sprites,
          account: account,
          multiplayer: multiplayer,
        ),
      ),
    );
    await tester.pump();

    channel.incoming.add(
      jsonEncode({
        'type': 'matched',
        'matchId': 'resumed-match',
        'resumed': true,
        'opponent': _opponent().toJson(),
      }),
    );
    channel.incoming.add(
      jsonEncode({
        'type': 'battleState',
        'matchId': 'resumed-match',
        'revision': 4,
        'message': 'Players reconnected. Battle resumed.',
        'self': _combatantState(),
        'opponent': _combatantState(),
      }),
    );
    expect(multiplayer.state, MultiplayerConnectionState.matched);
    expect(multiplayer.matchResumed, isTrue);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MultiplayerBattleScreen), findsOneWidget);
    expect(find.text('Opponent found!'), findsNothing);
    expect(find.text('ONLINE MATCH'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    multiplayer.dispose();
    channel.finish();
    setup.game.dispose();
  });
}

class _TokenProvider implements OnlineIdentityTokenProvider {
  const _TokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getIdToken() async => token;
}

MultiplayerPlayerSnapshot _opponent() => const MultiplayerPlayerSnapshot(
  playerId: 'peer-safe-id',
  displayName: 'Player A1B2C3',
  username: 'nest-a1b2c3',
  avatarColorValue: 0xFF5271FF,
  rating: 1000,
  team: [
    MultiplayerFighterSnapshot(
      animalId: 'chicken',
      mutationId: 'none',
      level: 1,
      power: 1,
    ),
    MultiplayerFighterSnapshot(
      animalId: 'fox',
      mutationId: 'none',
      level: 1,
      power: 8,
    ),
    MultiplayerFighterSnapshot(
      animalId: 'dragon',
      mutationId: 'none',
      level: 1,
      power: 250,
    ),
  ],
);

Map<String, dynamic> _combatantState() => {
  'health': [205, 277, 882],
  'activeIndex': 0,
  'energy': 0,
  'shield': 0,
  'energyHits': 0,
  'energyMisses': 0,
  'combo': 0,
  'bestCombo': 0,
};
