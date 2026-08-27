import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'online trade swaps one ordinary animal and preserves protected ones',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();
      game.devSetOwnedAnimalsForTesting(const [
        OwnedAnimal(animalId: 'chicken', quantity: 2, level: 3),
        OwnedAnimal(animalId: 'dragon', quantity: 1, isProtected: true),
      ]);

      expect(game.tradableAnimals.map((animal) => animal.animalId), [
        'chicken',
      ]);
      final applied = game.applyOnlineTrade(
        sent: const OwnedAnimal(animalId: 'chicken', quantity: 1, level: 3),
        received: const OwnedAnimal(
          animalId: 'fox',
          quantity: 1,
          level: 4,
          mutationId: 'golden',
        ),
      );

      expect(applied, isTrue);
      expect(
        game.ownedAnimals
            .singleWhere((animal) => animal.animalId == 'chicken')
            .quantity,
        1,
      );
      expect(
        game.ownedAnimals
            .singleWhere((animal) => animal.animalId == 'fox')
            .mutationId,
        'golden',
      );
      expect(
        game.ownedAnimals
            .singleWhere((animal) => animal.animalId == 'dragon')
            .isProtected,
        isTrue,
      );
      game.dispose();
    },
  );
}
