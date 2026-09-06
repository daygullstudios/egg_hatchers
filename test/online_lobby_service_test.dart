import 'dart:async';
import 'dart:io';

import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/models/online_trade.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/multiplayer_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/services/trading_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/multiplayer_server.dart';
import 'support/controlled_lobby_channel.dart';

void main() {
  test(
    'synchronous socket creation failure leaves the lobby unavailable',
    () async {
      final lobby = OnlineLobbyService(
        channelFactory: (_) => throw StateError('unavailable'),
      );
      await lobby.connect(_presence('first', 'First'));
      expect(lobby.state, OnlineLobbyConnectionState.disconnected);
      expect(lobby.statusMessage, 'Online lobby is unavailable.');
      lobby.dispose();
    },
  );

  test(
    'disconnect finishes without a handshake or close acknowledgement',
    () async {
      final channel = ControlledLobbyChannel();
      final lobby = OnlineLobbyService(channelFactory: (_) => channel);
      final connecting = lobby.connect(_presence('first', 'First'));
      await lobby.disconnect().timeout(const Duration(milliseconds: 100));
      expect(lobby.state, OnlineLobbyConnectionState.disconnected);
      expect(channel.sink.closeCalls, 1);
      expect(channel.sink.closed.isCompleted, isFalse);
      channel.finish();
      await connecting;
      expect(lobby.state, OnlineLobbyConnectionState.disconnected);
      expect(channel.sink.messages, isEmpty);
      lobby.dispose();
    },
  );

  for (final failOldHandshake in [false, true]) {
    test(
      'retired handshake cannot change the new session ($failOldHandshake)',
      () async {
        final old = ControlledLobbyChannel();
        final current = ControlledLobbyChannel();
        var calls = 0;
        final lobby = OnlineLobbyService(
          channelFactory: (_) => calls++ == 0 ? old : current,
        );
        final oldConnect = lobby.connect(_presence('old', 'Old'));
        await lobby.disconnect();
        final newConnect = lobby.connect(_presence('current', 'Current'));
        current.handshake.complete();
        await newConnect;
        if (failOldHandshake) {
          old.handshake.completeError(StateError('retired handshake failed'));
        } else {
          old.handshake.complete();
        }
        old.incoming.add('{"type":"lobbyError","message":"stale"}');
        old.sink.closed.completeError(StateError('retired close failed'));
        await oldConnect;
        expect(lobby.state, OnlineLobbyConnectionState.online);
        expect(lobby.statusMessage, isNull);
        expect(current.sink.closeCalls, 0);
        expect(current.sink.messages.single, contains('current'));
        lobby.dispose();
        old.finish();
        current.finish();
      },
    );
  }

  test(
    'handshake queues only the latest presence and handles both failure signals',
    () async {
      final channel = ControlledLobbyChannel();
      final lobby = OnlineLobbyService(channelFactory: (_) => channel);
      final connecting = lobby.connect(_presence('first', 'First'));
      lobby.updatePresence(_presence('second', 'Second'));
      expect(channel.sink.messages, isEmpty);
      channel.handshake.complete();
      await connecting;
      expect(channel.sink.messages, hasLength(1));
      expect(channel.sink.messages.single, contains('second'));
      channel.incoming.addError(StateError('connection lost'));
      expect(lobby.state, OnlineLobbyConnectionState.disconnected);
      expect(lobby.incomingInvite, isNull);
      expect(lobby.sessionLaunch, isNull);
      lobby.dispose();
      channel.finish();
    },
  );

  test(
    'failed current handshake completes even if cleanup never completes',
    () async {
      final channel = ControlledLobbyChannel();
      final lobby = OnlineLobbyService(channelFactory: (_) => channel);
      final connecting = lobby.connect(_presence('first', 'First'));
      channel.handshake.completeError(StateError('offline'));
      channel.incoming.addError(StateError('offline stream'));
      await connecting.timeout(const Duration(milliseconds: 100));
      expect(lobby.state, OnlineLobbyConnectionState.disconnected);
      expect(channel.sink.closed.isCompleted, isFalse);
      lobby.dispose();
      channel.finish();
    },
  );

  test(
    'online roster supports messages, decline, and invited battle',
    () async {
      final server = await _startServer();
      addTearDown(server.close);
      final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
      final first = OnlineLobbyService(serverUri: uri);
      final second = OnlineLobbyService(serverUri: uri);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final firstPresence = _presence('first', 'First Player');
      final secondPresence = _presence('second', 'Second Player');
      await Future.wait([
        first.connect(firstPresence),
        second.connect(secondPresence),
      ]);

      await _waitFor(
        () => first.players.length == 1 && second.players.length == 1,
      );
      expect(first.players.single.account.username, 'second');
      expect(first.players.single.animals.single.animalId, 'chicken');

      first.sendPresetMessage('second', 'good_luck');
      await _waitFor(() => second.latestMessage?.tag == 'good_luck');
      expect(second.latestMessage!.from.username, 'first');

      first.invite('second', OnlineInviteKind.battle);
      await _waitFor(() => second.incomingInvite != null);
      second.respondToInvite(false);
      await _waitFor(() => first.statusMessage?.contains('declined') ?? false);

      first.invite('second', OnlineInviteKind.battle);
      await _waitFor(() => second.incomingInvite != null);
      second.respondToInvite(true);
      await _waitFor(
        () => first.sessionLaunch != null && second.sessionLaunch != null,
      );
      expect(first.sessionLaunch!.roomId, second.sessionLaunch!.roomId);
      expect(first.sessionLaunch!.kind, OnlineInviteKind.battle);

      final firstBattle = MultiplayerService(serverUri: uri);
      final secondBattle = MultiplayerService(serverUri: uri);
      addTearDown(firstBattle.dispose);
      addTearDown(secondBattle.dispose);
      await Future.wait([firstBattle.connect(), secondBattle.connect()]);
      firstBattle.joinInvitedMatch(
        first.sessionLaunch!.roomId,
        _battlePlayer(firstPresence),
      );
      secondBattle.joinInvitedMatch(
        second.sessionLaunch!.roomId,
        _battlePlayer(secondPresence),
      );
      await _waitFor(
        () =>
            firstBattle.state == MultiplayerConnectionState.matched &&
            secondBattle.state == MultiplayerConnectionState.matched,
      );
      expect(firstBattle.matchId, secondBattle.matchId);
      expect(firstBattle.opponent!.username, 'second');
    },
  );

  test('accepted trade invite opens a private confirmed trade', () async {
    final server = await _startServer();
    addTearDown(server.close);
    final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
    final first = OnlineLobbyService(serverUri: uri);
    final second = OnlineLobbyService(serverUri: uri);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final firstPresence = _presence('first', 'First Trader');
    final secondPresence = _presence(
      'second',
      'Second Trader',
      animal: const OwnedAnimal(
        animalId: 'fox',
        mutationId: 'golden',
        quantity: 1,
        level: 4,
      ),
    );
    await Future.wait([
      first.connect(firstPresence),
      second.connect(secondPresence),
    ]);
    await _waitFor(() => first.players.length == 1);

    first.invite('missing-player', OnlineInviteKind.trade);
    await _waitFor(() => first.notice?.message == 'Trade Failed');
    expect(first.notice!.type, OnlineNoticeType.failure);
    first.clearNotice();

    first.invite('second', OnlineInviteKind.trade);
    await _waitFor(() => second.incomingInvite != null);
    await _waitFor(
      () => first.notice?.message == 'Trade sent to @second successfully',
    );
    expect(first.notice!.type, OnlineNoticeType.success);
    second.respondToInvite(false);
    await _waitFor(() => first.notice?.message == '@second declined the trade');
    expect(first.notice!.type, OnlineNoticeType.failure);

    first.invite('second', OnlineInviteKind.trade);
    await _waitFor(() => second.incomingInvite != null);
    second.respondToInvite(true);
    await _waitFor(
      () => first.sessionLaunch != null && second.sessionLaunch != null,
    );

    final firstTrade = TradingService(serverUri: uri);
    final secondTrade = TradingService(serverUri: uri);
    addTearDown(firstTrade.dispose);
    addTearDown(secondTrade.dispose);
    await Future.wait([firstTrade.connect(), secondTrade.connect()]);
    firstTrade.joinInvitedTrade(
      first.sessionLaunch!.roomId,
      OnlineTraderSnapshot(
        account: firstPresence.account,
        inventory: firstPresence.animals,
      ),
    );
    secondTrade.joinInvitedTrade(
      second.sessionLaunch!.roomId,
      OnlineTraderSnapshot(
        account: secondPresence.account,
        inventory: secondPresence.animals,
      ),
    );
    await _waitFor(
      () =>
          firstTrade.state == TradingConnectionState.trading &&
          secondTrade.state == TradingConnectionState.trading,
    );
    firstTrade.offer(firstPresence.animals.single);
    secondTrade.offer(secondPresence.animals.single);
    await _waitFor(
      () =>
          firstTrade.trade?.opponentOffer != null &&
          secondTrade.trade?.opponentOffer != null,
    );
    firstTrade.confirm();
    secondTrade.confirm();
    await _waitFor(
      () => firstTrade.completion != null && secondTrade.completion != null,
    );
    expect(firstTrade.completion!.received.animalId, 'fox');
    expect(secondTrade.completion!.received.animalId, 'chicken');
  });
}

