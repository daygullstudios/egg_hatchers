import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/services/game_service.dart';
import 'package:egg_hatchers/widgets/game_primary_navigation.dart';
import 'package:egg_hatchers/widgets/phone_width_layout.dart';
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

  testWidgets('wide screens retain the centered phone-width navigation', (
    tester,
  ) async {
    await pumpNavigation(tester, size: const Size(1000, 800), onSelect: (_) {});

    final content = tester.getRect(
      find.byKey(GamePrimaryNavigation.contentKey),
    );
    expect(content.width, 430);
    expect(content.center.dx, 500);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Quests'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('app bar bottom content shares the phone-width boundary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MainGameShellScope(
          current: MainGameDestination.hatchery,
          game: game,
          onSelect: (_) {},
          onOpenSettings: () {},
          child: const Scaffold(
            appBar: PhoneWidthAppBar(
              title: 'Hatchery',
              backgroundColor: Colors.teal,
              bottom: GamePrimaryNavigation(
                theme: BackgroundThemes.hatcheryDefault,
                hostDestination: MainGameDestination.hatchery,
              ),
            ),
          ),
        ),
      ),
    );

    final boundary = tester.getRect(
      find.byKey(PhoneWidthAppBar.bottomContentKey),
    );
    expect(boundary.width, 430);
    expect(boundary.center.dx, 700);
  });
}
