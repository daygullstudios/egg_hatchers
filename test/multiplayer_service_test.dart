import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/multiplayer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two connected players receive each other as a match', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final waiting = <({WebSocket socket, Map<String, dynamic> player})>[];
    final serverTask = server.forEach((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((raw) {
        final message = jsonDecode(raw as String) as Map<String, dynamic>;
        if (message['type'] != 'queue') return;
        final player = Map<String, dynamic>.from(message['player'] as Map);
        if (waiting.isEmpty) {
          waiting.add((socket: socket, player: player));
          socket.add(jsonEncode({'type': 'queued'}));
          return;
        }
        final opponent = waiting.removeAt(0);
        socket.add(
          jsonEncode({
            'type': 'matched',
            'matchId': 'test_match',
            'opponent': opponent.player,
          }),
        );
        opponent.socket.add(
          jsonEncode({
            'type': 'matched',
            'matchId': 'test_match',
            'opponent': player,
          }),
        );
      });
    });
    addTearDown(() async {
      await server.close(force: true);
      await serverTask;
    });

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

    expect(first.matchId, 'test_match');
    expect(first.opponent!.username, 'second');
    expect(second.opponent!.username, 'first');
  });
}

MultiplayerPlayerSnapshot _player(String id, String name) {
  final account = PlayerAccount(
    id: id,
    displayName: name,
    username: id,
    avatarColorValue: 0xFF5271FF,
    createdAt: DateTime.utc(2026, 8, 27),
  );
  return MultiplayerPlayerSnapshot.fromPlayer(
    account: account,
    team: const [
      ArenaFighter(animalId: 'chicken', mutationId: 'none', level: 1, power: 1),
      ArenaFighter(animalId: 'fox', mutationId: 'none', level: 1, power: 2),
      ArenaFighter(animalId: 'dragon', mutationId: 'none', level: 1, power: 3),
    ],
  );
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Expected multiplayer state was not reached.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
