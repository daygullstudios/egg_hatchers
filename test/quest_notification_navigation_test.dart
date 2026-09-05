import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/services/preferences_service.dart';
import 'package:egg_hatchers/utils/quest_notification_utils.dart';
import 'package:egg_hatchers/widgets/game_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('quest notification selects the persistent shell destination', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameService();
    final preferences = PreferencesService();
    await preferences.initialize();
    MainGameDestination? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: MainGameShellScope(
          current: MainGameDestination.hatchery,
          game: game,
          onSelect: (destination) => selected = destination,
          onOpenSettings: () {},
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => openQuestsScreen(
                context,
                game: game,
                preferences: preferences,
              ),
              child: const Text('View Quests'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('View Quests'));
    await tester.pump();

    expect(selected, MainGameDestination.quests);
    expect(find.text('🎯 Quests'), findsNothing);
    game.dispose();
  });
}
