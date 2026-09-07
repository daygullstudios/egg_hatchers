import 'dart:async';
import 'dart:convert';

import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/screens/multiplayer_battle_screen.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/multiplayer_service.dart';
import 'package:egg_hatchers/services/online_identity_token_provider.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/multiplayer_server.dart';
import 'support/controlled_lobby_channel.dart';

void main() {
  testWidgets('online battle fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late LocalMultiplayerServer server;
    late MultiplayerService first;
    late MultiplayerService second;
    late MultiplayerPlayerSnapshot firstPlayer;
    late MultiplayerPlayerSnapshot secondPlayer;
    late CustomSpriteService sprites;
    late GameService game;
    late PreferencesService preferences;
    await tester.runAsync(() async {
      server = await LocalMultiplayerServer.start(port: 0);
      final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
      first = MultiplayerService(serverUri: uri);
      second = MultiplayerService(serverUri: uri);
      await Future.wait([first.connect(), second.connect()]);
      firstPlayer = _player('first', 'First Player');
      secondPlayer = _player('second', 'Second Player');
      first.findMatch(firstPlayer);
      second.findMatch(secondPlayer);
      await _waitFor(() => first.opponent != null && second.opponent != null);
      first.enterBattle();
      second.enterBattle();
      await _waitFor(() => first.battleState != null);

      SharedPreferences.setMockInitialValues({});
      game = GameService();
      preferences = PreferencesService();
      sprites = CustomSpriteService();
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
      ]);
    });
    addTearDown(server.close);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(game.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerBattleScreen(
          multiplayer: first,
          game: game,
          player: firstPlayer,
          opponent: secondPlayer,
          customSprites: sprites,
          preferences: preferences,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ONLINE MATCH'), findsOneWidget);
    expect(find.text('First Player'), findsOneWidget);
    expect(find.text('Second Player'), findsOneWidget);
    expect(find.text('2 ENERGY'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hosted test result cannot grant client-local rewards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = ControlledLobbyChannel()..handshake.complete();
    final multiplayer = MultiplayerService(
      serverUri: Uri.parse('wss://egg-hatchers-playtest.daygullstudios.com/ws'),
      identityTokenProvider: const _TokenProvider(),
      hostedMultiplayerEnabled: true,
      channelFactory: (uri, {protocols}) => channel,
    );
    final player = _player('local-player', 'Local Player');
    final opponent = _player('peer-safe-id', 'Player A1B2C3');
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    await tester.runAsync(() async {
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
      ]);
      await multiplayer.connect();
      multiplayer.findMatch(player);
      channel.incoming.add(
        _message({
          'type': 'matched',
          'matchId': 'hosted-match',
          'opponent': opponent.toJson(),
        }),
      );
      channel.incoming.add(
        _message({
          'type': 'battleState',
          'matchId': 'hosted-match',
          'revision': 1,
          'message': 'Battle ready',
          'self': _combatantState([100, 100, 100]),
          'opponent': _combatantState([100, 100, 100]),
        }),
      );
    });
    addTearDown(() {
      multiplayer.dispose();
      game.dispose();
      channel.finish();
    });
    final coinsBefore = game.coins;
    final ratingBefore = game.arenaRating;
    final tokensBefore = game.battleTokens;

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerBattleScreen(
          multiplayer: multiplayer,
          game: game,
          player: player,
          opponent: opponent,
          customSprites: sprites,
          preferences: preferences,
        ),
      ),
    );
    await tester.pump();
    channel.incoming.add(
      _message({
        'type': 'battleState',
        'matchId': 'hosted-match',
        'revision': 2,
        'message': 'Local Player wins the test battle!',
        'lastActor': 'self',
        'winner': 'self',
        'self': _combatantState([100, 100, 100]),
        'opponent': _combatantState([0, 0, 0]),
      }),
    );
    await tester.pump();

    expect(find.text('ONLINE VICTORY'), findsOneWidget);
    expect(
      find.textContaining('coins, tokens, and rating stay unchanged'),
      findsOneWidget,
    );
    expect(game.coins, coinsBefore);
    expect(game.arenaRating, ratingBefore);
    expect(game.battleTokens, tokensBefore);
  });

  testWidgets('dropped hosted battle offers a clear reconnect action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = ControlledLobbyChannel()..handshake.complete();
    final multiplayer = MultiplayerService(
      serverUri: Uri.parse('wss://egg-hatchers-playtest.daygullstudios.com/ws'),
      identityTokenProvider: const _TokenProvider(),
      hostedMultiplayerEnabled: true,
      channelFactory: (uri, {protocols}) => channel,
    );
    final player = _player('local-player', 'Local Player');
    final opponent = _player('peer-safe-id', 'Player A1B2C3');
    final game = GameService();
    final preferences = PreferencesService();
    final sprites = CustomSpriteService();
    await tester.runAsync(() async {
      await Future.wait([
        game.initialize(),
        preferences.initialize(),
        sprites.initialize(),
      ]);
      await multiplayer.connect();
      multiplayer.findMatch(player);
      channel.incoming.add(
        _message({
          'type': 'matched',
          'matchId': 'hosted-match',
          'opponent': opponent.toJson(),
        }),
      );
      channel.incoming.add(
        _message({
          'type': 'battleState',
          'matchId': 'hosted-match',
          'revision': 1,
          'message': 'Battle ready',
          'self': _combatantState([100, 100, 100]),
          'opponent': _combatantState([100, 100, 100]),
        }),
      );
    });
    addTearDown(() {
      multiplayer.dispose();
      game.dispose();
      channel.finish();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MultiplayerBattleScreen(
          multiplayer: multiplayer,
          game: game,
          player: player,
          opponent: opponent,
          customSprites: sprites,
          preferences: preferences,
        ),
      ),
    );
    await tester.pump();
    channel.finish();
    await tester.pump();

    expect(find.text('BATTLE PAUSED'), findsOneWidget);
    expect(find.text('RECONNECT'), findsOneWidget);
    expect(find.textContaining('within 30 seconds'), findsOneWidget);
  });
}

final class _TokenProvider implements OnlineIdentityTokenProvider {
  const _TokenProvider();

  @override
  Future<String?> getIdToken() async => 'test-token';
}

String _message(Map<String, dynamic> value) => jsonEncode(value);

Map<String, dynamic> _combatantState(List<int> health) => {
  'health': health,
  'activeIndex': 0,
  'energy': 0,
  'shield': 0,
  'energyHits': 0,
  'energyMisses': 0,
  'combo': 0,
  'bestCombo': 0,
};

MultiplayerPlayerSnapshot _player(String id, String name) {
  return MultiplayerPlayerSnapshot.fromPlayer(
    account: PlayerAccount(
      id: id,
      displayName: name,
      username: id,
      avatarColorValue: 0xFF5271FF,
      createdAt: DateTime.utc(2026, 8, 27),
    ),
    rating: 1000,
    team: const [
      ArenaFighter(animalId: 'chicken', mutationId: 'none', level: 1, power: 1),
      ArenaFighter(animalId: 'fox', mutationId: 'none', level: 1, power: 2),
      ArenaFighter(animalId: 'dragon', mutationId: 'none', level: 1, power: 3),
    ],
  );
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Expected multiplayer state was not reached.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
