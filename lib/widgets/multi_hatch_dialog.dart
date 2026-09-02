import 'dart:async';

import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../models/egg.dart';
import '../models/hatch_result.dart';
import '../models/owned_animal.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../theme/game_theme.dart';
import 'audio_scope.dart';
import 'game_sprite.dart';
import 'hatching_egg_widgets.dart';

/// Stages of the egg cracking hatch reveal animation.
enum _HatchStage { gentleShake, cracking, pop, revealed }

/// Animated dialog for Triple Hatch showing one crack then three results.
class MultiHatchDialog extends StatefulWidget {
  const MultiHatchDialog({
    super.key,
    required this.egg,
    required this.results,
    required this.theme,
    this.customSprites,
    this.sourceEggId,
    this.masteryLevel = 0,
    this.initialDelay = const Duration(milliseconds: 900),
  });

  final Egg egg;
  final List<HatchResult> results;
  final BackgroundTheme theme;
  final CustomSpriteService? customSprites;
  final String? sourceEggId;
  final int masteryLevel;
  final Duration initialDelay;

  static Future<void> show(
    BuildContext context, {
    required Egg egg,
    required List<HatchResult> results,
    required BackgroundTheme theme,
    CustomSpriteService? customSprites,
    String? sourceEggId,
    int masteryLevel = 0,
    Duration initialDelay = const Duration(milliseconds: 900),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultiHatchDialog(
        egg: egg,
        results: results,
        theme: theme,
        customSprites: customSprites,
        sourceEggId: sourceEggId,
        masteryLevel: masteryLevel,
        initialDelay: initialDelay,
      ),
    );
  }

  @override
  State<MultiHatchDialog> createState() => _MultiHatchDialogState();
}

