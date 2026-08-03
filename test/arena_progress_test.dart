import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('old saves receive default Arena progress', () {
    final initial = PlayerState.initial().toJson()
      ..remove('arenaRating')
      ..remove('arenaWins')
      ..remove('arenaLosses')
      ..remove('arenaWinStreak')
      ..remove('arenaBestStreak');

    final restored = PlayerState.fromJson(initial);

    expect(restored.arenaRating, 1000);
    expect(restored.arenaWins, 0);
    expect(restored.arenaLosses, 0);
    expect(restored.arenaWinStreak, 0);
  });

  test('Arena results update rewards, rating, and streak records', () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    await game.initialize();
    final startingCoins = game.coins;
    final startingTokens = game.battleTokens;

    game.applyArenaResult(
      won: true,
      reward: const ArenaReward(ratingChange: 22, coins: 500, battleTokens: 2),
    );

    expect(game.arenaRating, 1022);
    expect(game.arenaWins, 1);
    expect(game.arenaWinStreak, 1);
    expect(game.arenaBestStreak, 1);
    expect(game.coins, startingCoins + 500);
    expect(game.battleTokens, startingTokens + 2);

    game.applyArenaResult(
      won: false,
      reward: const ArenaReward(ratingChange: -10, coins: 0, battleTokens: 0),
    );

    expect(game.arenaRating, 1012);
    expect(game.arenaLosses, 1);
    expect(game.arenaWinStreak, 0);
    expect(game.arenaBestStreak, 1);
  });
}
