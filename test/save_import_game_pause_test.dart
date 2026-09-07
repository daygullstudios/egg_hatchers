import 'dart:async';

import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'import pause drains pending saves, verifies final state and stops income/autosaves',
    (tester) async {
      final save = _DelayedSave();
      final game = GameService(saveService: save);
      addTearDown(game.dispose);
      await game.initialize();
      await tester.pump();
      save.gate = Completer<void>();
      final writing = game.save();
      var drained = false;
      final pausing = game.pauseForSaveImport().then((_) => drained = true);
      await tester.pump();
      expect(drained, false);
      expect(save.checked, 0);
      save.gate!.complete();
      await writing;
      await pausing;
      expect(save.checked, 1);
      final coins = game.coins, writes = save.writes;
      await tester.pump(const Duration(seconds: 10));
      await game.save();
      expect(game.coins, coins);
      expect(save.writes, writes);
      expect(
        await game.replaceProgressFromCloud(
          'other',
          GameData.startingPlayerState(),
        ),
        false,
      );
    },
  );
}

class _DelayedSave extends SaveService {
  Completer<void>? gate;
  var checked = 0, writes = 0;
  @override
  Future<PlayerState?> load() async => GameData.startingPlayerState().copyWith(
    ownedAnimals: [const OwnedAnimal(animalId: 'chicken', quantity: 1)],
    tutorialSkipped: true,
  );
  @override
  Future<void> save(PlayerState state) async {
    writes++;
    await gate?.future;
  }

  @override
  Future<void> saveForTransfer(PlayerState state) async {
    checked++;
  }
}
