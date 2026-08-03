import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../theme/game_theme.dart';
import '../utils/ui_sound.dart';
import '../widgets/app_theme_background.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/themed_route_transition_screen.dart';

const Duration kAppRouteForwardDuration = Duration(milliseconds: 300);
const Duration kAppRouteReverseDuration = Duration(milliseconds: 250);

/// Opaque route with a stable backdrop and animated phone-width panel only.
Route<T> appPageRoute<T>({
  required WidgetBuilder builder,
  required Color backgroundColor,
  BackgroundTheme? backgroundTheme,
  RouteSettings? settings,
  bool instantTransition = false,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    opaque: true,
    transitionDuration: instantTransition
        ? Duration.zero
        : kAppRouteForwardDuration,
    reverseTransitionDuration: instantTransition
        ? Duration.zero
        : kAppRouteReverseDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final panel = AppRoutePhonePanel(
        maxWidth: kPhoneMaxContentWidth,
        child: child,
      );

      if (instantTransition) {
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            StableRouteBackdrop(
              theme: backgroundTheme,
              color: backgroundTheme == null ? backgroundColor : null,
            ),
            panel,
          ],
        );
      }

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0.14, 0),
        end: Offset.zero,
      ).animate(curved);

      final fade = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
      );

      final scale = Tween<double>(begin: 0.985, end: 1.0).animate(fade);

      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          StableRouteBackdrop(
            theme: backgroundTheme,
            color: backgroundTheme == null ? backgroundColor : null,
          ),
          AppRoutePhonePanel(
            maxWidth: kPhoneMaxContentWidth,
            child: SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Pushes a screen with the app's standard transition and background color.
Future<T?> pushAppRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required Color backgroundColor,
  BackgroundTheme? backgroundTheme,
  RouteSettings? settings,
  bool instantTransition = false,
}) {
  UiSound.click(context);
  return Navigator.of(context).push<T>(
    appPageRoute<T>(
      builder: builder,
      backgroundColor: backgroundColor,
      backgroundTheme: backgroundTheme,
      settings: settings,
      instantTransition: instantTransition,
    ),
  );
}

/// Pushes a screen using the selected background theme's gradient backdrop.
Future<T?> pushThemedAppRoute<T>(
  BuildContext context, {
  required BackgroundTheme theme,
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool instantTransition = false,
}) {
  return pushAppRoute<T>(
    context,
    builder: builder,
    backgroundColor: theme.scaffoldColor,
    backgroundTheme: theme,
    settings: settings,
    instantTransition: instantTransition,
  );
}

const Duration kMainThemedPreNavDuration = Duration(milliseconds: 620);
const Duration kEditorThemedPreNavDuration = Duration(milliseconds: 580);
const Duration kReturnToHatcheryPreNavDuration = Duration(milliseconds: 550);

const String kHatcheryRouteName = '/';
const String kShopRouteName = '/shop';
const String kCollectionRouteName = '/collection';
const String kQuestsRouteName = '/quests';
const String kBattlesRouteName = '/battles';
const String kCustomSpritesRouteName = '/custom-sprites';
const String kSecretToolsRouteName = '/secret-tools';
const String kSettingsRouteName = '/settings';

/// Tracks the navigator's top page route name for duplicate-route guards.
/// Popup routes such as dialogs and bottom sheets do not change the active
/// screen beneath them.
class AppNavigationTracker extends NavigatorObserver {
  AppNavigationTracker._();
  static final AppNavigationTracker instance = AppNavigationTracker._();

  String? topRouteName;
  final List<VoidCallback> _routeListeners = [];

  void addRouteListener(VoidCallback listener) {
    if (!_routeListeners.contains(listener)) {
      _routeListeners.add(listener);
    }
  }

  void removeRouteListener(VoidCallback listener) {
    _routeListeners.remove(listener);
  }

  void _notifyRouteListeners() {
    for (final listener in List<VoidCallback>.from(_routeListeners)) {
      listener();
    }
  }

  void _syncTop(Route<dynamic>? route) {
    topRouteName = route?.settings.name;
    _notifyRouteListeners();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) return;
    _syncTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) return;
    _syncTop(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) return;
    _syncTop(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is PopupRoute<dynamic>) return;
    _syncTop(newRoute);
  }
}

bool isTopRouteNamed(String? name) {
  return name != null && AppNavigationTracker.instance.topRouteName == name;
}

/// Pre-navigation transition screen, then destination via pushReplacement.
Future<T?> openWithThemedTransition<T>(
  BuildContext context, {
  required BackgroundTheme theme,
  required WidgetBuilder builder,
  required String label,
  required String icon,
  Duration duration = kMainThemedPreNavDuration,
  RouteSettings? settings,
}) {
  UiSound.click(context);
  return Navigator.of(context).push<T>(
    appPageRoute<T>(
      settings: settings,
      backgroundColor: theme.scaffoldColor,
      backgroundTheme: theme,
      instantTransition: true,
      builder: (transitionContext) {
        return ThemedRouteTransitionScreen(
          theme: theme,
          icon: icon,
          label: label,
          duration: duration,
          onComplete: () {
            if (!transitionContext.mounted) return;
            Navigator.of(transitionContext).pushReplacement<T, void>(
              appPageRoute<T>(
                builder: builder,
                backgroundColor: theme.scaffoldColor,
                backgroundTheme: theme,
                settings: settings,
              ),
            );
          },
        );
      },
    ),
  );
}

