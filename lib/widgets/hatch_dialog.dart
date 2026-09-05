import 'dart:async';

import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../models/egg.dart';
import '../models/hatch_result.dart';
import '../services/custom_sprite_service.dart';
import '../theme/game_theme.dart';
import 'animal_card.dart';
import 'audio_scope.dart';
import 'game_sprite.dart';

/// Stages of the egg cracking hatch reveal animation.
enum _HatchStage { gentleShake, cracking, pop, revealed }

/// Animated dialog shown after buying an egg to reveal the hatched animal.
class HatchDialog extends StatefulWidget {
  const HatchDialog({
    super.key,
    required this.egg,
    required this.result,
    required this.theme,
    this.customSprites,
    this.revealedTitle,
    this.initialDelay = const Duration(milliseconds: 900),
  });

  final Egg egg;
  final HatchResult result;
  final BackgroundTheme theme;
  final CustomSpriteService? customSprites;
  final String? revealedTitle;
  final Duration initialDelay;

  static Future<void> show(
    BuildContext context, {
    required Egg egg,
    required HatchResult result,
    required BackgroundTheme theme,
    CustomSpriteService? customSprites,
    String? revealedTitle,
    Duration initialDelay = const Duration(milliseconds: 900),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HatchDialog(
        egg: egg,
        result: result,
        theme: theme,
        customSprites: customSprites,
        revealedTitle: revealedTitle,
        initialDelay: initialDelay,
      ),
    );
  }

  @override
  State<HatchDialog> createState() => _HatchDialogState();
}

