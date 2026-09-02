import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/arena_ability_data.dart';
import '../data/audio_assets.dart';
import '../data/game_data.dart';
import '../models/arena.dart';
import '../models/boss_battle.dart';
import '../models/custom_sprite_data.dart';
import '../models/owned_animal.dart';
import '../utils/arena_combat_logic.dart';
import '../utils/arena_logic.dart';
import '../utils/rotten_shell_final_battle_logic.dart';
import 'audio_scope.dart';
import 'animal_motion.dart';
import 'battle_health_bar.dart';
import 'boss_sprite.dart';
import 'game_sprite.dart';

enum _FinalBattleTutorialStage { none, tapBlue, tapGold, useAbility }

class RottenShellFinalBattle extends StatefulWidget {
  const RottenShellFinalBattle({
    super.key,
    required this.fighter,
    required this.fighterCustomSprite,
    required this.boss,
    required this.onVictory,
    required this.onDefeat,
    this.reducedEffects = false,
  });

  final OwnedAnimal fighter;
  final CustomSpriteData? fighterCustomSprite;
  final BossBattleDefinition boss;
  final VoidCallback onVictory;
  final VoidCallback onDefeat;
  final bool reducedEffects;

  @override
  State<RottenShellFinalBattle> createState() => _RottenShellFinalBattleState();
}

