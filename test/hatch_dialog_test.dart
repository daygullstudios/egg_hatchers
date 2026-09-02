import 'package:egg_hatchers/data/game_data.dart';
import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/models/hatch_result.dart';
import 'package:egg_hatchers/widgets/hatch_dialog.dart';
import 'package:egg_hatchers/widgets/multi_hatch_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final egg = GameData.eggs.first;
  final normalMutation = GameData.mutations.firstWhere((m) => m.isNormal);
  final animals = GameData.animals.take(3).toList();

  Widget app(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('single hatch can skip directly to its reward', (tester) async {
    await tester.pumpWidget(
      app(
        HatchDialog(
          egg: egg,
          result: HatchResult(animal: animals.first, mutation: normalMutation),
          theme: BackgroundThemes.defaultTheme,
          initialDelay: const Duration(milliseconds: 10),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('skip-single-hatch-animation')));
    await tester.pump();

    expect(find.text('It hatched!'), findsOneWidget);
    expect(find.text('Awesome!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('skip-single-hatch-animation')),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('triple hatch can skip directly to all rewards', (tester) async {
    final results = [
      for (final animal in animals)
        HatchResult(animal: animal, mutation: normalMutation),
    ];

    await tester.pumpWidget(
      app(
        MultiHatchDialog(
          egg: egg,
          results: results,
          theme: BackgroundThemes.defaultTheme,
          initialDelay: const Duration(milliseconds: 10),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('skip-triple-hatch-animation')));
    await tester.pump();

    expect(find.text('You hatched 3 animals!'), findsOneWidget);
    expect(find.text('Awesome!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('skip-triple-hatch-animation')),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });
}