class _HatchDialogState extends State<HatchDialog>
    with TickerProviderStateMixin {
  _HatchStage _stage = _HatchStage.gentleShake;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _popController;
  late final Animation<double> _popScale;
  late final AnimationController _revealController;
  late final Animation<double> _revealScale;
  var _sequenceGeneration = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runHatchSequence();
  }

  void _setupAnimations() {
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _shakeController.repeat(reverse: true);

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.85), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
  }

  Future<void> _runHatchSequence() async {
    final generation = ++_sequenceGeneration;

    // Stage 1: gentle shake
    await Future<void>.delayed(widget.initialDelay);
    if (!mounted || generation != _sequenceGeneration) return;

    // Stage 2: harder shake + cracks
    setState(() {
      _stage = _HatchStage.cracking;
      _shakeController.duration = const Duration(milliseconds: 120);
    });
    AudioScope.maybeOf(context)?.playEggCrack();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || generation != _sequenceGeneration) return;
    AudioScope.maybeOf(context)?.playEggCrack();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || generation != _sequenceGeneration) return;

    // Stage 3: pop
    setState(() => _stage = _HatchStage.pop);
    _shakeController.stop();
    AudioScope.maybeOf(context)?.playEggCrack();
    await _popController.forward();
    if (!mounted || generation != _sequenceGeneration) return;

    // Stage 4: reveal result
    setState(() => _stage = _HatchStage.revealed);
    final audio = AudioScope.maybeOf(context);
    await audio?.playHatchReveal(
      bigReward: widget.result.animal.rarity.sortOrder >= 4,
    );
    await _revealController.forward();
  }

  void _skipHatchAnimation() {
    if (_stage == _HatchStage.revealed) return;

    _sequenceGeneration++;
    _shakeController.stop();
    _popController.stop();
    setState(() => _stage = _HatchStage.revealed);
    unawaited(
      AudioScope.maybeOf(context)?.playHatchReveal(
            bigReward: widget.result.animal.rarity.sortOrder >= 4,
          ) ??
          Future<void>.value(),
    );
    unawaited(_revealController.forward(from: 0));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _popController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  double get _shakeAmount {
    switch (_stage) {
      case _HatchStage.gentleShake:
        return 6 * _shakeAnimation.value;
      case _HatchStage.cracking:
        return 14 * _shakeAnimation.value;
      case _HatchStage.pop:
      case _HatchStage.revealed:
        return 0;
    }
  }

  String get _stageTitle {
    switch (_stage) {
      case _HatchStage.gentleShake:
        return 'Hatching...';
      case _HatchStage.cracking:
        return 'Crack...';
      case _HatchStage.pop:
        return 'Pop!';
      case _HatchStage.revealed:
        final isMutated = !widget.result.mutation.isNormal;
        if (widget.revealedTitle != null) return widget.revealedTitle!;
        if (isMutated) return 'Mutation!';
        return 'It hatched!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.result.mutation.hatchMessage(widget.result.animal);
    final isMutated = !widget.result.mutation.isNormal;
    final revealed = _stage == _HatchStage.revealed;

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    final mutationColor = GameTheme.mutationAccent(widget.result.mutation.id);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: widget.theme.cardBorderColor.withValues(alpha: 0.5),
        ),
      ),
      backgroundColor: revealed && isMutated
          ? GameTheme.mutationTint(widget.result.mutation.id)
          : widget.theme.cardColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _stageTitle,
                        key: ValueKey(_stageTitle),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMutated && revealed ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: isMutated && revealed
                              ? mutationColor
                              : widget.theme.cardTextPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: revealed
                        ? null
                        : IconButton(
                            key: const ValueKey('skip-single-hatch-animation'),
                            onPressed: _skipHatchAnimation,
                            tooltip: 'Skip hatch animation',
                            icon: const Icon(Icons.fast_forward_rounded),
                            color: widget.theme.cardTextSecondaryColor,
                            padding: EdgeInsets.zero,
                          ),
                  ),
                ],
              ),
              if (revealed) ...[
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMutated ? 16 : 15,
                    fontWeight: isMutated ? FontWeight.bold : FontWeight.normal,
                    color: isMutated
                        ? mutationColor
                        : widget.theme.cardTextSecondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
              SizedBox(height: revealed ? 14 : 18),
              ClipRect(
                child: SizedBox(
                  height: revealed ? 104 : 108,
                  child: Center(
                    child: revealed
                        ? ScaleTransition(
                            scale: _revealScale,
                            child: _buildRevealedContent(isMutated),
                          )
                        : _stage == _HatchStage.pop
                        ? ScaleTransition(
                            scale: _popScale,
                            child: _buildEggVisual(showCracks: true),
                          )
                        : AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAmount, 0),
                                child: child,
                              );
                            },
                            child: _buildEggVisual(
                              showCracks: _stage == _HatchStage.cracking,
                            ),
                          ),
                  ),
                ),
              ),
              if (_stage == _HatchStage.cracking)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'crack...',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: widget.theme.cardTextSecondaryColor,
                    ),
                  ),
                ),
              if (revealed) ...[
                const SizedBox(height: 10),
                AnimalCard(
                  animal: widget.result.animal,
                  theme: widget.theme,
                  mutation: widget.result.mutation,
                  compact: true,
                  useBaseNameForTitle: true,
                  customSprites: widget.customSprites,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: GameTheme.filledButton(
                      widget.theme,
                      color: isMutated
                          ? mutationColor
                          : widget.theme.primaryColor,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      isMutated ? 'Amazing!' : 'Awesome!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEggVisual({required bool showCracks}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GameEggSprite(
          egg: widget.egg,
          size: 88,
          semanticLabel: widget.egg.name,
          emojiFontSize: 88,
        ),
        if (showCracks) const _CrackMarks(),
      ],
    );
  }

  Widget _buildRevealedContent(bool isMutated) {
    return GameAnimalPortrait(
      customSprite: widget.customSprites?.getDisplaySprite(
        widget.result.animal.id,
      ),
      animalId: widget.result.animal.id,
      spritePath: widget.result.animal.spritePath,
      fallbackEmoji: widget.result.animal.emoji,
      size: isMutated ? 84 : 76,
      mutation: widget.result.mutation,
      semanticLabel: widget.result.mutation.fullName(widget.result.animal),
      emojiFontSize: isMutated ? 76 : 68,
    );
  }
}

/// Simple crack lines drawn over the egg emoji.
class _CrackMarks extends StatelessWidget {
  const _CrackMarks();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(painter: _CrackPainter()),
    );
  }
}

class _CrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawLine(Offset(cx - 8, cy - 20), Offset(cx + 4, cy + 2), paint);
    canvas.drawLine(Offset(cx + 6, cy - 18), Offset(cx - 6, cy + 6), paint);
    canvas.drawLine(Offset(cx - 2, cy + 4), Offset(cx + 10, cy + 18), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
