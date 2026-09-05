import 'package:flutter/material.dart';

import '../models/background_theme.dart';
import '../models/boss_battle.dart';
import '../models/custom_sprite_data.dart';
import '../theme/game_theme.dart';
import '../utils/boss_battle_logic.dart';
import '../utils/format_utils.dart';
import 'boss_sprite.dart';
import 'game_sprite.dart';

/// Animated phone-width boss battle scene before the result dialog.
class BattleAnimationDialog extends StatefulWidget {
  const BattleAnimationDialog({
    super.key,
    required this.theme,
    required this.boss,
    required this.result,
    required this.fighterName,
    required this.fighterSpritePath,
    required this.fighterEmoji,
    this.fighterCustomSprite,
  });

  final BackgroundTheme theme;
  final BossBattleDefinition boss;
  final BossBattleResult result;
  final String fighterName;
  final String? fighterSpritePath;
  final String fighterEmoji;
  final CustomSpriteData? fighterCustomSprite;

  static Future<void> show(
    BuildContext context, {
    required BackgroundTheme theme,
    required BossBattleDefinition boss,
    required BossBattleResult result,
    required String fighterName,
    required String? fighterSpritePath,
    required String fighterEmoji,
    CustomSpriteData? fighterCustomSprite,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: theme.scaffoldColor.withValues(alpha: 0.92),
      builder: (_) => BattleAnimationDialog(
        theme: theme,
        boss: boss,
        result: result,
        fighterName: fighterName,
        fighterSpritePath: fighterSpritePath,
        fighterEmoji: fighterEmoji,
        fighterCustomSprite: fighterCustomSprite,
      ),
    );
  }

  @override
  State<BattleAnimationDialog> createState() => _BattleAnimationDialogState();
}

class _BattleAnimationDialogState extends State<BattleAnimationDialog> {
  late final List<BattleRoundSnapshot> _steps;
  var _stepIndex = -1;
  var _playerHp = 0;
  var _bossHp = 0;
  var _playerOffset = 0.0;
  var _bossOffset = 0.0;
  var _playerFlash = false;
  var _bossFlash = false;
  var _finished = false;
  var _skipped = false;
  int? _playerDamage;
  int? _bossDamage;
  var _damageTick = 0;

