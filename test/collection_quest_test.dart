import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egg_hatchers/data/quest_data.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/models/quest.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/collection_quest_logic.dart';
import 'package:egg_hatchers/utils/quest_logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Quest collectionQuest() =>
      QuestData.all.firstWhere((q) => q.id == 'late_complete_collection');

  test('collection quest target matches total base animals', () {
    expect(collectionQuest().target, CollectionQuestLogic.totalBaseAnimalCount);
    expect(collectionQuest().target, 48);
  });

  test('mutation variants count toward base animal collection', () {
    final state = PlayerState.initial().copyWith(
      ownedAnimals: const [
        OwnedAnimal(animalId: 'chicken', quantity: 1, mutationId: 'golden'),
        OwnedAnimal(animalId: 'mouse', quantity: 2, mutationId: 'rainbow'),
      ],
    );

    expect(CollectionQuestLogic.collectedBaseAnimalCount(state), 2);
    expect(
      QuestLogic.progressText(collectionQuest(), state),
      'Collected 2 / ${collectionQuest().target} animals',
    );
  });

  test('collection quest completes when every base animal is owned', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    game.devCollectAllAnimals();

    final quest = collectionQuest();
    expect(QuestLogic.isComplete(quest, game.state), isTrue);
    expect(QuestLogic.status(quest, game.state), QuestStatus.readyToClaim);
  });

  test('claiming collection quest grants no coins and marks claimed', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    final beforeCoins = game.coins;
    final beforeLifetime = game.lifetimeCoinsEarned;

    game.devCollectAllAnimals();
    final quest = collectionQuest();
    final reward = game.claimQuest(quest.id);

    expect(reward?.coins, 0);
    expect(reward?.collectorsVaultUnlocked, isTrue);
    expect(game.coins, beforeCoins);
    expect(game.lifetimeCoinsEarned, beforeLifetime);
    expect(game.collectorsVaultUnlocked, isTrue);
    expect(game.questProgress.isQuestClaimed(quest.id), isTrue);
    expect(game.claimQuest(quest.id), isNull);
  });

  test('collection quest notification uses late game label', () {
    final quest = collectionQuest();
    expect(
      QuestLogic.completionNotificationMessage([quest]),
      '👑 Late Game Quest Complete! Claim your reward.',
    );
  });
}
