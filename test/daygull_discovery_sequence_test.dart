import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/widgets/daygull_discovery_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DayGull discovery scrolls, flashes, and reveals the egg', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = GameService();
    await game.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: DayGullDiscoverySequence(
          game: game,
          theme: BackgroundThemes.hatcheryDefault,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Egg Shard Upgrades'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1800));
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));

    final glitch = find.byKey(const Key('daygull-glitch-tap'));
    expect(glitch, findsOneWidget);
    await tester.ensureVisible(glitch);
    await tester.tap(glitch);
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('DayGull Egg'), findsOneWidget);
    expect(find.text('A new path has opened.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
    game.dispose();
  });
}