  BackgroundTheme get theme => widget.theme;
  BossBattleResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _steps = BossBattleLogic.visibleSnapshots(result);
    _playerHp = result.initialPlayerHp;
    _bossHp = result.initialBossHp;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runBattle());
  }

  Future<void> _runBattle() async {
    if (_steps.isEmpty) {
      _finish();
      return;
    }

    for (var i = 0; i < _steps.length; i++) {
      if (!mounted || _skipped) break;
      await _playStep(_steps[i]);
    }

    if (mounted) _finish();
  }

  Future<void> _playStep(BattleRoundSnapshot step) async {
    setState(() {
      _stepIndex++;
      _playerDamage = null;
      _bossDamage = null;
      if (step.isPlayerAttack) {
        _playerOffset = 24;
      } else {
        _bossOffset = -24;
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 175));
    if (!mounted || _skipped) return;

    setState(() {
      _playerHp = step.playerHpAfter;
      _bossHp = step.bossHpAfter;
      _damageTick++;
      if (step.isPlayerAttack) {
        _bossFlash = true;
        _bossDamage = step.damage;
      } else {
        _playerFlash = true;
        _playerDamage = step.damage;
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 175));
    if (!mounted || _skipped) return;

    setState(() {
      _playerOffset = 0;
      _bossOffset = 0;
      _playerFlash = false;
      _bossFlash = false;
    });
  }

  void _skip() {
    if (_finished) return;
    setState(() {
      _skipped = true;
      _playerHp = result.finalPlayerHp;
      _bossHp = result.finalBossHp;
      _playerOffset = 0;
      _bossOffset = 0;
      _playerFlash = false;
      _bossFlash = false;
      _playerDamage = null;
      _bossDamage = null;
    });
    _finish();
  }

  void _finish() {
    if (_finished) return;
    setState(() {
      _finished = true;
      _playerHp = result.finalPlayerHp;
      _bossHp = result.finalBossHp;
      _playerDamage = null;
      _bossDamage = null;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final playerSize = width >= 360 ? 96.0 : 84.0;
    final bossSize = width >= 360 ? 150.0 : 132.0;

    return Dialog(
      backgroundColor: theme.cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameTheme.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Battle!',
                      style: GameTheme.sectionTitle(theme),
                    ),
                  ),
                  if (!_finished)
                    TextButton.icon(
                      onPressed: _skip,
                      icon: Icon(
                        Icons.fast_forward_rounded,
                        color: theme.secondaryColor,
                      ),
                      label: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FighterColumn(
                      theme: theme,
                      label: widget.fighterName,
                      currentHp: _playerHp,
                      maxHp: result.initialPlayerHp,
                      accent: theme.primaryColor,
                      spriteSize: playerSize,
                      offsetX: _playerOffset,
                      flash: _playerFlash,
                      damage: _playerDamage,
                      damageKey: 'p$_damageTick',
                      sprite: GameSprite(
                        customSprite: widget.fighterCustomSprite,
                        spritePath: widget.fighterSpritePath,
                        fallbackEmoji: widget.fighterEmoji,
                        size: playerSize,
                        emojiFontSize: playerSize * 0.55,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FighterColumn(
                      theme: theme,
                      label: widget.boss.name,
                      currentHp: _bossHp,
                      maxHp: result.initialBossHp,
                      accent: theme.secondaryColor,
                      spriteSize: bossSize,
                      offsetX: _bossOffset,
                      flash: _bossFlash,
                      damage: _bossDamage,
                      damageKey: 'b$_damageTick',
                      sprite: BossSprite(
                        spritePath: widget.boss.spritePath,
                        fallbackEmoji: widget.boss.emoji,
                        bossId: widget.boss.id,
                        size: bossSize,
                        semanticLabel: widget.boss.name,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_stepIndex >= 0 && _stepIndex < _steps.length)
                Text(
                  _steps[_stepIndex.clamp(0, _steps.length - 1)].logText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.cardTextSecondaryColor,
                    height: 1.3,
                  ),
                )
              else
                Text(
                  'Get ready…',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.cardTextSecondaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FighterColumn extends StatelessWidget {
  const _FighterColumn({
    required this.theme,
    required this.label,
    required this.currentHp,
    required this.maxHp,
    required this.accent,
    required this.spriteSize,
    required this.offsetX,
    required this.flash,
    required this.damage,
    required this.damageKey,
    required this.sprite,
  });

  final BackgroundTheme theme;
  final String label;
  final int currentHp;
  final int maxHp;
  final Color accent;
  final double spriteSize;
  final double offsetX;
  final bool flash;
  final int? damage;
  final String damageKey;
  final Widget sprite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HpBar(
          theme: theme,
          label: label,
          current: currentHp,
          max: maxHp,
          accent: accent,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: spriteSize + 24,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(offsetX, 0),
                  child: _FlashWrap(
                    flash: flash,
                    child: sprite,
                  ),
                ),
              ),
              if (damage != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _FloatingDamageNumber(
                      key: ValueKey(damageKey),
                      damage: damage!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.theme,
    required this.label,
    required this.current,
    required this.max,
    required this.accent,
  });

  final BackgroundTheme theme;
  final String label;
  final int current;
  final int max;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.cardTextPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: theme.disabledColor.withValues(alpha: 0.2),
            color: accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${formatCoins(current)} / ${formatCoins(max)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: theme.cardTextSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _FloatingDamageNumber extends StatefulWidget {
  const _FloatingDamageNumber({
    super.key,
    required this.damage,
  });

  final int damage;

  @override
  State<_FloatingDamageNumber> createState() => _FloatingDamageNumberState();
}

class _FloatingDamageNumberState extends State<_FloatingDamageNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -22 * t),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Text(
        '-${formatCoins(widget.damage)}',
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}

class _FlashWrap extends StatelessWidget {
  const _FlashWrap({
    required this.flash,
    required this.child,
  });

  final bool flash;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: flash ? 0.45 : 1,
      child: child,
    );
  }
}
