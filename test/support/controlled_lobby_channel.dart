import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// A socket whose handshake and close acknowledgement are controlled by tests.
class ControlledLobbyChannel implements WebSocketChannel {
  final handshake = Completer<void>();
  final incoming = StreamController<dynamic>.broadcast(sync: true);
  @override
  final ControlledLobbySink sink = ControlledLobbySink();

  @override
  Future<void> get ready => handshake.future;
  @override
  Stream<dynamic> get stream => incoming.stream;

  void finish() {
    if (!handshake.isCompleted) handshake.complete();
    if (!sink.closed.isCompleted) sink.closed.complete();
    unawaited(incoming.close());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ControlledLobbySink implements WebSocketSink {
  final closed = Completer<void>();
  final messages = <dynamic>[];
  var closeCalls = 0;

  @override
  void add(dynamic data) => messages.add(data);
  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    closeCalls++;
    return closed.future;
  }

  @override
  Future<void> get done => closed.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
