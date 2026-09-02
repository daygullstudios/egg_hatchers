import 'package:flutter/material.dart';

class BattleComboBadge extends StatelessWidget {
  const BattleComboBadge({
    super.key,
    required this.combo,
    required this.reducedEffects,
  });

  final int combo;
  final bool reducedEffects;

  String get _label => combo >= 10
      ? 'UNSTOPPABLE  $combo'
      : combo >= 5
      ? 'HOT STREAK  $combo'
      : '$combo HIT COMBO';

  Color get _color => combo >= 10
      ? const Color(0xFF80DEEA)
      : combo >= 5
      ? const Color(0xFFFF8A65)
      : const Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final visible = combo >= 2;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reducedEffects || disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return AnimatedSwitcher(
      duration: duration,
      child: !visible
          ? const SizedBox(key: ValueKey('combo-hidden'), height: 12)
          : Semantics(
              key: ValueKey('combo-$combo'),
              liveRegion: true,
              label: _label,
              child: ExcludeSemantics(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.22, end: 1),
                  duration: duration,
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Text(
                    _label,
                    style: TextStyle(
                      color: _color,
                      fontSize: combo >= 10 ? 12 : 10,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: _color.withValues(alpha: 0.5),
                          blurRadius: 7,
                        ),
                        const Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
