import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/multiplayer_service.dart';
import 'package:egg_hatchers/services/online_identity_token_provider.dart';
import 'package:egg_hatchers/utils/battle_power_logic.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/multiplayer_server.dart';
import 'support/controlled_lobby_channel.dart';

void main() {
  test('hosted playtest failure keeps Bot Arena as the clear fallback', () {
    expect(
      MultiplayerService.unavailableMessageFor(
        Uri.parse('wss://egg-hatchers-playtest.daygullstudios.com/ws'),
      ),
      'Protected online multiplayer is still being completed. '
      'Bot Arena is available now.',
    );
  });

  test(
    'local failure still explains that the development server is absent',
    () {
      expect(
        MultiplayerService.unavailableMessageFor(
          Uri.parse('ws://127.0.0.1:53218/ws'),
        ),
        'The local match server is not running.',
      );
    },
  );

  test(
    'hosted multiplayer stays fail-closed until its release flag is on',
    () async {
      var opened = false;
      final service = MultiplayerService(
        serverUri: Uri.parse(
          'wss://egg-hatchers-playtest.daygullstudios.com/ws',
        ),
        identityTokenProvider: _TokenProvider('valid-token'),
        channelFactory: (uri, {protocols}) {
          opened = true;
          return ControlledLobbyChannel();
        },
      );
      addTearDown(service.dispose);
      await service.connect();
      expect(opened, isFalse);
      expect(service.state, MultiplayerConnectionState.offline);
      expect(service.message, contains('still being completed'));
    },
  );

  test(
    'released hosted multiplayer authenticates in websocket protocols',
    () async {
      final channel = ControlledLobbyChannel()..handshake.complete();
      Uri? openedUri;
      Iterable<String>? openedProtocols;
      final service = MultiplayerService(
        serverUri: Uri.parse(
          'wss://egg-hatchers-playtest.daygullstudios.com/ws',
        ),
        identityTokenProvider: _TokenProvider('firebase-token'),
        hostedMultiplayerEnabled: true,
        channelFactory: (uri, {protocols}) {
          openedUri = uri;
          openedProtocols = protocols;
          return channel;
        },
      );
      addTearDown(() {
        service.dispose();
        channel.finish();
      });
      await service.connect();
      expect(openedUri, service.serverUri);
      expect(openedProtocols, ['nestarium-v1', 'firebase-auth.firebase-token']);
      expect(service.state, MultiplayerConnectionState.ready);
    },
  );

  test(
    'released hosted multiplayer rejects a missing identity token',
    () async {
      var opened = false;
      final service = MultiplayerService(
        serverUri: Uri.parse(
          'wss://egg-hatchers-playtest.daygullstudios.com/ws',
        ),
        identityTokenProvider: _TokenProvider(null),
        hostedMultiplayerEnabled: true,
        channelFactory: (uri, {protocols}) {
          opened = true;
          throw StateError('must not open');
        },
      );
      addTearDown(service.dispose);
      await service.connect();
      expect(opened, isFalse);
      expect(service.state, MultiplayerConnectionState.offline);
    },
  );

  test('two matched players share a server-authoritative battle', () async {
    final webRoot = await Directory.systemTemp.createTemp('nestarium_web_');
    await File(
      '${webRoot.path}${Platform.pathSeparator}index.html',
    ).writeAsString('<!doctype html><title>Nestarium</title>');
    addTearDown(() => webRoot.delete(recursive: true));
    final server = await LocalMultiplayerServer.start(
      port: 0,
      webRoot: webRoot.path,
    );
    addTearDown(server.close);
    final pageRequest = await HttpClient().getUrl(
      Uri.parse('http://127.0.0.1:${server.port}/'),
    );
    final pageResponse = await pageRequest.close();
    final page = await utf8.decoder.bind(pageResponse).join();
    expect(pageResponse.statusCode, HttpStatus.ok);
    expect(page, contains('Nestarium'));
    final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
    final first = MultiplayerService(serverUri: uri);
    final second = MultiplayerService(serverUri: uri);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await Future.wait([first.connect(), second.connect()]);

    first.findMatch(_player('first', 'First Player'));
    second.findMatch(_player('second', 'Second Player'));
    await _waitFor(() => first.state == MultiplayerConnectionState.matched);
    await _waitFor(() => second.state == MultiplayerConnectionState.matched);

    expect(first.matchId, isNotNull);
    expect(first.matchId, second.matchId);
    expect(first.opponent!.username, 'second');
    expect(second.opponent!.username, 'first');
    expect(
      second.opponent!.team.first.power,
      BattlePowerLogic.battlePowerForOwnedAnimal(
        const OwnedAnimal(animalId: 'chicken', quantity: 1),
      ),
    );

    first.enterBattle();
    second.enterBattle();
    await _waitFor(
      () => first.battleState != null && second.battleState != null,
    );
    final startingHealth = first.battleState!.opponent.health.first;

    while ((first.battleState?.self.energy ?? 0) < 2) {
      await _waitFor(() => first.energySpawn != null);
      first.collectEnergy(first.energySpawn!.id);
      await _waitFor(() => first.energySpawn == null);
    }
    await _waitFor(
      () => second.battleState!.opponent.combo == first.battleState!.self.combo,
    );
    expect(first.battleState!.self.combo, greaterThan(0));
    expect(first.battleState!.self.bestCombo, first.battleState!.self.combo);
    first.useAbility(0);

    await _waitFor(
      () => first.battleState!.opponent.health.first < startingHealth,
    );
    await _waitFor(
      () =>
          second.battleState!.self.health.first ==
          first.battleState!.opponent.health.first,
    );

    expect(first.battleState!.self.energy, lessThan(2));
    expect(first.battleState!.opponent.health, second.battleState!.self.health);
    expect(first.battleState!.revision, second.battleState!.revision);

    final far = MultiplayerService(serverUri: uri);
    final nearbyFirst = MultiplayerService(serverUri: uri);
    final nearbySecond = MultiplayerService(serverUri: uri);
    addTearDown(far.dispose);
    addTearDown(nearbyFirst.dispose);
    addTearDown(nearbySecond.dispose);
    await Future.wait([
      far.connect(),
      nearbyFirst.connect(),
      nearbySecond.connect(),
    ]);
    far.findMatch(_player('far', 'Far Player', rating: 1450));
    nearbyFirst.findMatch(_player('near_1', 'Nearby One', rating: 900));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(far.state, MultiplayerConnectionState.searching);
    expect(nearbyFirst.state, MultiplayerConnectionState.searching);

    nearbySecond.findMatch(_player('near_2', 'Nearby Two', rating: 950));
    await _waitFor(
      () => nearbyFirst.state == MultiplayerConnectionState.matched,
    );
    await _waitFor(
      () => nearbySecond.state == MultiplayerConnectionState.matched,
    );
    expect(nearbyFirst.opponent!.rating, 950);
    expect(nearbySecond.opponent!.rating, 900);
    expect(far.state, MultiplayerConnectionState.searching);
  });

  test('match server rejects teams containing unknown animals', () async {
    final webRoot = await Directory.systemTemp.createTemp('nestarium_web_');
    await File(
      '${webRoot.path}${Platform.pathSeparator}index.html',
    ).writeAsString('<!doctype html><title>Nestarium</title>');
    addTearDown(() => webRoot.delete(recursive: true));
    final server = await LocalMultiplayerServer.start(
      port: 0,
      webRoot: webRoot.path,
    );
    addTearDown(server.close);
    final service = MultiplayerService(
      serverUri: Uri.parse('ws://127.0.0.1:${server.port}/ws'),
    );
    addTearDown(service.dispose);
    await service.connect();

    service.findMatch(
      MultiplayerPlayerSnapshot(
        playerId: 'invalid_player',
        displayName: 'Invalid Player',
        username: 'invalid_player',
        avatarColorValue: 0xFF5271FF,
        rating: 1000,
        team: const [
          MultiplayerFighterSnapshot(
            animalId: 'not_a_real_animal',
            mutationId: 'none',
            level: 1,
            power: 999999999,
          ),
          MultiplayerFighterSnapshot(
            animalId: 'fox',
            mutationId: 'none',
            level: 1,
            power: 2,
          ),
          MultiplayerFighterSnapshot(
            animalId: 'dragon',
            mutationId: 'none',
            level: 1,
            power: 3,
          ),
        ],
      ),
    );

    await _waitFor(() => service.state == MultiplayerConnectionState.ready);
    expect(service.message, 'A full team is required.');
  });
}

final class _TokenProvider implements OnlineIdentityTokenProvider {
  const _TokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getIdToken() async => token;
}

MultiplayerPlayerSnapshot _player(String id, String name, {int rating = 1000}) {
  final account = PlayerAccount(
    id: id,
    displayName: name,
    username: id,
    avatarColorValue: 0xFF5271FF,
    createdAt: DateTime.utc(2026, 8, 27),
  );
  return MultiplayerPlayerSnapshot.fromPlayer(
    account: account,
    rating: rating,
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
