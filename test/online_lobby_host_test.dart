import 'package:egg_hatchers/models/online_lobby.dart';
import 'package:egg_hatchers/models/owned_animal.dart';
import 'package:egg_hatchers/models/player_account.dart';
import 'package:egg_hatchers/services/custom_sprite_service.dart';
import 'package:egg_hatchers/services/online_lobby_service.dart';
import 'package:egg_hatchers/widgets/online_lobby_host.dart';
import 'package:egg_hatchers/widgets/online_player_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('battle invitation is a compact bottom-left accept card', (
    tester,
  ) async {
    final lobby = _FakeOnlineLobbyService();
    addTearDown(lobby.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: OnlineLobbyHost(
          lobby: lobby,
          onSessionReady: (_) {},
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    lobby.showInvite();
    await tester.pump();

    expect(find.text('challenger wants to battle you'), findsOneWidget);
    expect(find.byKey(const ValueKey('accept-online-invite')), findsOneWidget);
    expect(find.byKey(const ValueKey('decline-online-invite')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('online player actions and animal viewer fit a narrow phone', (
    tester,
  ) async {
    final lobby = _FakeOnlineLobbyService();
    final sprites = CustomSpriteService();
    addTearDown(lobby.dispose);
    addTearDown(sprites.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OnlinePlayerList(
              players: [
                OnlinePlayerPresence(
                  account: PlayerAccount(
                    id: 'second',
                    displayName: 'Second Player',
                    username: 'second_player',
                    avatarColorValue: 0xFF5271FF,
                    createdAt: DateTime.utc(2026, 8, 27),
                  ),
                  rating: 1040,
                  team: const [],
                  animals: const [
                    OwnedAnimal(animalId: 'chicken', quantity: 2, level: 3),
                  ],
                ),
              ],
              activity: OnlineInviteKind.trade,
              lobby: lobby,
              customSprites: sprites,
            ),
          ),
        ),
      ),
    );

    expect(find.text('VIEW ANIMALS'), findsOneWidget);
    expect(find.text('TRADE'), findsOneWidget);
    await tester.tap(find.text('VIEW ANIMALS'));
    await tester.pumpAndSettle();
    expect(find.text("Second Player's Animals"), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeOnlineLobbyService extends OnlineLobbyService {
  OnlineInvite? _invite;

  @override
  OnlineInvite? get incomingInvite => _invite;

  void showInvite() {
    _invite = OnlineInvite(
      id: 'invite_1',
      kind: OnlineInviteKind.battle,
      from: PlayerAccount(
        id: 'challenger',
        displayName: 'Challenger',
        username: 'challenger',
        avatarColorValue: 0xFF5271FF,
        createdAt: DateTime.utc(2026, 8, 27),
      ),
    );
    notifyListeners();
  }
}
