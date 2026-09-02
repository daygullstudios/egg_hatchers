import 'dart:convert';

/// Decodes a WebSocket payload only when it is a JSON object.
Map<String, dynamic>? decodeWebSocketMessage(dynamic raw) {
  if (raw is! String) return null;

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}
