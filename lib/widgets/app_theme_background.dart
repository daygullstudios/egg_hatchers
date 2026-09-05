import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import 'phone_width_layout.dart';

/// Hosts the entire app inside its canonical portrait viewport.
///
/// Phones remain edge-to-edge. Wider displays get a neutral surround while
/// routes, overlays, and dialogs all see the constrained width through
/// [MediaQuery], preventing desktop width from leaking into mobile-first UI.
class PortraitAppShell extends StatelessWidget {
  const PortraitAppShell({super.key, required this.child});

  static const surfaceKey = ValueKey<String>('portrait-app-surface');
  static const Color surroundColor = Color(0xFF121212);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: surroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final surfaceWidth = math.min(
            constraints.maxWidth,
            kPhoneMaxContentWidth,
          );
          final isWide = constraints.maxWidth > kPhoneMaxContentWidth;

          return Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: isWide
                    ? const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipRect(
                child: SizedBox(
                  key: surfaceKey,
                  width: surfaceWidth,
                  height: constraints.maxHeight,
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      size: Size(surfaceWidth, constraints.maxHeight),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen gradient backdrop that stays painted behind routes.
class AppThemeBackground extends StatelessWidget {
  const AppThemeBackground({
    super.key,
    required this.theme,
    this.child = const SizedBox.shrink(),
  });

  final BackgroundTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: theme.gradient),
          child: const SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}

/// Opaque full-screen backdrop for route transitions. Never animated.
class StableRouteBackdrop extends StatelessWidget {
  const StableRouteBackdrop({super.key, this.theme, this.color})
    : assert(theme != null || color != null);

  final BackgroundTheme? theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (theme != null) {
      return AppThemeBackground(theme: theme!);
    }
    return ColoredBox(color: color!);
  }
}

/// Centers route content in the phone-width column for panel transitions.
class AppRoutePhonePanel extends StatelessWidget {
  const AppRoutePhonePanel({
    super.key,
    required this.child,
    this.maxWidth = 430,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width, maxWidth);
    final height = MediaQuery.sizeOf(context).height;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}
