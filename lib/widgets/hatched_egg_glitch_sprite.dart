import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/sprite_decode_size.dart';
import 'animated_animal_glitch.dart';

/// Open glitch shell whose occupant changes between friendly animal heads.
class HatchedEggGlitchSprite extends StatefulWidget {
  const HatchedEggGlitchSprite({
    super.key,
    required this.body,
    required this.size,
  });

  static const headAssetDirectory = 'assets/images/hatched_egg_heads';

  static const goodHeadAnimalIds = [
    'royal_chicken',
    'crown_fox',
    'gem_dragon',
    'cloud_bunny',
    'sun_lion',
    'cosmic_phoenix',
    'moon_cat',
    'star_fox',
    'galaxy_dragon',
    'unicorn',
  ];

  static const _headTopFactors = <String, double>{
    'royal_chicken': 0.115,
    'crown_fox': 0.10,
    'gem_dragon': 0.055,
    'cloud_bunny': 0.015,
    'sun_lion': 0.11,
    'cosmic_phoenix': 0.07,
    'moon_cat': 0.065,
    'star_fox': 0.06,
    'galaxy_dragon': 0.055,
    'unicorn': 0.025,
  };

  final Widget body;
  final double size;

  @override
  State<HatchedEggGlitchSprite> createState() => _HatchedEggGlitchSpriteState();
}

class _HatchedEggGlitchSpriteState extends State<HatchedEggGlitchSprite> {
  final _random = math.Random();
  Timer? _headTimer;
  var _headIndex = 0;

  @override
  void initState() {
    super.initState();
    _scheduleHeadChange();
  }

  @override
  void dispose() {
    _headTimer?.cancel();
    super.dispose();
  }

  void _scheduleHeadChange() {
    _headTimer = Timer(
      Duration(milliseconds: 1800 + _random.nextInt(1400)),
      () {
        if (!mounted) return;
        var nextIndex = _random.nextInt(
          HatchedEggGlitchSprite.goodHeadAnimalIds.length,
        );
        if (nextIndex == _headIndex) {
          nextIndex =
              (nextIndex + 1) % HatchedEggGlitchSprite.goodHeadAnimalIds.length;
        }
        setState(() => _headIndex = nextIndex);
        _scheduleHeadChange();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final headId = HatchedEggGlitchSprite.goodHeadAnimalIds[_headIndex];
    final headSize = widget.size * 0.39;
    final headDecodeWidth = SpriteDecodeSize.forDisplay(
      logicalSize: headSize,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      maxSourceWidth: 256,
    );
    final headTop = HatchedEggGlitchSprite._headTopFactors[headId] ?? 0.06;

    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedAnimalGlitch(
        size: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: widget.body),
            Positioned(
              top: widget.size * 0.16,
              left: widget.size * 0.27,
              width: widget.size * 0.46,
              height: widget.size * 0.25,
              child: const ExcludeSemantics(
                child: DecoratedBox(
                  key: ValueKey('hatched-egg-cavity'),
                  decoration: BoxDecoration(
                    color: Color(0xFF10162E),
                    borderRadius: BorderRadius.all(Radius.elliptical(999, 520)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xAA5A2EA6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: widget.size * headTop,
              left: widget.size * 0.305,
              width: widget.size * 0.39,
              height: widget.size * 0.37,
              child: ExcludeSemantics(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.82, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: OverflowBox(
                      key: ValueKey(headId),
                      alignment: Alignment.topCenter,
                      maxWidth: headSize,
                      maxHeight: headSize,
                      child: Image.asset(
                        '${HatchedEggGlitchSprite.headAssetDirectory}/$headId.png',
                        width: headSize,
                        height: headSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        cacheWidth: headDecodeWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: ClipPath(
                  key: const ValueKey('hatched-egg-front-shell'),
                  clipper: const _HatchedEggFrontShellClipper(),
                  child: widget.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the lower egg wall in front of the occupant along the cracked rim.
class _HatchedEggFrontShellClipper extends CustomClipper<Path> {
  const _HatchedEggFrontShellClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h * 0.39)
      ..lineTo(w * 0.25, h * 0.39)
      ..lineTo(w * 0.31, h * 0.33)
      ..lineTo(w * 0.39, h * 0.41)
      ..lineTo(w * 0.47, h * 0.33)
      ..lineTo(w * 0.55, h * 0.41)
      ..lineTo(w * 0.65, h * 0.34)
      ..lineTo(w * 0.72, h * 0.39)
      ..lineTo(w, h * 0.39)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(_HatchedEggFrontShellClipper oldClipper) => false;
}
