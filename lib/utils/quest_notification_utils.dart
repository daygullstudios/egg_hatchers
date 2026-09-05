import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../screens/quests_screen.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../widgets/game_primary_navigation.dart';
import 'snackbar_utils.dart';

/// Shows a deferred or immediate pending quest completion notification.
void showPendingQuestCompletionNotification(
  BuildContext context, {
  required GameService game,
  required PreferencesService preferences,
}) {
  final message =
      game.releaseDeferredQuestNotification() ??
      game.consumePendingQuestNotification();
  if (message == null) return;

  showQuestCompletionSnackBar(
    context,
    message: message,
    backgroundColor: preferences.selectedTheme.secondaryColor,
    onViewQuests: () =>
        openQuestsScreen(context, game: game, preferences: preferences),
  );
}

/// Shows pending Egg Mastery level-up notifications after hatching.
void showPendingEggMasteryNotifications(
  BuildContext context, {
  required GameService game,
  required PreferencesService preferences,
}) {
  while (game.hasPendingMasteryNotifications) {
    final message = game.consumePendingMasteryNotification();
    if (message == null) break;
    showGameSnackBar(
      context,
      message: message,
      backgroundColor: preferences.selectedTheme.secondaryColor,
      duration: kGameSnackBarDurationImportant,
    );
  }
}

void showPendingHatchNotifications(
  BuildContext context, {
  required GameService game,
  required PreferencesService preferences,
}) {
  showPendingQuestCompletionNotification(
    context,
    game: game,
    preferences: preferences,
  );
  showPendingEggMasteryNotifications(
    context,
    game: game,
    preferences: preferences,
  );
}

void openQuestsScreen(
  BuildContext context, {
  required GameService game,
  required PreferencesService preferences,
}) {
  final shell = MainGameShellScope.maybeOf(context);
  if (shell != null) {
    shell.onSelect(MainGameDestination.quests);
    return;
  }

  if (isTopRouteNamed(kQuestsRouteName)) return;

  openWithThemedTransition(
    context,
    theme: preferences.selectedTheme,
    icon: '⭐',
    label: 'Opening Quests',
    settings: const RouteSettings(name: kQuestsRouteName),
    builder: (_) => QuestsScreen(game: game, preferences: preferences),
  );
}
