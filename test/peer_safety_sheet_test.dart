import 'package:egg_hatchers/models/peer_safety.dart';
import 'package:egg_hatchers/widgets/peer_safety_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preset player report remains usable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PeerReportReason? selectedReason;
    bool? selectedBlock;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showPeerSafetySheet(
                  context: context,
                  opponentName: 'Player A1B2C3',
                  onReport: (reason, {required block}) {
                    selectedReason = reason;
                    selectedBlock = block;
                  },
                  onBlock: () {},
                ),
                child: const Text('OPEN SAFETY'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN SAFETY'));
    await tester.pumpAndSettle();
    expect(find.text('Player safety'), findsOneWidget);
    expect(find.textContaining('no message or personal information'), findsOne);

    await tester.tap(
      find.byKey(const ValueKey('peer-report-suspected_cheating')),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-peer-report')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit-peer-report')));
    await tester.pumpAndSettle();

    expect(selectedReason, PeerReportReason.suspectedCheating);
    expect(selectedBlock, isTrue);
    expect(find.text('Player safety'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
