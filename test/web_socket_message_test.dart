import 'package:egg_hatchers/utils/web_socket_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes JSON object messages', () {
    expect(decodeWebSocketMessage('{"type":"ready","count":2}'), {
      'type': 'ready',
      'count': 2,
    });
  });

  test('ignores malformed and non-object messages', () {
    expect(decodeWebSocketMessage('{broken'), isNull);
    expect(decodeWebSocketMessage('["ready"]'), isNull);
    expect(decodeWebSocketMessage(42), isNull);
  });
}