Future<LocalMultiplayerServer> _startServer() async {
  final webRoot = await Directory.systemTemp.createTemp('egg_lobby_web_');
  addTearDown(() => webRoot.delete(recursive: true));
  return LocalMultiplayerServer.start(port: 0, webRoot: webRoot.path);
}

OnlinePresenceSnapshot _presence(
  String id,
  String name, {
  OwnedAnimal animal = const OwnedAnimal(
    animalId: 'chicken',
    quantity: 2,
    level: 3,
  ),
}) {
  final account = PlayerAccount(
    id: id,
    displayName: name,
    username: id,
    avatarColorValue: 0xFF5271FF,
    createdAt: DateTime.utc(2026, 8, 27),
  );
  return OnlinePresenceSnapshot(
    account: account,
    rating: 1000,
    team: const [
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
        power: 2,
      ),
      MultiplayerFighterSnapshot(
        animalId: 'dragon',
        mutationId: 'none',
        level: 1,
        power: 3,
      ),
    ],
    animals: [animal],
  );
}

MultiplayerPlayerSnapshot _battlePlayer(OnlinePresenceSnapshot presence) =>
    MultiplayerPlayerSnapshot.fromPlayer(
      account: presence.account,
      rating: presence.rating,
      team: presence.team
          .map(
            (fighter) => ArenaFighter(
              animalId: fighter.animalId,
              mutationId: fighter.mutationId,
              level: fighter.level,
              power: fighter.power,
            ),
          )
          .toList(growable: false),
    );

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Expected online lobby state was not reached.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