class _MultiHatchDialogState extends State<MultiHatchDialog>
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

    await Future<void>.delayed(widget.initialDelay);
    if (!mounted || generation != _sequenceGeneration) return;

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

    setState(() => _stage = _HatchStage.pop);
    _shakeController.stop();
    AudioScope.maybeOf(context)?.playEggCrack();
    await _popController.forward();
    if (!mounted || generation != _sequenceGeneration) return;

    setState(() => _stage = _HatchStage.revealed);
    final audio = AudioScope.maybeOf(context);
    final hasBigReward = widget.results.any(
      (result) => result.animal.rarity.sortOrder >= 4,
    );
    await audio?.playHatchReveal(bigReward: hasBigReward);
    await _revealController.forward();
  }

  void _skipHatchAnimation() {
    if (_stage == _HatchStage.revealed) return;

    _sequenceGeneration++;
    _shakeController.stop();
    _popController.stop();
    setState(() => _stage = _HatchStage.revealed);
    final hasBigReward = widget.results.any(
      (result) => result.animal.rarity.sortOrder >= 4,
    );
    unawaited(
      AudioScope.maybeOf(context)?.playHatchReveal(bigReward: hasBigReward) ??
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

  bool get _hasMutation => widget.results.any((r) => !r.mutation.isNormal);

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
        return 'Triple Hatching...';
      case _HatchStage.cracking:
        return 'Crack...';
      case _HatchStage.pop:
        return 'Pop!';
      case _HatchStage.revealed:
        if (_hasMutation) return 'Triple Hatch Results!';
        return 'You hatched 3 animals!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final revealed = _stage == _HatchStage.revealed;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final eggSize = screenWidth < 360 ? 58.0 : 68.0;
    final accent = _hasMutation && revealed
        ? GameTheme.mutationAccent(
            widget.results.firstWhere((r) => !r.mutation.isNormal).mutation.id,
          )
        : widget.theme.primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: widget.theme.cardBorderColor.withValues(alpha: 0.5),
        ),
      ),
      backgroundColor: revealed && _hasMutation
          ? GameTheme.mutationTint(
              widget.results
                  .firstWhere((r) => !r.mutation.isNormal)
                  .mutation
                  .id,
            )
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
                          fontSize: revealed && _hasMutation ? 26 : 22,
                          fontWeight: FontWeight.bold,
                          color: revealed && _hasMutation
                              ? accent
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
                            key: const ValueKey('skip-triple-hatch-animation'),
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
                const SizedBox(height: 8),
                Text(
                  _hasMutation
                      ? 'Amazing haul — check your mutations!'
                      : 'All three are in your collection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.cardTextSecondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
              SizedBox(height: revealed ? 14 : 18),
              ClipRect(
                child: SizedBox(
                  height: revealed ? null : eggSize + 16,
                  child: Center(
                    child: revealed
                        ? ScaleTransition(
                            scale: _revealScale,
                            child: _buildResultsGrid(context),
                          )
                        : _stage == _HatchStage.pop
                        ? ScaleTransition(
                            scale: _popScale,
                            child: AnimatedTripleEggRow(
                              egg: widget.egg,
                              eggSize: eggSize,
                              showCracks: true,
                              shakeAmount: 0,
                              shakePhase: 0,
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, _) {
                              return AnimatedTripleEggRow(
                                egg: widget.egg,
                                eggSize: eggSize,
                                showCracks: _stage == _HatchStage.cracking,
                                shakeAmount: _shakeAmount,
                                shakePhase: _shakeAnimation.value,
                              );
                            },
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: GameTheme.filledButton(widget.theme, color: accent),
                    child: Text(
                      _hasMutation ? 'Amazing!' : 'Awesome!',
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

  Widget _buildResultsGrid(BuildContext context) {
    final useWideLayout =
        MediaQuery.sizeOf(context).width >= 520 && widget.results.length == 3;

    if (useWideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.results.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == 2 ? 0 : 6,
                ),
                child: _TripleResultTile(
                  result: widget.results[i],
                  theme: widget.theme,
                  customSprites: widget.customSprites,
                  index: i + 1,
                  compact: true,
                  sourceEggId: widget.sourceEggId,
                  masteryLevel: widget.masteryLevel,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < widget.results.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _TripleResultTile(
            result: widget.results[i],
            theme: widget.theme,
            customSprites: widget.customSprites,
            index: i + 1,
            sourceEggId: widget.sourceEggId,
            masteryLevel: widget.masteryLevel,
          ),
        ],
      ],
    );
  }
}

class _TripleResultTile extends StatelessWidget {
  const _TripleResultTile({
    required this.result,
    required this.theme,
    required this.index,
    this.customSprites,
    this.compact = false,
    this.sourceEggId,
    this.masteryLevel = 0,
  });

  final HatchResult result;
  final BackgroundTheme theme;
  final CustomSpriteService? customSprites;
  final int index;
  final bool compact;
  final String? sourceEggId;
  final int masteryLevel;

  @override
  Widget build(BuildContext context) {
    final isMutated = !result.mutation.isNormal;
    final mutationColor = GameTheme.mutationAccent(result.mutation.id);
    final animalName = result.animal.name;
    final accessibilityName = result.mutation.fullName(result.animal);
    final income = GameService.incomeFor(
      result.animal,
      OwnedAnimal(
        animalId: result.animal.id,
        quantity: 1,
        level: 1,
        mutationId: result.mutation.id,
        sourceEggId: sourceEggId,
      ),
      masteryLevel: masteryLevel,
    );

    return Container(
      decoration: GameTheme.cardDecoration(
        theme,
        borderColor: isMutated ? mutationColor : null,
        backgroundColor: isMutated
            ? GameTheme.mutationTint(result.mutation.id)
            : null,
      ),
      padding: EdgeInsets.all(compact ? 10 : 12),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameAnimalPortrait(
                  customSprite: customSprites?.getDisplaySprite(
                    result.animal.id,
                  ),
                  animalId: result.animal.id,
                  spritePath: result.animal.spritePath,
                  fallbackEmoji: result.animal.emoji,
                  size: 52,
                  mutation: result.mutation,
                  semanticLabel: accessibilityName,
                  emojiFontSize: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  animalName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isMutated
                        ? mutationColor
                        : theme.cardTextPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMutated ? result.mutation.displayName : '$income/s',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isMutated ? FontWeight.w700 : FontWeight.w500,
                    color: isMutated
                        ? mutationColor
                        : theme.cardTextSecondaryColor,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                GameAnimalPortrait(
                  customSprite: customSprites?.getDisplaySprite(
                    result.animal.id,
                  ),
                  animalId: result.animal.id,
                  spritePath: result.animal.spritePath,
                  fallbackEmoji: result.animal.emoji,
                  size: 56,
                  mutation: result.mutation,
                  semanticLabel: accessibilityName,
                  emojiFontSize: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$index $animalName',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isMutated
                              ? mutationColor
                              : theme.cardTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMutated
                            ? result.mutation.displayName
                            : '${result.animal.coinsPerSecond}/s base',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isMutated
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isMutated
                              ? mutationColor
                              : theme.cardTextSecondaryColor,
                        ),
                      ),
                      Text(
                        '$income/s income',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.cardTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
