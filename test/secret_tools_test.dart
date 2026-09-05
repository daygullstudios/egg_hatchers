import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('secret reward badge is one-time and protects chosen animal', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    final initialLifetime = game.lifetimeCoinsEarned;
    final initialCoins = game.coins;

    expect(game.secretRewardBadgeClaimed, isFalse);
    expect(game.canUseSecretRewardBadge, isFalse);

    game.devSetOwnedAnimalsForTesting([
      const OwnedAnimal(animalId: 'chicken', quantity: 1),
    ]);
    expect(game.canUseSecretRewardBadge, isFalse);

    game.devGrantSecretRewardBadge();
    expect(game.canUseSecretRewardBadge, isTrue);

    final name = game.applySecretRewardBadge(
      animalId: 'chicken',
      mutationId: 'none',
      isProtected: false,
    );
    expect(name, isNotNull);
    expect(game.secretRewardBadgeClaimed, isTrue);
    expect(game.hasSecretRewardAnimal, isTrue);
    expect(game.ownedAnimals.single.isProtected, isTrue);
    expect(game.ownedAnimals.single.isSecretReward, isTrue);
    expect(game.coins, initialCoins);
    expect(game.lifetimeCoinsEarned, initialLifetime);

    expect(
      game.applySecretRewardBadge(
        animalId: 'chicken',
        mutationId: 'none',
        isProtected: true,
      ),
      isNull,
    );

    game.dispose();
  });

  test('legacy protected secret void egg animals load as secret reward', () {
    final restored = PlayerState.fromJson({
      'coins': 100,
      'ownedAnimals': [
        {
          'animalId': 'void_mouse',
          'quantity': 1,
          'level': 1,
          'mutationId': 'none',
          'isProtected': true,
        },
      ],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 100,
      'secretSpaceEggClaimed': true,
    });

    expect(restored.secretSpaceEggClaimed, isTrue);
    expect(restored.ownedAnimals.single.isSecretReward, isTrue);
    expect(restored.ownedAnimals.single.isProtected, isTrue);
  });

  test('old coin-claim saves can still claim secret reward badge', () {
    final restored = PlayerState.fromJson({
      'coins': 100,
      'ownedAnimals': <dynamic>[],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 100,
      'secretToolsCoinsClaimed': true,
    });

    expect(restored.secretSpaceEggClaimed, isFalse);
  });

  test('secretSpaceEggClaimed defaults false for older saves', () {
    final restored = PlayerState.fromJson({
      'coins': 100,
      'ownedAnimals': <dynamic>[],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 100,
    });

    expect(restored.secretSpaceEggClaimed, isFalse);
    expect(restored.fullDeveloperToolsUnlocked, isFalse);
  });

  test('secretSpaceEggClaimed round-trips through json', () {
    final state = PlayerState.initial().copyWith(secretSpaceEggClaimed: true);
    final restored = PlayerState.fromJson(state.toJson());
    expect(restored.secretSpaceEggClaimed, isTrue);
  });

  test('secret discovery and Collector’s Vault round-trip through json', () {
    final state = PlayerState.initial().copyWith(
      secretHatcheryDiscovered: true,
      collectorsVaultUnlocked: true,
    );
    final restored = PlayerState.fromJson(state.toJson());

    expect(restored.secretHatcheryDiscovered, isTrue);
    expect(restored.collectorsVaultUnlocked, isTrue);
  });

  test('older completed collection saves unlock the Collector’s Vault', () {
    final restored = PlayerState.fromJson({
      'coins': 100,
      'ownedAnimals': <dynamic>[],
      'lastSavedTime': '2025-01-01T00:00:00.000',
      'lifetimeCoinsEarned': 100,
      'questProgress': {
        'claimedQuestIds': ['late_complete_collection'],
      },
    });

    expect(restored.collectorsVaultUnlocked, isTrue);
  });

  test(
    'fullDeveloperToolsUnlocked is ignored but loads safely from old saves',
    () {
      final restored = PlayerState.fromJson({
        'coins': 100,
        'ownedAnimals': <dynamic>[],
        'lastSavedTime': '2025-01-01T00:00:00.000',
        'lifetimeCoinsEarned': 100,
        'fullDeveloperToolsUnlocked': true,
      });

      expect(restored.fullDeveloperToolsUnlocked, isTrue);
      final roundTrip = PlayerState.fromJson(restored.toJson());
      expect(roundTrip.fullDeveloperToolsUnlocked, isTrue);
    },
  );
}
