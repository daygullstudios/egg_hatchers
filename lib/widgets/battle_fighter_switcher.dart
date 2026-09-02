import 'package:flutter/material.dart';

class BattleFighterSwitcher extends StatelessWidget {
  const BattleFighterSwitcher({
    super.key,
    required this.identity,
    required this.isOpponent,
    required this.reducedEffects,
    required this.child,
  });

  final Object identity;
  final bool isOpponent;
  final bool reducedEffects;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reducedEffects || disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 360);
    final side = isOpponent ? 0.28 : -0.28;

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (transitionChild, animation) {
        final slide = Tween<Offset>(
          begin: Offset(side, 0),
          end: Offset.zero,
        ).animate(animation);
        final scale = Tween<double>(begin: 0.88, end: 1).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: transitionChild),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('battle-fighter-$identity'),
        child: child,
      ),
    );
  }
}
