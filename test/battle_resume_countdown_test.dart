import 'package:egg_hatchers/models/background_theme.dart';
import 'package:egg_hatchers/widgets/battle_resume_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resume countdown holds each number for one second', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleResumeCountdown(
            theme: BackgroundThemes.defaultTheme,
            reducedEffects: true,
            onComplete: () => completions++,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(completions, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    expect(completions, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    expect(completions, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(completions, 1);
  });

  testWidgets('removing the countdown cancels its completion', (tester) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BattleResumeCountdown(
          theme: BackgroundThemes.defaultTheme,
          onComplete: () => completions++,
        ),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 3));

    expect(completions, 0);
  });
}
