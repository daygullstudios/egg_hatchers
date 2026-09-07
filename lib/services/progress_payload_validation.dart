import '../models/player_state.dart';

/// Validate stored shapes before forgiving legacy model migrations can drop
/// malformed containers. Missing historical optional fields remain supported.
PlayerState parseProgressPayload(Map<String, dynamic> raw) {
  for (final name in [
    'bossWins',
    'hardPhaseWins',
    'nightmareWins',
    'eggMastery',
    'questProgress',
  ]) {
    if (raw[name] != null && raw[name] is! Map<String, dynamic>) {
      throw const FormatException('Progress container');
    }
  }
  if (raw['dailyQuests'] != null && raw['dailyQuests'] is! List ||
      raw['activeAutoBattle'] != null && raw['activeAutoBattle'] is! Map) {
    throw const FormatException('Progress container');
  }
  if (raw['eggMastery'] case final Map mastery) {
    if (mastery.values.any((value) => value is! Map<String, dynamic>)) {
      throw const FormatException('Mastery entry');
    }
  }
  final state = PlayerState.fromJson(raw);
  _checkShapes(raw, state.toJson());
  for (final animal in state.ownedAnimals) {
    if (animal.animalId.trim().isEmpty ||
        animal.quantity < 1 ||
        animal.level < 1) {
      throw const FormatException('Animal entry');
    }
  }
  if (state.coins < 0 ||
      state.lifetimeCoinsEarned < 0 ||
      state.luckLevel < 1 ||
      state.rebirthLevel < 0) {
    throw const FormatException('Progress totals');
  }
  return state;
}

void _checkShapes(Object? raw, Object? parsed) {
  if (raw == null || parsed == null) return;
  if (parsed is bool && raw is! bool ||
      parsed is String && raw is! String ||
      parsed is num && (raw is! num || !raw.isFinite || raw < 0)) {
    throw const FormatException('Progress field');
  }
  if (parsed is List) {
    if (raw is! List || raw.length != parsed.length) {
      throw const FormatException('Progress list');
    }
    for (var i = 0; i < raw.length; i++) {
      _checkShapes(raw[i], parsed[i]);
    }
  } else if (parsed is Map) {
    if (raw is! Map) throw const FormatException('Progress map');
    for (final key in raw.keys) {
      if (parsed.containsKey(key)) _checkShapes(raw[key], parsed[key]);
    }
  }
}