/// Hatchery -> Shop: pre-navigation transition screen, then Shop.
Future<T?> openShopWithTransition<T>(
  BuildContext context, {
  required BackgroundTheme theme,
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return openWithThemedTransition<T>(
    context,
    theme: theme,
    builder: builder,
    label: 'Opening Shop',
    icon: '🛒',
    duration: kShopPreNavTransitionDuration,
    settings: settings ?? const RouteSettings(name: kShopRouteName),
  );
}

/// Hatchery -> Battles: pre-navigation transition screen, then Battles.
Future<T?> openBattlesWithTransition<T>(
  BuildContext context, {
  required BackgroundTheme theme,
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return openWithThemedTransition<T>(
    context,
    theme: theme,
    builder: builder,
    label: 'Opening Battles',
    icon: '⚔️',
    settings: settings ?? const RouteSettings(name: kBattlesRouteName),
  );
}

/// Hatchery -> Secret Tools: pre-navigation transition screen, then destination.
Future<T?> openSecretToolsWithTransition<T>(
  BuildContext context, {
  required BackgroundTheme theme,
  required WidgetBuilder builder,
}) {
  return openWithThemedTransition<T>(
    context,
    theme: theme,
    builder: builder,
    label: 'Opening Secret',
    icon: '🔐',
    settings: const RouteSettings(name: kSecretToolsRouteName),
  );
}

/// Shows a return cue, then pops back to Hatchery without leaving the cue on stack.
Future<void> returnToHatcheryWithTransition(
  BuildContext context, {
  required BackgroundTheme theme,
}) {
  return returnToRouteWithTransition(
    context,
    theme: theme,
    label: 'Returning to Hatchery',
    icon: '🏠',
    stopAtRouteName: null,
    popUntilFirst: true,
    duration: kReturnToHatcheryPreNavDuration,
  );
}

/// Shows a return cue, then pops until a named route (or first route) is on top.
Future<void> returnToRouteWithTransition(
  BuildContext context, {
  required BackgroundTheme theme,
  required String label,
  required String icon,
  String? stopAtRouteName,
  bool popUntilFirst = false,
  Duration duration = kReturnToHatcheryPreNavDuration,
}) {
  UiSound.click(context);
  final navigator = Navigator.of(context);
  if (!navigator.canPop()) return Future.value();

  return navigator.push<void>(
    appPageRoute<void>(
      backgroundColor: theme.scaffoldColor,
      backgroundTheme: theme,
      instantTransition: true,
      builder: (transitionContext) {
        return ThemedRouteTransitionScreen(
          theme: theme,
          icon: icon,
          label: label,
          duration: duration,
          onComplete: () {
            if (!transitionContext.mounted) return;
            Navigator.of(transitionContext).popUntil((route) {
              if (popUntilFirst) return route.isFirst;
              if (route.settings.name == stopAtRouteName) return true;
              return route.isFirst;
            });
          },
        );
      },
    ),
  );
}

/// Sprite Editor -> Custom Sprites list with a short return cue.
Future<void> returnToCustomSpritesWithTransition(
  BuildContext context, {
  required BackgroundTheme theme,
}) {
  return returnToRouteWithTransition(
    context,
    theme: theme,
    label: 'Returning to Custom Animals',
    icon: '✏️',
    stopAtRouteName: kCustomSpritesRouteName,
  );
}

/// Back button that plays the return-to-Hatchery transition cue.
class ReturnToHatcheryBackButton extends StatelessWidget {
  const ReturnToHatcheryBackButton({
    super.key,
    required this.theme,
    this.color,
    this.tutorialKey,
  });

  final BackgroundTheme theme;
  final Color? color;
  final Key? tutorialKey;

  @override
  Widget build(BuildContext context) {
    final button = BackButton(
      color: color,
      onPressed: () => returnToHatcheryWithTransition(context, theme: theme),
    );
    if (tutorialKey == null) return button;
    return KeyedSubtree(key: tutorialKey, child: button);
  }
}

/// Intercepts system back and routes through [returnToHatcheryWithTransition].
class ReturnToHatcheryPopScope extends StatelessWidget {
  const ReturnToHatcheryPopScope({
    super.key,
    required this.theme,
    required this.child,
  });

  final BackgroundTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        returnToHatcheryWithTransition(context, theme: theme);
      },
      child: child,
    );
  }
}

/// Back button that returns to the Custom Sprites list with a transition cue.
class ReturnToCustomSpritesBackButton extends StatelessWidget {
  const ReturnToCustomSpritesBackButton({
    super.key,
    required this.theme,
    this.color,
  });

  final BackgroundTheme theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return BackButton(
      color: color,
      onPressed: () {
        UiSound.click(context);
        returnToCustomSpritesWithTransition(context, theme: theme);
      },
    );
  }
}

/// Intercepts system back and routes through [returnToCustomSpritesWithTransition].
class ReturnToCustomSpritesPopScope extends StatelessWidget {
  const ReturnToCustomSpritesPopScope({
    super.key,
    required this.theme,
    required this.child,
  });

  final BackgroundTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        returnToCustomSpritesWithTransition(context, theme: theme);
      },
      child: child,
    );
  }
}

/// Pushes Developer Tools with the terminal black background (debug builds only).
Future<T?> pushDevToolsRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  if (!kDebugMode) return Future<T?>.value();
  return pushAppRoute<T>(
    context,
    builder: builder,
    backgroundColor: DevToolsTheme.background,
    settings: settings,
  );
}
