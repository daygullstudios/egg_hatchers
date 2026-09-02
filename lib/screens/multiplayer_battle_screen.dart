import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/arena_ability_data.dart';
import '../data/audio_assets.dart';
import '../data/game_data.dart';
import '../models/arena.dart';
import '../models/multiplayer.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/multiplayer_service.dart';
import '../services/preferences_service.dart';
import '../utils/arena_combat_logic.dart';
import '../utils/arena_logic.dart';
import '../utils/format_utils.dart';
import '../utils/game_haptics.dart';
import '../widgets/audio_scope.dart';
import '../widgets/animal_motion.dart';
import '../widgets/battle_ability_button.dart';
import '../widgets/battle_combo_badge.dart';
import '../widgets/battle_hit_feedback.dart';
import '../widgets/battle_health_bar.dart';
import '../widgets/battle_fighter_switcher.dart';
import '../widgets/game_sprite.dart';

class MultiplayerBattleScreen extends StatefulWidget {
  const MultiplayerBattleScreen({
    super.key,
    required this.multiplayer,
    required this.game,
    required this.player,
    required this.opponent,
    required this.customSprites,
    required this.preferences,
  });

  final MultiplayerService multiplayer;
  final GameService game;
  final MultiplayerPlayerSnapshot player;
  final MultiplayerPlayerSnapshot opponent;
  final CustomSpriteService customSprites;
  final PreferencesService preferences;

  @override
  State<MultiplayerBattleScreen> createState() =>
      _MultiplayerBattleScreenState();
}

class _MultiplayerBattleScreenState extends State<MultiplayerBattleScreen> {
  Timer? _attackTimer;
  var _playerAttacking = false;
  var _opponentAttacking = false;
  var _lastRevision = -1;
  var _resultSoundPlayed = false;
  int? _lastSelfHealthTotal;
  int? _lastOpponentHealthTotal;
  var _impactRevision = 0;
  var _impactDamage = 0;
  var _impactPlayerTarget = false;
  ArenaReward? _reward;
  var _rewardApplied = false;

  List<ArenaFighter> get _playerTeam =>
      widget.player.team.map(_arenaFighterFromSnapshot).toList(growable: false);

