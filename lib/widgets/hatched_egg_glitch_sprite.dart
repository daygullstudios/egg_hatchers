import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/sprite_decode_size.dart';
import '../models/animal_sprite_theme.dart';
import 'animal_sprite_theme_scope.dart';
import 'animated_animal_glitch.dart';

/// Glitching nest with five independently changing friendly animal heads.
class UltimateNestGlitchSprite extends StatefulWidget {
  const UltimateNestGlitchSprite({
    super.key,
    required this.body,
    required this.size,
  });

  static const headAssetDirectory = 'assets/images/hatched_egg_heads';

  static String headAssetPath(String themeId, String animalId) {
    final directory = themeId == AnimalSpriteThemes.realistic.id
        ? headAssetDirectory
        : '$headAssetDirectory/$themeId';
    return '$directory/$animalId.png';
  }

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

  final Widget body;
  final double size;

  @override
  State<UltimateNestGlitchSprite> createState() =>
      _UltimateNestGlitchSpriteState();
}

class _UltimateNestGlitchSpriteState extends State<UltimateNestGlitchSprite> {
  final _random = math.Random();
  Timer? _headTimer;
  final _headIndices = <int>[0, 1, 2, 3, 4];
  var _nextSlot = 0;

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
        final slot = _nextSlot;
        var nextIndex = _random.nextInt(
          UltimateNestGlitchSprite.goodHeadAnimalIds.length,
        );
        final occupied = _headIndices.toSet()..remove(_headIndices[slot]);
        while (nextIndex == _headIndices[slot] ||
            occupied.contains(nextIndex)) {
          nextIndex =
              (nextIndex + 1) %
              UltimateNestGlitchSprite.goodHeadAnimalIds.length;
        }
        setState(() {
          _headIndices[slot] = nextIndex;
          _nextSlot = (_nextSlot + 1) % _headIndices.length;
        });
        _scheduleHeadChange();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedAnimalGlitch(
        size: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: widget.body),
            for (var slot = 0; slot < _headIndices.length; slot++)
              _buildHead(context, slot),
            Positioned.fill(
              child: ExcludeSemantics(
                child: ClipPath(
                  key: const ValueKey('ultimate-nest-front-rim'),
                  clipper: const _UltimateNestFrontRimClipper(),
                  child: widget.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHead(BuildContext context, int slot) {
    const slots = <({double left, double top, double size})>[
      (left: 0.13, top: 0.27, size: 0.29),
      (left: 0.26, top: 0.19, size: 0.29),
      (left: 0.45, top: 0.20, size: 0.29),
      (left: 0.59, top: 0.29, size: 0.29),
      (left: 0.35, top: 0.35, size: 0.30),
    ];
    final layout = slots[slot];
    final headId =
        UltimateNestGlitchSprite.goodHeadAnimalIds[_headIndices[slot]];
    final headSize = widget.size * layout.size;
    final themeId = AnimalSpriteThemeScope.of(context).id;
    final pixelated = themeId == AnimalSpriteThemes.retroPixel.id;
    final headDecodeWidth = SpriteDecodeSize.forDisplay(
      logicalSize: headSize,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      maxSourceWidth: pixelated ? 64 : 256,
    );

    return Positioned(
      key: ValueKey('ultimate-nest-head-slot-$slot'),
      top: widget.size * layout.top,
      left: widget.size * layout.left,
      width: headSize,
      height: headSize,
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.78, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: Image.asset(
            UltimateNestGlitchSprite.headAssetPath(themeId, headId),
            key: ValueKey('ultimate-nest-head-$slot-$headId'),
            width: headSize,
            height: headSize,
            fit: BoxFit.contain,
            filterQuality: pixelated ? FilterQuality.none : FilterQuality.high,
            cacheWidth: headDecodeWidth,
          ),
        ),
      ),
    );
  }
}

/// Repaints the lower nest weave in front of all five occupants.
class _UltimateNestFrontRimClipper extends CustomClipper<Path> {
  const _UltimateNestFrontRimClipper();

  @override
  Path getClip(Size size) {
    final h = size.height;
    return Path()
      ..moveTo(0, h * 0.43)
      ..quadraticBezierTo(size.width * .5, h * .77, size.width, h * .43)
      ..lineTo(size.width, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(_UltimateNestFrontRimClipper oldClipper) => false;
}
