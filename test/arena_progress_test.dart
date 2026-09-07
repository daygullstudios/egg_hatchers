import 'package:egg_hatchers/models/arena.dart';
import 'package:egg_hatchers/models/multiplayer.dart';
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
      ..remove('arenaBestStreak')
      ..remove('onlineArenaRating')
      ..remove('onlineArenaWins')
      ..remove('onlineArenaLosses')
      ..remove('onlineArenaWinStreak')
      ..remove('onlineArenaBestStreak')
      ..remove('hostedSettlementReceipts');

    final restored = PlayerState.fromJson(initial);

    expect(restored.arenaRating, 1000);
    expect(restored.arenaWins, 0);
    expect(restored.arenaLosses, 0);
    expect(restored.arenaWinStreak, 0);
    expect(restored.onlineArenaRating, 1000);
    expect(restored.onlineArenaWins, 0);
    expect(restored.onlineArenaLosses, 0);
    expect(restored.onlineArenaWinStreak, 0);
    expect(restored.onlineArenaBestStreak, 0);
    expect(restored.hostedSettlementReceipts, isEmpty);
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

  test(
    'hosted settlements survive saves and cannot be applied twice',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();
      final startingCoins = game.coins;
      final settlement = MultiplayerSettlement(
        receiptId: 'match-1:player-1',
        matchId: 'match-1',
        won: true,
        ratingChange: 18,
        coins: 250,
        battleTokens: 1,
        serverRating: 1018,
      );

      expect(await game.applyHostedArenaSettlement(settlement), isTrue);
      expect(await game.applyHostedArenaSettlement(settlement), isTrue);
      expect(game.coins, startingCoins + 250);
      expect(game.battleTokens, 1);
      expect(game.onlineArenaRating, 1018);
      expect(game.onlineArenaWins, 1);
      expect(game.onlineArenaLosses, 0);
      expect(game.onlineArenaWinStreak, 1);
      expect(game.onlineArenaBestStreak, 1);
      expect(game.arenaRating, 1000);
      expect(game.arenaWins, 0);
      expect(game.arenaLosses, 0);
      expect(game.arenaWinStreak, 0);

      final restored = PlayerState.fromJson(game.state.toJson());
      expect(restored.hostedSettlementReceipts, ['match-1:player-1']);
    },
  );
}