  List<ArenaFighter> get _opponentTeam => widget.opponent.team
      .map(_arenaFighterFromSnapshot)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final initialState = widget.multiplayer.battleState;
    if (initialState != null) {
      _lastRevision = initialState.revision;
      _lastSelfHealthTotal = initialState.self.health.fold<int>(
        0,
        (sum, hp) => sum + hp,
      );
      _lastOpponentHealthTotal = initialState.opponent.health.fold<int>(
        0,
        (sum, hp) => sum + hp,
      );
    }
    widget.multiplayer.addListener(_onMultiplayerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AudioScope.maybeOf(context)?.playMusic(MusicTrack.bossBattle);
      widget.multiplayer.enterBattle();
    });
  }

  void _onMultiplayerChanged() {
    if (!mounted) return;
    final state = widget.multiplayer.battleState;
    if (state != null && state.revision != _lastRevision) {
      _lastRevision = state.revision;
      final actorId = state.lastActorId;
      final selfHealthTotal = state.self.health.fold(0, (sum, hp) => sum + hp);
      final opponentHealthTotal = state.opponent.health.fold(
        0,
        (sum, hp) => sum + hp,
      );
      final playerWasTarget = actorId == widget.opponent.playerId;
      final previousTargetHealth = playerWasTarget
          ? _lastSelfHealthTotal
          : _lastOpponentHealthTotal;
      if (actorId != null && previousTargetHealth != null && !state.finished) {
        final currentTargetHealth = playerWasTarget
            ? selfHealthTotal
            : opponentHealthTotal;
        _impactRevision++;
        _impactDamage = max(0, previousTargetHealth - currentTargetHealth);
        _impactPlayerTarget = playerWasTarget;
      }
      _lastSelfHealthTotal = selfHealthTotal;
      _lastOpponentHealthTotal = opponentHealthTotal;
      _attackTimer?.cancel();
      _playerAttacking = actorId == widget.player.playerId;
      _opponentAttacking = actorId == widget.opponent.playerId;
      if (actorId != null && !state.finished) {
        AudioScope.maybeOf(context)?.playSfx(
          actorId == widget.player.playerId ? Sfx.bossHit : Sfx.playerHit,
          volumeScale: 0.58,
        );
        if (actorId == widget.player.playerId) {
          GameHaptics.attack(enabled: widget.preferences.hapticsEnabled);
        } else {
          GameHaptics.damage(enabled: widget.preferences.hapticsEnabled);
        }
      }
      _attackTimer = Timer(const Duration(milliseconds: 240), () {
        if (!mounted) return;
        setState(() {
          _playerAttacking = false;
          _opponentAttacking = false;
        });
      });
      if (state.finished && !_resultSoundPlayed) {
        _resultSoundPlayed = true;
        final won = state.winnerId == widget.player.playerId;
        AudioScope.maybeOf(context)?.playSfx(won ? Sfx.victory : Sfx.defeat);
        GameHaptics.result(
          enabled: widget.preferences.hapticsEnabled,
          won: won,
        );
      }
      if (state.finished && !_rewardApplied) {
        _applyReward(state);
      }
    }
    setState(() {});
  }

  void _applyReward(MultiplayerBattleState state) {
    _rewardApplied = true;
    final won = state.winnerId == widget.player.playerId;
    final reward = ArenaLogic.rewardFor(
      won: won,
      playerRating: widget.player.rating,
      opponentRating: widget.opponent.rating,
      opponentPower: widget.opponent.team.fold(
        0,
        (sum, fighter) => sum + fighter.power,
      ),
      currentStreak: widget.game.arenaWinStreak,
    );
    _reward = reward;
    widget.game.applyArenaResult(won: won, reward: reward);
  }

  void _collectEnergy() {
    final spawn = widget.multiplayer.energySpawn;
    if (spawn == null) return;
    widget.multiplayer.collectEnergy(spawn.id);
    AudioScope.maybeOf(context)?.playSfx(Sfx.uiTap, volumeScale: 0.42);
    GameHaptics.selection(enabled: widget.preferences.hapticsEnabled);
  }

  void _switchFighter(int index) {
    GameHaptics.selection(enabled: widget.preferences.hapticsEnabled);
    widget.multiplayer.switchFighter(index);
  }

  void _continue() {
    widget.multiplayer.clearMatch();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _attackTimer?.cancel();
    widget.multiplayer.removeListener(_onMultiplayerChanged);
    if (!(widget.multiplayer.battleState?.finished ?? false)) {
      widget.multiplayer.leaveBattle();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.multiplayer.battleState;
    if (state == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF07131C),
        body: _WaitingForPlayer(),
      );
    }
    final playerTeam = _playerTeam;
    final opponentTeam = _opponentTeam;
    final playerFighter = playerTeam[state.self.activeIndex];
    final opponentFighter = opponentTeam[state.opponent.activeIndex];
    final abilities = ArenaAbilityData.forAnimal(playerFighter.animalId);
    final spawn = widget.multiplayer.energySpawn;
    final finished = state.finished;

    return PopScope(
      canPop: finished,
      child: Scaffold(
        backgroundColor: const Color(0xFF07131C),
        body: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _OnlineArenaPainter()),
            ),
            SafeArea(
              child: Column(
                children: [
                  _OnlineBattleTopBar(
                    opponent: widget.opponent,
                    playerEnergy: state.self.energy,
                    opponentEnergy: state.opponent.energy,
                    canLeave: finished,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const circleSize = 64.0;
                        final compact = constraints.maxHeight < 430;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  BattleFighterSwitcher(
                                    identity:
                                        'opponent-${state.opponent.activeIndex}',
                                    isOpponent: true,
                                    reducedEffects:
                                        widget.preferences.reducedBattleEffects,
                                    child: _OnlineActiveFighter(
                                      fighter: opponentFighter,
                                      health: state
                                          .opponent
                                          .health[state.opponent.activeIndex],
                                      shield: state.opponent.shield,
                                      customSprites: widget.customSprites,
                                      isOpponent: true,
                                      isAttacking: _opponentAttacking,
                                      isHurt: _playerAttacking,
                                      isVictorious:
                                          finished &&
                                          state.winnerId ==
                                              widget.opponent.playerId,
                                      label: widget.opponent.displayName,
                                      compact: compact,
                                      reducedEffects: widget
                                          .preferences
                                          .reducedBattleEffects,
                                    ),
                                  ),
                                  _OnlineCombatMessage(
                                    message: state.message,
                                    finished: finished,
                                    combo: state.self.combo,
                                    reducedEffects:
                                        widget.preferences.reducedBattleEffects,
                                  ),
                                  BattleFighterSwitcher(
                                    identity: 'self-${state.self.activeIndex}',
                                    isOpponent: false,
                                    reducedEffects:
                                        widget.preferences.reducedBattleEffects,
                                    child: _OnlineActiveFighter(
                                      fighter: playerFighter,
                                      health: state
                                          .self
                                          .health[state.self.activeIndex],
                                      shield: state.self.shield,
                                      customSprites: widget.customSprites,
                                      isOpponent: false,
                                      isAttacking: _playerAttacking,
                                      isHurt: _opponentAttacking,
                                      isVictorious:
                                          finished &&
                                          state.winnerId ==
                                              widget.player.playerId,
                                      label: widget.player.displayName,
                                      compact: compact,
                                      reducedEffects: widget
                                          .preferences
                                          .reducedBattleEffects,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (spawn != null && !finished)
                              Positioned(
                                key: const ValueKey('multiplayer-energy'),
                                left:
                                    spawn.x *
                                    max(0, constraints.maxWidth - circleSize),
                                top:
                                    spawn.y *
                                    max(0, constraints.maxHeight - circleSize),
                                child: _OnlineEnergy(
                                  golden: spawn.golden,
                                  onTap: _collectEnergy,
                                ),
                              ),
                            Positioned.fill(
                              child: BattleHitFeedback(
                                trigger: _impactRevision,
                                alignment: Alignment(
                                  0,
                                  _impactPlayerTarget ? 0.55 : -0.55,
                                ),
                                damage: _impactDamage,
                                color: _impactPlayerTarget
                                    ? const Color(0xFFFF7043)
                                    : const Color(0xFF4DD0E1),
                                reducedEffects:
                                    widget.preferences.reducedBattleEffects,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _OnlineAbilityPanel(
                    abilities: abilities,
                    energy: state.self.energy,
                    hits: state.self.energyHits,
                    misses: state.self.energyMisses,
                    enabled: !finished,
                    reducedEffects: widget.preferences.reducedBattleEffects,
                    onAbility: widget.multiplayer.useAbility,
                  ),
                  _OnlineBenches(
                    playerTeam: playerTeam,
                    opponentTeam: opponentTeam,
                    playerHealth: state.self.health,
                    opponentHealth: state.opponent.health,
                    playerActiveIndex: state.self.activeIndex,
                    opponentActiveIndex: state.opponent.activeIndex,
                    customSprites: widget.customSprites,
                    onPlayerTap: _switchFighter,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            if (finished && _reward != null)
              Positioned.fill(
                child: _OnlineResultOverlay(
                  won: state.winnerId == widget.player.playerId,
                  opponentName: widget.opponent.displayName,
                  reward: _reward!,
                  rating: widget.game.arenaRating,
                  onContinue: _continue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

ArenaFighter _arenaFighterFromSnapshot(MultiplayerFighterSnapshot fighter) {
  return ArenaFighter(
    animalId: fighter.animalId,
    mutationId: fighter.mutationId,
    level: fighter.level,
    power: fighter.power,
  );
}

class _WaitingForPlayer extends StatelessWidget {
  const _WaitingForPlayer();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 36,
              child: CircularProgressIndicator(color: Color(0xFF70D9FF)),
            ),
            SizedBox(height: 18),
            Text(
              'WAITING FOR OPPONENT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineBattleTopBar extends StatelessWidget {
  const _OnlineBattleTopBar({
    required this.opponent,
    required this.playerEnergy,
    required this.opponentEnergy,
    required this.canLeave,
  });

  final MultiplayerPlayerSnapshot opponent;
  final int playerEnergy;
  final int opponentEnergy;
  final bool canLeave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 14, 3),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave battle',
            onPressed: canLeave ? () => Navigator.pop(context) : null,
            icon: const Icon(Icons.close),
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'ONLINE MATCH',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'VS ${opponent.displayName.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'YOU $playerEnergy',
                style: const TextStyle(
                  color: Color(0xFF4DD0E1),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'THEM $opponentEnergy',
                style: const TextStyle(
                  color: Color(0xFFFF8A65),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnlineEnergy extends StatelessWidget {
  const _OnlineEnergy({required this.golden, required this.onTap});

  final bool golden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: golden ? const Color(0xFFFFC107) : const Color(0xFF26C6DA),
        shape: const CircleBorder(),
        elevation: 12,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 64,
            child: Icon(
              golden ? Icons.bolt : Icons.add,
              color: const Color(0xFF07131C),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineActiveFighter extends StatelessWidget {
  const _OnlineActiveFighter({
    required this.fighter,
    required this.health,
    required this.shield,
    required this.customSprites,
    required this.isOpponent,
    required this.isAttacking,
    required this.isHurt,
    required this.isVictorious,
    required this.label,
    required this.compact,
    required this.reducedEffects,
  });

  final ArenaFighter fighter;
  final int health;
  final int shield;
  final CustomSpriteService customSprites;
  final bool isOpponent;
  final bool isAttacking;
  final bool isHurt;
  final bool isVictorious;
  final String label;
  final bool compact;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(fighter.animalId)!;
    final mutation = GameData.mutationById(fighter.mutationId)!;
    final fraction = (health / fighter.maxHealth).clamp(0.0, 1.0);
    final portraitSize = compact ? 70.0 : 92.0;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 170),
      offset: isAttacking ? Offset(0, isOpponent ? 0.13 : -0.13) : Offset.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedScale(
            duration: const Duration(milliseconds: 170),
            scale: isAttacking ? 1.1 : 1,
            child: Container(
              width: portraitSize + 10,
              height: portraitSize + 10,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpponent
                    ? const Color(0xFF4E1D1D)
                    : const Color(0xFF123F43),
                border: Border.all(
                  color: isOpponent
                      ? const Color(0xFFFF7043)
                      : const Color(0xFF4DD0E1),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: GameAnimalPortrait(
                  customSprite: customSprites.getDisplaySprite(animal.id),
                  animalId: animal.id,
                  spritePath: animal.spritePath,
                  fallbackEmoji: animal.emoji,
                  mutation: mutation,
                  size: portraitSize,
                  motion: isVictorious
                      ? AnimalMotionState.victory
                      : isAttacking
                      ? AnimalMotionState.attack
                      : isHurt
                      ? AnimalMotionState.hurt
                      : AnimalMotionState.idle,
                  attackDirection: Offset(0, isOpponent ? 1 : -1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            mutation.fullName(animal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: compact ? 160 : 190,
            child: BattleHealthBar(
              value: fraction,
              identity:
                  '${fighter.animalId}:${fighter.mutationId}:${fighter.level}:${fighter.power}',
              height: 11,
              reducedEffects: reducedEffects,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shield > 0
                ? '$health / ${fighter.maxHealth}  +$shield shield'
                : '$health / ${fighter.maxHealth}',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _OnlineCombatMessage extends StatelessWidget {
  const _OnlineCombatMessage({
    required this.message,
    required this.finished,
    required this.combo,
    required this.reducedEffects,
  });

  final String message;
  final bool finished;
  final int combo;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            finished ? 'MATCH COMPLETE' : message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
          if (!finished)
            BattleComboBadge(combo: combo, reducedEffects: reducedEffects),
        ],
      ),
    );
  }
}

class _OnlineAbilityPanel extends StatelessWidget {
  const _OnlineAbilityPanel({
    required this.abilities,
    required this.energy,
    required this.hits,
    required this.misses,
    required this.enabled,
    required this.reducedEffects,
    required this.onAbility,
  });

  final List<ArenaAbility> abilities;
  final int energy;
  final int hits;
  final int misses;
  final bool enabled;
  final bool reducedEffects;
  final ValueChanged<int> onAbility;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xE612222B),
        border: Border.all(color: const Color(0xFF26C6DA), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 17),
              Text(
                '$energy / ${ArenaCombatLogic.maxEnergy}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: LinearProgressIndicator(
                  value: energy / ArenaCombatLogic.maxEnergy,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFFFFC107),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$hits hit  $misses miss',
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(abilities.length, (index) {
              final ability = abilities[index];
              final available = enabled && energy >= ability.energyCost;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
                  child: BattleAbilityButton(
                    key: ValueKey('online-ability-$index'),
                    ability: ability,
                    available: available,
                    reducedEffects: reducedEffects,
                    compact: true,
                    onPressed: () => onAbility(index),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OnlineBenches extends StatelessWidget {
  const _OnlineBenches({
    required this.playerTeam,
    required this.opponentTeam,
    required this.playerHealth,
    required this.opponentHealth,
    required this.playerActiveIndex,
    required this.opponentActiveIndex,
    required this.customSprites,
    required this.onPlayerTap,
  });

  final List<ArenaFighter> playerTeam;
  final List<ArenaFighter> opponentTeam;
  final List<int> playerHealth;
  final List<int> opponentHealth;
  final int playerActiveIndex;
  final int opponentActiveIndex;
  final CustomSpriteService customSprites;
  final ValueChanged<int> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BenchSide(
            team: playerTeam,
            health: playerHealth,
            activeIndex: playerActiveIndex,
            customSprites: customSprites,
            onTap: onPlayerTap,
          ),
          const Text(
            'TEAMS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          _BenchSide(
            team: opponentTeam,
            health: opponentHealth,
            activeIndex: opponentActiveIndex,
            customSprites: customSprites,
          ),
        ],
      ),
    );
  }
}

class _BenchSide extends StatelessWidget {
  const _BenchSide({
    required this.team,
    required this.health,
    required this.activeIndex,
    required this.customSprites,
    this.onTap,
  });

  final List<ArenaFighter> team;
  final List<int> health;
  final int activeIndex;
  final CustomSpriteService customSprites;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(team.length, (index) {
        final fighter = team[index];
        final animal = GameData.animalById(fighter.animalId)!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap != null && health[index] > 0
                ? () => onTap!(index)
                : null,
            child: Opacity(
              opacity: health[index] > 0 ? 1 : 0.25,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index == activeIndex
                        ? const Color(0xFFFFD54F)
                        : Colors.white24,
                    width: index == activeIndex ? 2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: GameAnimalPortrait(
                    customSprite: customSprites.getDisplaySprite(animal.id),
                    animalId: animal.id,
                    spritePath: animal.spritePath,
                    fallbackEmoji: animal.emoji,
                    mutation: GameData.mutationById(fighter.mutationId),
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OnlineResultOverlay extends StatelessWidget {
  const _OnlineResultOverlay({
    required this.won,
    required this.opponentName,
    required this.reward,
    required this.rating,
    required this.onContinue,
  });

  final bool won;
  final String opponentName;
  final ArenaReward reward;
  final int rating;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    won ? Icons.emoji_events : Icons.shield_outlined,
                    color: won
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF90A4AE),
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    won ? 'ONLINE VICTORY' : 'TEAM DEFEATED',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? 'You defeated $opponentName.'
                        : '$opponentName won this match.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ArenaLogic.divisionFor(rating)}  |  $rating rating',
                    style: const TextStyle(
                      color: Color(0xFF70D9FF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _OnlineRewardStat(
                        icon: Icons.trending_up,
                        value:
                            '${reward.ratingChange >= 0 ? '+' : ''}${reward.ratingChange}',
                        label: 'RATING',
                      ),
                      _OnlineRewardStat(
                        icon: Icons.monetization_on,
                        value: formatCoins(reward.coins),
                        label: 'COINS',
                      ),
                      _OnlineRewardStat(
                        icon: Icons.sports_martial_arts,
                        value: '${reward.battleTokens}',
                        label: 'TOKENS',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey('online-battle-continue'),
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'CONTINUE',
                        style: TextStyle(fontWeight: FontWeight.w900),
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

class _OnlineRewardStat extends StatelessWidget {
  const _OnlineRewardStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD54F), size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OnlineArenaPainter extends CustomPainter {
  const _OnlineArenaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF15143A), Color(0xFF07131C), Color(0xFF102B2E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final line = Paint()
      ..color = const Color(0xFF70D9FF).withValues(alpha: 0.09)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
