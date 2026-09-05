import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/widgets/game_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameService game;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    game = GameService();
    await game.initialize();
  });

  tearDown(() => game.dispose());

  Future<void> pumpNavigation(
    WidgetTester tester, {
    required Size size,
    required ValueChanged<MainGameDestination> onSelect,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MainGameShellScope(
          current: MainGameDestination.hatchery,
          game: game,
          onSelect: onSelect,
          onOpenSettings: () {},
          child: const Scaffold(
            body: GamePrimaryNavigation(
              theme: BackgroundThemes.hatcheryDefault,
              hostDestination: MainGameDestination.hatchery,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('mobile navigation keeps four core destinations and More', (
    tester,
  ) async {
    MainGameDestination? selected;
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      onSelect: (value) => selected = value,
    );

    expect(find.text('Hatchery'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Battles'), findsOneWidget);
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Quests'), findsNothing);

    await tester.tap(find.text('Shop'));
    expect(selected, MainGameDestination.shop);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Quests'), findsOneWidget);
    expect(find.text('Custom Animals'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('desktop navigation exposes all destinations directly', (
    tester,
  ) async {
    await pumpNavigation(tester, size: const Size(1000, 800), onSelect: (_) {});

    expect(find.text('Quests'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('More'), findsNothing);
  });
}
