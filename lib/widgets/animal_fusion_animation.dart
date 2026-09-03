import 'dart:math';

import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/animal.dart';
import '../models/background_theme.dart';
import '../models/mutation.dart';
import '../models/custom_sprite_data.dart';
import '../services/custom_sprite_service.dart';
import '../utils/animal_fusion_logic.dart';
import '../utils/ui_sound.dart';
import 'game_sprite.dart';

/// Full-screen fusion swirl animation with flash and result reveal.
class AnimalFusionAnimation extends StatefulWidget {
  const AnimalFusionAnimation({
    super.key,
    required this.theme,
    required this.customSprites,
    required this.outcome,
  });

  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final AnimalFusionOutcome outcome;

  static const duration = Duration(milliseconds: 3400);
  static const skipButtonKey = Key('fusion-animation-skip');

  static Future<void> show(
    BuildContext context, {
    required BackgroundTheme theme,
    required CustomSpriteService customSprites,
    required AnimalFusionOutcome outcome,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (dialogContext) => AnimalFusionAnimation(
        theme: theme,
        customSprites: customSprites,
        outcome: outcome,
      ),
    );
  }

  @override
  State<AnimalFusionAnimation> createState() => _AnimalFusionAnimationState();
}

class _AnimalFusionAnimationState extends State<AnimalFusionAnimation>
    with SingleTickerProviderStateMixin {
  static const _revealStart = 0.941;
  static const _flashStart = 0.853;

  late final AnimationController _controller;
  var _revealSoundPlayed = false;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: AnimalFusionAnimation.duration,
          )
          ..addListener(_onTick)
          ..forward();
  }

  void _onTick() {
    if (_revealSoundPlayed || _controller.value < _revealStart) return;
    _revealSoundPlayed = true;
    if (!mounted) return;
    if (widget.outcome.succeeded) {
      if (widget.outcome.wasLucky) {
        UiSound.rewardBigTriumph(context);
      } else {
        UiSound.rewardTriumph(context);
      }
    } else {
      UiSound.locked(context);
    }
  }

  void _finishOnce() {
    if (_completed) return;
    _completed = true;
    Navigator.of(context).pop();
  }

  void _skipAnimation() {
    if (_controller.value >= 1) return;
    _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(widget.outcome.animalId);
    if (animal == null) {
      return Center(child: Text(widget.outcome.inputDisplayName));
    }

    final inputMutation =
        GameData.mutationById(widget.outcome.inputMutationId) ??
        GameData.mutations.first;
    final outputMutation = widget.outcome.resultMutationId == null
        ? null
        : GameData.mutationById(widget.outcome.resultMutationId!) ??
              GameData.mutations.first;
    final customSprite = widget.customSprites.getDisplaySprite(animal.id);
    final flashColor = FusionVisuals.flashColor(widget.outcome.inputMutationId);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final showOrbit = t < _flashStart + 0.04;
            final flashT = _segment(t, _flashStart, _flashStart + 0.088);
            final revealT = _segment(t, _revealStart, 1.0, Curves.easeOut);
            final orbitT = _segment(t, 0.118, _flashStart, Curves.easeIn);
            final startT = _segment(t, 0, 0.118, Curves.easeOut);
            final done = t >= 1.0;

            return Container(
              constraints: const BoxConstraints(maxWidth: 360, minHeight: 380),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.theme.cardColor.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: flashColor.withValues(alpha: 0.35 + orbitT * 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: flashColor.withValues(alpha: 0.25 * orbitT),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final center = Offset(
                              constraints.maxWidth / 2,
                              constraints.maxHeight / 2,
                            );
                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                _MagicCircle(
                                  color: flashColor,
                                  pulse: 0.4 + orbitT * 0.6,
                                  opacity: 0.12 + startT * 0.18,
                                ),
                                if (orbitT > 0 && showOrbit)
                                  ..._orbitParticles(
                                    center: center,
                                    flashColor: flashColor,
                                    orbitT: orbitT,
                                    t: t,
                                  ),
                                if (showOrbit)
                                  ..._orbitingSprites(
                                    center: center,
                                    animal: animal,
                                    inputMutation: inputMutation,
                                    customSprite: customSprite,
                                    startT: startT,
                                    orbitT: orbitT,
                                    t: t,
                                  ),
                                if (flashT > 0)
                                  _FusionFlash(
                                    color: flashColor,
                                    intensity: flashT,
                                    inputMutationId:
                                        widget.outcome.inputMutationId,
                                  ),
                                if (revealT > 0)
                                  _RevealLayer(
                                    animal: animal,
                                    inputMutation: inputMutation,
                                    outputMutation: outputMutation,
                                    customSprite: customSprite,
                                    outcome: widget.outcome,
                                    revealT: revealT,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (revealT > 0.35) ...[
                        Opacity(
                          opacity: ((revealT - 0.35) / 0.65).clamp(0.0, 1.0),
                          child: _RevealText(outcome: widget.outcome),
                        ),
                      ],
                      if (done) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _finishOnce,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.outcome.succeeded
                                ? widget.theme.primaryColor
                                : Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: const Text('Continue'),
                        ),
                      ],
                    ],
                  ),
                  if (!done)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: TextButton.icon(
                        key: AnimalFusionAnimation.skipButtonKey,
                        onPressed: _skipAnimation,
                        style: TextButton.styleFrom(
                          foregroundColor: widget.theme.cardTextSecondaryColor,
                          backgroundColor: widget.theme.cardColor.withValues(
                            alpha: 0.88,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.fast_forward_rounded, size: 20),
                        label: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static double _segment(
    double t,
    double start,
    double end, [
    Curve curve = Curves.linear,
  ]) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return curve.transform((t - start) / (end - start));
  }

  List<Widget> _orbitParticles({
    required Offset center,
    required Color flashColor,
    required double orbitT,
    required double t,
  }) {
    return List.generate(6, (index) {
      final angle = t * pi * (4 + orbitT * 8) + index * pi / 3;
      final radius = 36 + orbitT * 72;
      return Positioned(
        left: center.dx + cos(angle) * radius - 3,
        top: center.dy + sin(angle) * radius - 3,
        child: Opacity(
          opacity: (0.15 + orbitT * 0.45).clamp(0.0, 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: flashColor,
              boxShadow: [
                BoxShadow(
                  color: flashColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _orbitingSprites({
    required Offset center,
    required Animal animal,
    required Mutation inputMutation,
    required CustomSpriteData? customSprite,
    required double startT,
    required double orbitT,
    required double t,
  }) {
    const spriteSize = 58.0;
    final startRadius = 92.0;
    final endRadius = 6.0;
    final radius = startRadius + (endRadius - startRadius) * orbitT;
    final turns = 1.5 + orbitT * 5.5;
    final spin = t * pi * (3 + orbitT * 10);

    final angles = [pi, 0.0];
    return List.generate(2, (index) {
      final baseAngle = angles[index];
      final angle = baseAngle + turns * 2 * pi * orbitT;
      final bob = sin(t * pi * 6 + index) * (4 * (1 - orbitT));
      final pos =
          center +
          Offset(cos(angle), sin(angle)) * radius +
          Offset(0, bob * startT);

      final introScale = 0.55 + startT * 0.45;
      final opacity = startT.clamp(0.0, 1.0);

      return Positioned(
        left: pos.dx - spriteSize / 2,
        top: pos.dy - spriteSize / 2,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: spin + index * pi,
            child: Transform.scale(
              scale: introScale * (1 + orbitT * 0.08),
              child: GameSprite(
                customSprite: customSprite,
                animalId: animal.id,
                spritePath: animal.spritePath,
                fallbackEmoji: inputMutation.displayEmoji(animal),
                size: spriteSize,
                semanticLabel: inputMutation.fullName(animal),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class FusionVisuals {
  FusionVisuals._();

  static Color flashColor(String inputMutationId) {
    return switch (inputMutationId) {
      'golden' => const Color(0xFFFFD54F),
      'rainbow' => const Color(0xFF40C4FF),
      'none' => const Color(0xFFFFF9C4),
      _ => const Color(0xFF7E57C2),
    };
  }
}

class _MagicCircle extends StatelessWidget {
  const _MagicCircle({
    required this.color,
    required this.pulse,
    required this.opacity,
  });

  final Color color;
  final double pulse;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 180 * pulse,
        height: 180 * pulse,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: opacity), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.8),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FusionFlash extends StatelessWidget {
  const _FusionFlash({
    required this.color,
    required this.intensity,
    required this.inputMutationId,
  });

  final Color color;
  final double intensity;
  final String inputMutationId;

  @override
  Widget build(BuildContext context) {
    final rainbow = inputMutationId == 'rainbow';
    final flashOpacity = sin(intensity * pi).clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 140 + intensity * 80,
            height: 140 + intensity * 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: rainbow
                  ? RadialGradient(
                      colors: [
                        Colors.pinkAccent.withValues(alpha: flashOpacity),
                        Colors.cyanAccent.withValues(
                          alpha: flashOpacity * 0.85,
                        ),
                        Colors.transparent,
                      ],
                    )
                  : null,
              color: rainbow
                  ? null
                  : color.withValues(alpha: flashOpacity * 0.92),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: flashOpacity * 0.75),
                  blurRadius: 40,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealLayer extends StatelessWidget {
  const _RevealLayer({
    required this.animal,
    required this.inputMutation,
    required this.outputMutation,
    required this.customSprite,
    required this.outcome,
    required this.revealT,
  });

  final Animal animal;
  final Mutation inputMutation;
  final Mutation? outputMutation;
  final CustomSpriteData? customSprite;
  final AnimalFusionOutcome outcome;
  final double revealT;

  @override
  Widget build(BuildContext context) {
    if (!outcome.succeeded || outputMutation == null) {
      return Opacity(
        opacity: revealT.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + revealT * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 72,
                color: Colors.grey.shade500.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 8),
              Icon(Icons.close_rounded, size: 36, color: Colors.red.shade400),
            ],
          ),
        ),
      );
    }

    final lucky = outcome.wasLucky;
    final size = lucky ? 96.0 : 84.0;
    final resultMutation = outputMutation!;
    final glow = FusionVisuals.flashColor(outcome.resultMutationId ?? 'none');

    return Opacity(
      opacity: revealT.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.5 + revealT * 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: lucky ? 0.65 : 0.45),
                blurRadius: lucky ? 36 : 24,
                spreadRadius: lucky ? 8 : 3,
              ),
              if (lucky)
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: GameSprite(
            customSprite: customSprite,
            animalId: animal.id,
            spritePath: animal.spritePath,
            fallbackEmoji: resultMutation.displayEmoji(animal),
            size: size,
            semanticLabel: outcome.displayName,
          ),
        ),
      ),
    );
  }
}

class _RevealText extends StatelessWidget {
  const _RevealText({required this.outcome});

  final AnimalFusionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    if (outcome.succeeded) {
      return Column(
        children: [
          Text(
            outcome.wasLucky ? 'Lucky Fusion!' : 'Fusion Success!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: outcome.wasLucky
                  ? Colors.amber.shade700
                  : Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Created ${outcome.displayName}!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Fusion Failed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Both animals were lost.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
