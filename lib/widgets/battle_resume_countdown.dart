import 'dart:async';

import 'package:flutter/material.dart';

import '../models/background_theme.dart';

/// A three-second input-blocking countdown shown before a paused battle resumes.
class BattleResumeCountdown extends StatefulWidget {
  const BattleResumeCountdown({
    super.key,
    required this.theme,
    required this.onComplete,
    this.reducedEffects = false,
  });

  final BackgroundTheme theme;
  final VoidCallback onComplete;
  final bool reducedEffects;

  @override
  State<BattleResumeCountdown> createState() => _BattleResumeCountdownState();
}

class _BattleResumeCountdownState extends State<BattleResumeCountdown> {
  static const _startCount = 3;

  late int _count;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _count = _startCount;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (_count > 1) {
      setState(() => _count--);
      return;
    }

    timer.cancel();
    widget.onComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.62),
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Battle resumes in $_count',
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get Ready',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_count),
                    duration: widget.reducedEffects
                        ? Duration.zero
                        : const Duration(milliseconds: 700),
                    tween: Tween(begin: 1.45, end: 1),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 112,
                      height: 112,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.theme.primaryColor,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: widget.reducedEffects
                            ? null
                            : [
                                BoxShadow(
                                  color: widget.theme.primaryColor.withValues(
                                    alpha: 0.55,
                                  ),
                                  blurRadius: 28,
                                  spreadRadius: 5,
                                ),
                              ],
                      ),
                      child: Text(
                        '$_count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
