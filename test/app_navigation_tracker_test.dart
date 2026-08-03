import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:egg_hatchers/navigation/app_page_route.dart';

void main() {
  testWidgets('popup routes keep the underlying page active', (tester) async {
    late BuildContext testContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final tracker = AppNavigationTracker.instance;
    final battleRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/manual-boss-battle'),
      builder: (_) => const SizedBox.shrink(),
    );
    final resultDialog = DialogRoute<void>(
      context: testContext,
      builder: (_) => const AlertDialog(title: Text('Battle Result')),
    );

    tracker.didPush(battleRoute, null);
    expect(tracker.topRouteName, '/manual-boss-battle');

    tracker.didPush(resultDialog, battleRoute);
    expect(tracker.topRouteName, '/manual-boss-battle');

    tracker.didPop(resultDialog, battleRoute);
    expect(tracker.topRouteName, '/manual-boss-battle');
  });
}
