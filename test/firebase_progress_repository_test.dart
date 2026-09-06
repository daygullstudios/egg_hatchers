import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/services/firebase_progress_repository.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes a valid revisioned cloud progress document', () {
    final state = GameData.startingPlayerState().copyWith(coins: 875);
    final snapshot = FirebaseProgressRepository.decode({
      'format': 'egg_hatchers_cloud_progress',
      'schemaVersion': 1,
      'cloudRevision': 7,
      'savedAt': DateTime.utc(2026, 9, 5).toIso8601String(),
      'contentFingerprint': SaveService.contentFingerprint(state),
      'playerState': state.toJson(),
    });

    expect(snapshot, isNotNull);
    expect(snapshot!.state.coins, 875);
    expect(snapshot.cloudRevision, 7);
  });

  test('rejects cloud data whose fingerprint does not match progress', () {
    final state = GameData.startingPlayerState().copyWith(coins: 875);
    final snapshot = FirebaseProgressRepository.decode({
      'format': 'egg_hatchers_cloud_progress',
      'schemaVersion': 1,
      'cloudRevision': 7,
      'savedAt': DateTime.utc(2026, 9, 5).toIso8601String(),
      'contentFingerprint': List.filled(64, 'a').join(),
      'playerState': state.toJson(),
    });

    expect(snapshot, isNull);
  });
}
