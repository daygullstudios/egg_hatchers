import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/player_state.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/utils/daily_system_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailySystemLogic', () {
    test('reward track rotates every 7 streak days', () {
      expect(DailySystemLogic.rewardForStreak(1).coins, 500);
      expect(DailySystemLogic.rewardForStreak(3).battleTokens, 5);
      expect(DailySystemLogic.rewardForStreak(7).coins, 10000);
      expect(DailySystemLogic.rewardForStreak(7).battleTokens, 15);
      expect(DailySystemLogic.rewardForStreak(8).coins, 500);
    });

    test('generates three random daily quests with unique groups', () {
      final quests = DailySystemLogic.generateDailyQuests('2026-06-05');
      expect(quests.length, DailySystemLogic.dailyQuestCount);

      final groups = quests.map((q) => q.group).whereType<String>().toSet();
      expect(groups.length, DailySystemLogic.dailyQuestCount);

      final ids = quests.map((q) => q.id).toSet();
      expect(ids.length, DailySystemLogic.dailyQuestCount);
    });

    test('same date generates the same daily quests', () {
      final first = DailySystemLogic.generateDailyQuests('2026-06-05');
      final second = DailySystemLogic.generateDailyQuests('2026-06-05');

      expect(first.map((q) => q.id).toList(), second.map((q) => q.id).toList());
    });

    test('different dates can generate different daily quests', () {
      final june5 = DailySystemLogic.generateDailyQuests('2026-06-05');
      final june6 = DailySystemLogic.generateDailyQuests('2026-06-06');

      expect(
        june5.map((q) => q.id).toList(),
        isNot(equals(june6.map((q) => q.id).toList())),
      );
    });

    test('reroll salt changes same-day quest selection', () {
      final stable = DailySystemLogic.generateDailyQuests('2026-06-05');
      final rerolled = DailySystemLogic.generateDailyQuests(
        '2026-06-05',
        rerollSalt: 12345,
      );

      expect(
        stable.map((q) => q.id).toList(),
        isNot(equals(rerolled.map((q) => q.id).toList())),
      );
    });
  });

  group('PlayerState daily persistence', () {
    test('old saves default daily fields safely', () {
      final restored = PlayerState.fromJson({
        'coins': 100,
        'ownedAnimals': [],
        'lastSavedTime': DateTime.now().toIso8601String(),
        'lifetimeCoinsEarned': 100,
      });

      expect(restored.lastDailyRewardClaimDate, isNull);
      expect(restored.dailyRewardStreak, 0);
      expect(restored.bestDailyRewardStreak, 0);
      expect(restored.dailyQuestDate, isNull);
      expect(restored.dailyQuests, isEmpty);
    });

    test('daily fields round-trip', () {
      final quests = DailySystemLogic.generateDailyQuests('2026-06-05');
      final state = PlayerState.initial().copyWith(
        lastDailyRewardClaimDate: '2026-06-05',
        dailyRewardStreak: 4,
        bestDailyRewardStreak: 6,
        dailyQuestDate: '2026-06-05',
        dailyQuests: quests,
      );
      final restored = PlayerState.fromJson(state.toJson());

      expect(restored.lastDailyRewardClaimDate, '2026-06-05');
      expect(restored.dailyRewardStreak, 4);
      expect(restored.bestDailyRewardStreak, 6);
      expect(restored.dailyQuestDate, '2026-06-05');
      expect(restored.dailyQuests.length, 3);
      expect(restored.dailyQuests.first.group, isNotNull);
    });

    test('legacy daily quests without group still load', () {
      final restored = PlayerState.fromJson({
        'coins': 100,
        'ownedAnimals': [],
        'lastSavedTime': DateTime.now().toIso8601String(),
        'lifetimeCoinsEarned': 100,
        'dailyQuestDate': DailySystemLogic.todayKey(),
        'dailyQuests': [
          {
            'id': 'daily_hatch_3',
            'type': DailySystemLogic.hatchEggsType,
            'title': 'Hatch 3 eggs',
            'target': 3,
            'progress': 1,
            'rewardCoins': 1000,
          },
        ],
      });

      expect(restored.dailyQuests.length, 1);
      expect(restored.dailyQuests.first.group, isNull);
      expect(restored.dailyQuests.first.progress, 1);
    });
  });

  group('GameService daily systems', () {
    test('claimDailyReward grants coins without lifetime earnings', () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();

      final lifetimeBefore = game.lifetimeCoinsEarned;
      expect(game.claimDailyReward(), isTrue);

      expect(game.hasClaimedDailyRewardToday, isTrue);
      expect(game.dailyRewardStreak, 1);
      expect(game.coins, greaterThan(250));
      expect(game.lifetimeCoinsEarned, lifetimeBefore);
      expect(game.claimDailyReward(), isFalse);
    });

    test(
      'shouldAutoShowDailyRewardPopup respects tutorial and dismiss',
      () async {
        SharedPreferences.setMockInitialValues({});
        final game = GameService();
        await game.initialize();

        expect(game.shouldAutoShowDailyRewardPopup, isFalse);

        game.completeTutorial();
        expect(game.shouldAutoShowDailyRewardPopup, isTrue);

        game.dismissDailyRewardPopup();
        expect(game.shouldAutoShowDailyRewardPopup, isFalse);

        game.resetDailyRewardPopupSessionGuard();
        expect(game.shouldAutoShowDailyRewardPopup, isFalse);

        game.devResetDailyRewardClaim();
        game.completeTutorial();
        expect(game.shouldAutoShowDailyRewardPopup, isTrue);
      },
    );

    test('daily quest progress increments on hatch count', () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();

      final hatchSalt = Iterable<int>.generate(100).firstWhere(
        (salt) => DailySystemLogic.generateDailyQuests(
          DailySystemLogic.todayKey(),
          rerollSalt: salt,
        ).any((q) => q.type == DailySystemLogic.hatchEggsType),
        orElse: () => throw StateError('No hatch quest reroll found'),
      );
      game.devRerollDailyQuests(rerollSalt: hatchSalt);
      final hatchQuest = game.dailyQuests.firstWhere(
        (q) => q.type == DailySystemLogic.hatchEggsType,
      );
      expect(hatchQuest.progress, 0);

      game.hatchEgg(GameData.eggs.first);
      final updated = game.dailyQuests.firstWhere((q) => q.id == hatchQuest.id);
      expect(updated.progress, 1);
    });

    test('dev reroll changes active daily quests for today', () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.initialize();

      final before = game.dailyQuests.map((q) => q.id).toList();
      game.devRerollDailyQuests();
      final after = game.dailyQuests.map((q) => q.id).toList();

      expect(after.length, DailySystemLogic.dailyQuestCount);
      expect(after, isNot(equals(before)));
    });
  });
}
