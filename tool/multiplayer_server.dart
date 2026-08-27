import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _host = '127.0.0.1';
const _port = 53218;

Future<void> main() async {
  final server = await HttpServer.bind(_host, _port);
  final matchmaker = _Matchmaker();
  stdout.writeln('Egg Hatchers match server: ws://$_host:$_port/ws');

  await for (final request in server) {
    if (request.uri.path == '/health') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({'status': 'ok', 'waiting': matchmaker.waitingCount}),
        );
      await request.response.close();
      continue;
    }
    if (request.uri.path != '/ws' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    matchmaker.attach(socket);
  }
}

class _Matchmaker {
  final List<_QueuedPlayer> _waiting = [];
  var _nextMatch = 1;

  int get waitingCount => _waiting.length;

  void attach(WebSocket socket) {
    socket.listen(
      (raw) => _handle(socket, raw),
      onDone: () => _remove(socket),
      onError: (_) => _remove(socket),
      cancelOnError: true,
    );
  }

  void _handle(WebSocket socket, dynamic raw) {
    if (raw is! String) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      switch (data['type']) {
        case 'queue':
          _queue(socket, Map<String, dynamic>.from(data['player'] as Map));
        case 'cancel':
          _remove(socket);
      }
    } catch (_) {
      _send(socket, {'type': 'error', 'message': 'Invalid match request.'});
    }
  }

  void _queue(WebSocket socket, Map<String, dynamic> player) {
    _remove(socket);
    final playerId = player['playerId'] as String?;
    if (playerId == null || (player['team'] as List?)?.length != 3) {
      _send(socket, {'type': 'error', 'message': 'A full team is required.'});
      return;
    }

    final opponentIndex = _waiting.indexWhere(
      (candidate) => candidate.player['playerId'] != playerId,
    );
    if (opponentIndex < 0) {
      _waiting.add(_QueuedPlayer(socket: socket, player: player));
      _send(socket, {'type': 'queued'});
      return;
    }

    final opponent = _waiting.removeAt(opponentIndex);
    final matchId =
        'local_match_${DateTime.now().microsecondsSinceEpoch}_${_nextMatch++}';
    _send(socket, {
      'type': 'matched',
      'matchId': matchId,
      'opponent': opponent.player,
    });
    _send(opponent.socket, {
      'type': 'matched',
      'matchId': matchId,
      'opponent': player,
    });
  }

  void _remove(WebSocket socket) {
    _waiting.removeWhere((entry) => identical(entry.socket, socket));
  }

  void _send(WebSocket socket, Map<String, dynamic> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }
}

class _QueuedPlayer {
  const _QueuedPlayer({required this.socket, required this.player});

  final WebSocket socket;
  final Map<String, dynamic> player;
}
