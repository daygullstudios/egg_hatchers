import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/models/quest.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/widgets/quest_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ready quest uses the contrasting primary action color', (
    tester,
  ) async {
    const theme = BackgroundThemes.hatcheryDefault;
    const quest = Quest(
      id: 'ready_test',
      category: QuestCategory.beginner,
      title: 'Ready Quest',
      description: 'Ready to claim.',
      rewardCoins: 100,
      metric: QuestMetric.totalEggsHatched,
      target: 0,
    );
    final game = GameService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestCard(
            quest: quest,
            game: game,
            theme: theme,
            onClaim: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Claim Reward'),
    );
    expect(
      button.style?.backgroundColor?.resolve(const <WidgetState>{}),
      theme.primaryColor,
    );
    game.dispose();
  });
}