class _RottenShellFinalBattleState extends State<RottenShellFinalBattle>
    with TickerProviderStateMixin {
  static const _tutorialCompletedKey =
      'rottenShellFinalBattleTutorialCompleted';
  late final AnimationController _introController;
  late final AnimationController _beamController;
  late final ArenaFighter _fighter;
  late final List<ArenaAbility> _abilities;
  late final int _playerMaxHealth;
  late final int _bossMaxHealth;
  late final Color _beamColor;
  final _random = Random();

  Timer? _bossAttackTimer;
  Timer? _energyMoveTimer;
  Timer? _attackFlashTimer;
  Timer? _resultTimer;
  var _playerHealth = 0;
  var _bossHealth = 0;
  var _playerShield = 0;
  var _energy = 0;
  var _energyX = 0.5;
  var _energyY = 0.5;
  var _goldenEnergy = false;
  var _energyVisible = false;
  var _tutorialStage = _FinalBattleTutorialStage.none;
  var _introComplete = false;
  var _finishing = false;
  var _finished = false;
  var _playerAttacking = false;
  var _bossAttacking = false;
  var _message = 'Gather energy and break the shell.';

  @override
  void initState() {
    super.initState();
    _fighter = ArenaLogic.fighterFromOwned(widget.fighter);
    _abilities = ArenaAbilityData.forAnimal(_fighter.animalId);
    _playerMaxHealth = RottenShellFinalBattleLogic.playerMaxHealth(_fighter);
    _bossMaxHealth = RottenShellFinalBattleLogic.bossMaxHealth(_fighter);
    _playerHealth = _playerMaxHealth;
    _bossHealth = _bossMaxHealth;
    _beamColor = Color(
      RottenShellFinalBattleLogic.beamColorValue(
        _fighter.animalId,
        _fighter.mutationId,
      ),
    );
    _introController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) unawaited(_startDuel());
        });
    _beamController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2300),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && !_finished) {
            _finished = true;
            widget.onVictory();
          }
        });
    _introController.forward();
  }

  Future<void> _startDuel() async {
    if (!mounted || _introComplete) return;
    final preferences = await SharedPreferences.getInstance();
    if (!mounted || _introComplete) return;
    final showTutorial = !(preferences.getBool(_tutorialCompletedKey) ?? false);
    setState(() {
      _introComplete = true;
      if (showTutorial) {
        _tutorialStage = _FinalBattleTutorialStage.tapBlue;
        _energyX = 0.5;
        _energyY = 0.5;
        _goldenEnergy = false;
        _energyVisible = true;
        _message = 'Tap the blue energy to collect it.';
      }
    });
    if (showTutorial) return;
    _moveEnergy();
    _startCombatTimers();
  }

  void _startCombatTimers() {
    _energyMoveTimer?.cancel();
    _bossAttackTimer?.cancel();
    _energyMoveTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _moveEnergy(),
    );
    _bossAttackTimer = Timer.periodic(
      const Duration(milliseconds: 1850),
      (_) => _bossAttack(),
    );
  }

  void _moveEnergy() {
    if (!mounted || _finishing || _finished) return;
    setState(() {
      _energyX = 0.35 + _random.nextDouble() * 0.30;
      _energyY = 0.35 + _random.nextDouble() * 0.30;
      _goldenEnergy = _random.nextInt(8) == 0;
      _energyVisible = true;
    });
  }

  void _collectEnergy() {
    if (!_introComplete || !_energyVisible || _finishing || _finished) return;
    if (_tutorialStage == _FinalBattleTutorialStage.tapBlue) {
      setState(() {
        _energy = min(ArenaCombatLogic.maxEnergy, _energy + 1);
        _tutorialStage = _FinalBattleTutorialStage.tapGold;
        _goldenEnergy = true;
        _energyX = 0.5;
        _energyY = 0.5;
        _message = 'Gold energy gives 2 energy. Tap the gold energy.';
      });
      AudioScope.of(context).playSfx(Sfx.uiTap, volumeScale: 0.45);
      return;
    }
    if (_tutorialStage == _FinalBattleTutorialStage.tapGold) {
      setState(() {
        _energy = min(ArenaCombatLogic.maxEnergy, _energy + 2);
        _tutorialStage = _FinalBattleTutorialStage.useAbility;
        _energyVisible = false;
        _message = 'Use an ability to attack The Rotten Shell.';
      });
      AudioScope.of(context).playSfx(Sfx.uiTap, volumeScale: 0.45);
      return;
    }
    setState(() {
      final gain = _goldenEnergy ? 2 : 1;
      _energy = min(ArenaCombatLogic.maxEnergy, _energy + gain);
      _energyVisible = false;
      _message = _goldenEnergy ? '+2 energy!' : '+1 energy';
    });
    AudioScope.of(context).playSfx(Sfx.uiTap, volumeScale: 0.45);
    _moveEnergy();
  }

  void _bossAttack() {
    if (!mounted || !_introComplete || _finishing || _finished) return;
    final rawDamage = RottenShellFinalBattleLogic.bossAttackDamage(_fighter);
    final absorbed = min(_playerShield, rawDamage);
    final damage = rawDamage - absorbed;
    setState(() {
      _playerShield -= absorbed;
      _playerHealth = max(0, _playerHealth - damage);
      _bossAttacking = true;
      _playerAttacking = false;
      _message = absorbed == rawDamage
          ? 'Rotten Pulse blocked!'
          : 'Rotten Pulse  -$damage';
    });
    AudioScope.of(context).playSfx(Sfx.playerHit, volumeScale: 0.65);
    _attackFlashTimer?.cancel();
    _attackFlashTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted && !_finished) setState(() => _bossAttacking = false);
    });
    if (_playerHealth <= 0) {
      _finished = true;
      _stopTimers();
      _resultTimer = Timer(const Duration(milliseconds: 500), widget.onDefeat);
    }
  }

  void _useAbility(ArenaAbility ability) {
    if (!_introComplete ||
        _finishing ||
        _finished ||
        _energy < ability.energyCost) {
      return;
    }
    final completesTutorial =
        _tutorialStage == _FinalBattleTutorialStage.useAbility;
    final damage = RottenShellFinalBattleLogic.abilityDamage(_fighter, ability);
    final finalAttack = RottenShellFinalBattleLogic.isFinalAttack(
      fighter: _fighter,
      ability: ability,
      bossHealth: _bossHealth,
    );
    if (finalAttack) {
      setState(() {
        _energy -= ability.energyCost;
        _bossHealth = 1;
        _finishing = true;
        _playerAttacking = true;
        _bossAttacking = false;
        _message = 'FINAL ATTACK';
      });
      _stopTimers();
      AudioScope.of(context).playSfx(Sfx.rageMode, volumeScale: 0.8);
      _beamController.forward();
      return;
    }

    setState(() {
      _energy -= ability.energyCost;
      _bossHealth = max(1, _bossHealth - damage);
      _applyAbilityEffect(ability);
      if (completesTutorial) {
        _tutorialStage = _FinalBattleTutorialStage.none;
      }
      _playerAttacking = true;
      _bossAttacking = false;
      _message = '${ability.name}  -$damage';
    });
    AudioScope.of(context).playSfx(Sfx.bossHit, volumeScale: 0.62);
    if (completesTutorial) _completeTutorial();
    _attackFlashTimer?.cancel();
    _attackFlashTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted && !_finished) setState(() => _playerAttacking = false);
    });
  }

  void _completeTutorial() {
    unawaited(
      SharedPreferences.getInstance().then(
        (preferences) => preferences.setBool(_tutorialCompletedKey, true),
      ),
    );
    _moveEnergy();
    _startCombatTimers();
  }

  void _applyAbilityEffect(ArenaAbility ability) {
    final amount = ArenaCombatLogic.supportAmount(_fighter, ability);
    switch (ability.effect) {
      case ArenaAbilityEffect.damage:
        break;
      case ArenaAbilityEffect.shield:
        _playerShield += amount;
      case ArenaAbilityEffect.heal:
        _playerHealth = min(_playerMaxHealth, _playerHealth + amount);
      case ArenaAbilityEffect.drain:
        _energy = min(ArenaCombatLogic.maxEnergy, _energy + 1);
    }
  }

  void _stopTimers() {
    _bossAttackTimer?.cancel();
    _energyMoveTimer?.cancel();
    _attackFlashTimer?.cancel();
  }

  @override
  void dispose() {
    _stopTimers();
    _resultTimer?.cancel();
    _introController.dispose();
    _beamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(_fighter.animalId)!;
    final mutation = GameData.mutationById(_fighter.mutationId)!;
    return Material(
      color: const Color(0xFF020817),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_introController, _beamController]),
            builder: (context, _) => CustomPaint(
              painter: _FinalBattleBackgroundPainter(
                progress: _introComplete ? 1 : _introController.value,
                beamProgress: _beamController.value,
                beamColor: _beamColor,
              ),
            ),
          ),
          if (_introComplete)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    const Text(
                      'FINAL BATTLE MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0xFF39D9FF), blurRadius: 12),
                          Shadow(color: Color(0xFF9C54FF), blurRadius: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FinalFighterPanel(
                      name: widget.boss.name,
                      health: _bossHealth,
                      maxHealth: _bossMaxHealth,
                      shield: 0,
                      accent: const Color(0xFF9C54FF),
                      identity: widget.boss.id,
                      reducedEffects: widget.reducedEffects,
                      attacking: _bossAttacking,
                      portrait: BossSprite(
                        spritePath: widget.boss.spritePath,
                        fallbackEmoji: widget.boss.emoji,
                        bossId: widget.boss.id,
                        size: 104,
                        semanticLabel: widget.boss.name,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const orbSize = 58.0;
                          final maxLeft = max(
                            0.0,
                            constraints.maxWidth - orbSize,
                          );
                          final maxTop = max(
                            0.0,
                            constraints.maxHeight - orbSize,
                          );
                          final left =
                              (_energyX * constraints.maxWidth - orbSize / 2)
                                  .clamp(0.0, maxLeft);
                          final top =
                              (_energyY * constraints.maxHeight - orbSize / 2)
                                  .clamp(0.0, maxTop);
                          return Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  padding:
                                      _tutorialStage ==
                                          _FinalBattleTutorialStage.none
                                      ? EdgeInsets.zero
                                      : const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                  decoration:
                                      _tutorialStage ==
                                          _FinalBattleTutorialStage.none
                                      ? null
                                      : BoxDecoration(
                                          color: const Color(0xEE071326),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _goldenEnergy
                                                ? const Color(0xFFFFD54F)
                                                : const Color(0xFF39D9FF),
                                          ),
                                        ),
                                  child: Text(
                                    _message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _finishing
                                          ? _beamColor
                                          : Colors.white,
                                      fontSize: _finishing ? 24 : 14,
                                      fontWeight: FontWeight.w900,
                                      shadows: _finishing
                                          ? [
                                              Shadow(
                                                color: _beamColor,
                                                blurRadius: 20,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              if (_energyVisible && !_finishing)
                                Positioned(
                                  left: left,
                                  top: top,
                                  child: _EnergyOrb(
                                    golden: _goldenEnergy,
                                    onTap: _collectEnergy,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    _FinalFighterPanel(
                      name: mutation.fullName(animal),
                      health: _playerHealth,
                      maxHealth: _playerMaxHealth,
                      shield: _playerShield,
                      accent: _beamColor,
                      identity:
                          '${_fighter.animalId}:${_fighter.mutationId}:${_fighter.level}',
                      reducedEffects: widget.reducedEffects,
                      attacking: _playerAttacking,
                      portrait: GameAnimalPortrait(
                        customSprite: widget.fighterCustomSprite,
                        animalId: animal.id,
                        spritePath: animal.spritePath,
                        fallbackEmoji: mutation.displayEmoji(animal),
                        mutation: mutation,
                        size: 96,
                        semanticLabel: mutation.fullName(animal),
                        motion: _playerAttacking
                            ? AnimalMotionState.attack
                            : _bossAttacking
                            ? AnimalMotionState.hurt
                            : AnimalMotionState.idle,
                        attackDirection: const Offset(0, -1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FinalAbilityPanel(
                      abilities: _abilities,
                      fighter: _fighter,
                      bossHealth: _bossHealth,
                      energy: _energy,
                      enabled: !_finishing && !_finished,
                      tutorialUseAbility:
                          _tutorialStage ==
                          _FinalBattleTutorialStage.useAbility,
                      accent: _beamColor,
                      onAbility: _useAbility,
                    ),
                  ],
                ),
              ),
            ),
          if (!_introComplete)
            _FinalBattleIntro(progress: _introController, boss: widget.boss),
        ],
      ),
    );
  }
}

class _FinalFighterPanel extends StatelessWidget {
  const _FinalFighterPanel({
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.shield,
    required this.accent,
    required this.identity,
    required this.reducedEffects,
    required this.attacking,
    required this.portrait,
  });

  final String name;
  final int health;
  final int maxHealth;
  final int shield;
  final Color accent;
  final Object identity;
  final bool reducedEffects;
  final bool attacking;
  final Widget portrait;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: attacking ? 1.06 : 1,
    duration: const Duration(milliseconds: 140),
    child: Row(
      children: [
        SizedBox(width: 108, height: 108, child: Center(child: portrait)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              BattleHealthBar(
                value: health / maxHealth,
                identity: identity,
                height: 12,
                reducedEffects: reducedEffects,
              ),
              const SizedBox(height: 5),
              Text(
                '$health / $maxHealth HP${shield > 0 ? '  +$shield shield' : ''}',
                style: TextStyle(
                  color: accent.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FinalAbilityPanel extends StatelessWidget {
  const _FinalAbilityPanel({
    required this.abilities,
    required this.fighter,
    required this.bossHealth,
    required this.energy,
    required this.enabled,
    required this.tutorialUseAbility,
    required this.accent,
    required this.onAbility,
  });

  final List<ArenaAbility> abilities;
  final ArenaFighter fighter;
  final int bossHealth;
  final int energy;
  final bool enabled;
  final bool tutorialUseAbility;
  final Color accent;
  final ValueChanged<ArenaAbility> onAbility;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xEE071326),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF35D9FF)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 17),
            Text(
              '$energy / ${ArenaCombatLogic.maxEnergy} ENERGY',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: energy / ArenaCombatLogic.maxEnergy,
                minHeight: 7,
                color: const Color(0xFFFFD54F),
                backgroundColor: Colors.white12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < abilities.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final ability = abilities[i];
                    final finalAttack =
                        RottenShellFinalBattleLogic.isFinalAttack(
                          fighter: fighter,
                          ability: ability,
                          bossHealth: bossHealth,
                        );
                    final available = enabled && energy >= ability.energyCost;
                    return _FinalAbilityButton(
                      label: finalAttack ? 'Final attack' : ability.name,
                      energyCost: ability.energyCost,
                      enabled: available,
                      glowing: finalAttack || (tutorialUseAbility && available),
                      accent: accent,
                      onTap: () => onAbility(ability),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _FinalAbilityButton extends StatefulWidget {
  const _FinalAbilityButton({
    required this.label,
    required this.energyCost,
    required this.enabled,
    required this.glowing,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int energyCost;
  final bool enabled;
  final bool glowing;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_FinalAbilityButton> createState() => _FinalAbilityButtonState();
}

class _FinalAbilityButtonState extends State<_FinalAbilityButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (context, child) => Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: widget.glowing
            ? [
                BoxShadow(
                  color: widget.accent.withValues(
                    alpha: 0.35 + _pulse.value * 0.45,
                  ),
                  blurRadius: 8 + _pulse.value * 12,
                  spreadRadius: _pulse.value * 2,
                ),
              ]
            : null,
      ),
      child: FilledButton(
        onPressed: widget.enabled ? widget.onTap : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          backgroundColor: widget.glowing
              ? widget.accent
              : const Color(0xFF075E68),
          disabledBackgroundColor: widget.glowing
              ? widget.accent.withValues(alpha: 0.25)
              : Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.enabled ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${widget.energyCost} ENERGY',
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EnergyOrb extends StatelessWidget {
  const _EnergyOrb({required this.golden, required this.onTap});

  final bool golden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const Key('final-battle-energy'),
    button: true,
    label: golden ? 'Golden energy' : 'Energy',
    child: InkResponse(
      onTap: onTap,
      radius: 38,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: golden ? const Color(0xFFFFD54F) : const Color(0xFF3DE7FF),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: golden ? const Color(0xFFFFB300) : const Color(0xFF27C7FF),
              blurRadius: 22,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.bolt, color: Color(0xFF071326), size: 32),
      ),
    ),
  );
}

class _FinalBattleIntro extends StatelessWidget {
  const _FinalBattleIntro({required this.progress, required this.boss});

  final Animation<double> progress;
  final BossBattleDefinition boss;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) {
      final t = progress.value;
      final titleT = Curves.easeOutBack.transform(
        ((t - 0.15) / 0.35).clamp(0, 1),
      );
      final subT = Curves.easeOutCubic.transform(
        ((t - 0.45) / 0.30).clamp(0, 1),
      );
      final shake = sin(t * pi * 30) * 3;
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020816), Color(0xFF071D49), Color(0xFF02040E)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _IntroGlitchPainter(progress.value)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset((1 - titleT) * -90 + shake, 0),
                      child: Opacity(
                        opacity: titleT.clamp(0, 1),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'FINAL BATTLE MODE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF46DFFF),
                                  blurRadius: 14,
                                ),
                                Shadow(
                                  color: Color(0xFFAA4DFF),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Transform.translate(
                      offset: Offset((1 - subT) * 80 - shake, 0),
                      child: Opacity(
                        opacity: subT.clamp(0, 1),
                        child: Text(
                          'ONE ANIMAL  •  ${boss.name.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFDCEBFF),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Color(0xFF7C4DFF), blurRadius: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _IntroGlitchPainter extends CustomPainter {
  const _IntroGlitchPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 18; i++) {
      final color = i.isEven
          ? const Color(0xFF47E2FF)
          : const Color(0xFFA64DFF);
      final y = size.height * ((i * 0.071 + progress * 0.42) % 1);
      final width = size.width * (0.12 + (i % 7) * 0.065);
      final x =
          size.width * ((sin(progress * 9 + i * 1.6) + 1) / 2) - width / 2;
      canvas.drawRect(
        Rect.fromLTWH(x, y, width, 2 + (i % 4).toDouble()),
        Paint()..color = color.withValues(alpha: 0.34),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IntroGlitchPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FinalBattleBackgroundPainter extends CustomPainter {
  const _FinalBattleBackgroundPainter({
    required this.progress,
    required this.beamProgress,
    required this.beamColor,
  });

  final double progress;
  final double beamProgress;
  final Color beamColor;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF061B42), Color(0xFF020817), Color(0xFF10051E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final grid = Paint()
      ..color = const Color(0xFF5EDCFF).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 12; i++) {
      final y = size.height * i / 12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (beamProgress <= 0) return;
    final beamT = Curves.easeInCubic.transform(
      beamProgress.clamp(0, 0.58) / 0.58,
    );
    final start = Offset(size.width * 0.50, size.height * 0.69);
    final end = Offset(size.width * 0.50, size.height * 0.23);
    final currentEnd = Offset.lerp(start, end, beamT)!;
    final pulse = 0.75 + sin(beamProgress * pi * 22).abs() * 0.25;
    canvas.drawLine(
      start,
      currentEnd,
      Paint()
        ..color = beamColor.withValues(alpha: 0.42)
        ..strokeWidth = 62 * pulse
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawLine(
      start,
      currentEnd,
      Paint()
        ..color = beamColor
        ..strokeWidth = 30 * pulse
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      start,
      currentEnd,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..strokeWidth = 9 * pulse
        ..strokeCap = StrokeCap.round,
    );
    if (beamProgress > 0.56) {
      final burst = ((beamProgress - 0.56) / 0.44).clamp(0.0, 1.0);
      canvas.drawCircle(
        end,
        24 + burst * size.shortestSide * 0.34,
        Paint()
          ..color = beamColor.withValues(alpha: (1 - burst) * 0.82)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FinalBattleBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.beamProgress != beamProgress ||
      oldDelegate.beamColor != beamColor;
}
