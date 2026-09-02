import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/arena_ability_data.dart';
import '../data/audio_assets.dart';
import '../data/game_data.dart';
import '../models/arena.dart';
import '../models/background_theme.dart';
import '../models/owned_animal.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/preferences_service.dart';
import '../theme/game_theme.dart';
import '../utils/arena_logic.dart';
import '../utils/arena_combat_logic.dart';
import '../utils/battle_power_logic.dart';
import '../utils/format_utils.dart';
import '../widgets/audio_scope.dart';
import '../widgets/animal_motion.dart';
import '../widgets/battle_hit_feedback.dart';
import '../widgets/battle_health_bar.dart';
import '../widgets/game_background.dart';
import '../widgets/game_sprite.dart';
import '../widgets/phone_width_layout.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final _random = Random();
  List<OwnedAnimal> _team = [];
  List<ArenaOpponent> _challengers = [];

  @override
  void initState() {
    super.initState();
    _team = ArenaLogic.recommendedTeam(widget.game.state.ownedAnimals);
    _refreshChallengers();
  }

  void _refreshChallengers() {
    if (_team.isEmpty) {
      _challengers = [];
      return;
    }
    _challengers = ArenaLogic.generateOpponentRoster(
      playerTeam: _team.map(ArenaLogic.fighterFromOwned).toList(),
      playerRating: widget.game.arenaRating,
      random: _random,
    );
  }

  void _toggleTeamMember(OwnedAnimal owned) {
    final key = ArenaLogic.ownedKey(owned);
    final existing = _team.indexWhere(
      (item) => ArenaLogic.ownedKey(item) == key,
    );
    setState(() {
      if (existing >= 0) {
        _team.removeAt(existing);
      } else if (_team.length < ArenaLogic.teamSize) {
        _team.add(owned);
      } else {
        _team[_team.length - 1] = owned;
      }
      _refreshChallengers();
    });
  }

  Future<void> _chooseTeam(BackgroundTheme theme) async {
    final owned = [...widget.game.state.ownedAnimals]
      ..sort(
        (a, b) => BattlePowerLogic.battlePowerForOwnedAnimal(
          b,
        ).compareTo(BattlePowerLogic.battlePowerForOwnedAnimal(a)),
      );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) {
          final selectedKeys = _team.map(ArenaLogic.ownedKey).toSet();
          return Container(
            height: MediaQuery.sizeOf(context).height * 0.78,
            decoration: BoxDecoration(
              color: theme.panelColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: theme.panelAccentColor, width: 2),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose your team',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: theme.cardTextPrimaryColor,
                              ),
                            ),
                            Text(
                              '${_team.length}/${ArenaLogic.teamSize} selected',
                              style: TextStyle(
                                color: theme.cardTextSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Done',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.check_circle),
                        color: theme.primaryColor,
                        iconSize: 30,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    itemCount: owned.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = owned[index];
                      final selected = selectedKeys.contains(
                        ArenaLogic.ownedKey(item),
                      );
                      final animal = GameData.animalById(item.animalId)!;
                      final mutation = GameData.mutationById(item.mutationId)!;
                      return Material(
                        color: selected
                            ? theme.primaryColor.withValues(alpha: 0.14)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            _toggleTeamMember(item);
                            refreshSheet(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                GameAnimalPortrait(
                                  customSprite: widget.customSprites
                                      .getDisplaySprite(animal.id),
                                  animalId: animal.id,
                                  spritePath: animal.spritePath,
                                  fallbackEmoji: animal.emoji,
                                  mutation: mutation,
                                  size: 58,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mutation.fullName(animal),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: theme.cardTextPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Lv ${item.level}  |  ${formatCoins(BattlePowerLogic.battlePowerForOwnedAnimal(item))} power',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.cardTextSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: selected
                                      ? theme.primaryColor
                                      : theme.cardTextSecondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _fight(BackgroundTheme theme, ArenaOpponent opponent) async {
    if (_team.isEmpty) return;
    final simulation = ArenaLogic.simulate(
      playerTeam: _team.map(ArenaLogic.fighterFromOwned).toList(),
      opponent: opponent,
    );
    await pushThemedAppRoute<void>(
      context,
      theme: theme,
      settings: const RouteSettings(name: kArenaBattleRouteName),
      builder: (_) => ArenaBattleScreen(
        game: widget.game,
        preferences: widget.preferences,
        customSprites: widget.customSprites,
        simulation: simulation,
      ),
    );
    if (!mounted) return;
    await AudioScope.of(context).playMusic(MusicTrack.hatchery);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.game,
        widget.preferences,
        widget.customSprites,
      ]),
      builder: (context, _) {
        final theme = widget.preferences.selectedTheme;
        final playerFighters = _team.map(ArenaLogic.fighterFromOwned).toList();
        final playerPower = playerFighters.fold(
          0,
          (sum, fighter) => sum + fighter.power,
        );
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: 'Arena',
            titleStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
            backgroundColor: const Color(0xFF263238),
            foregroundColor: Colors.white,
          ),
          body: GameBackground(
            theme: theme,
            child: PhoneWidthLayout(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  _ArenaRecordBanner(game: widget.game),
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: 'Your lineup',
                    actionLabel: 'EDIT',
                    onTap: () => _chooseTeam(theme),
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                  _TeamStrip(
                    team: playerFighters,
                    theme: theme,
                    customSprites: widget.customSprites,
                    emptyLabel: 'Choose an animal',
                    onTap: () => _chooseTeam(theme),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeading(title: 'Challengers', theme: theme),
                  const SizedBox(height: 10),
                  if (_challengers.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _challengers.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final challenger = _challengers[index];
                        return _ChallengerCard(
                          opponent: challenger,
                          playerPower: playerPower,
                          theme: theme,
                          customSprites: widget.customSprites,
                          onChallenge: _team.isEmpty
                              ? null
                              : () => _fight(theme, challenger),
                        );
                      },
                    )
                  else
                    _EmptyArenaCard(theme: theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ArenaBattleScreen extends StatefulWidget {
  const ArenaBattleScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
    required this.simulation,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final ArenaBattleSimulation simulation;

  @override
  State<ArenaBattleScreen> createState() => _ArenaBattleScreenState();
}

class _ArenaBattleScreenState extends State<ArenaBattleScreen> {
  Timer? _circleSpawnTimer;
  Timer? _circleLifetimeTimer;
  Timer? _botTimer;
  Timer? _attackTimer;
  late final Random _battleRandom;
  late final List<int> _playerHealth;
  late final List<int> _botHealth;
  ArenaReward? _reward;
  var _playerActiveIndex = 0;
  var _botActiveIndex = 0;
  var _playerEnergy = 0;
  var _botEnergy = 0;
  var _playerShield = 0;
  var _botShield = 0;
  var _circleX = 0.5;
  var _circleY = 0.5;
  var _circleVisible = false;
  var _circleIsGolden = false;
  var _combo = 0;
  var _bestCombo = 0;
  var _circlesHit = 0;
  var _circlesMissed = 0;
  var _playerAttacking = false;
  var _botAttacking = false;
  var _impactRevision = 0;
  var _impactDamage = 0;
  var _impactPlayerTarget = false;
  var _battleMessage = 'Collect energy!';
  var _finished = false;
  var _rewardApplied = false;
  bool? _playerWon;

  @override
  void initState() {
    super.initState();
    _battleRandom = Random(widget.simulation.opponent.seed);
    _playerHealth = widget.simulation.playerTeam
        .map((fighter) => fighter.maxHealth)
        .toList();
    _botHealth = widget.simulation.opponent.team
        .map((fighter) => fighter.maxHealth)
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AudioScope.of(context).playMusic(MusicTrack.bossBattle);
      _scheduleCircle(initial: true);
      _botTimer = Timer.periodic(
        ArenaCombatLogic.botEnergyInterval(widget.simulation.opponent.rating),
        (_) => _botTick(),
      );
    });
  }

  void _scheduleCircle({bool initial = false}) {
    _circleSpawnTimer?.cancel();
    _circleLifetimeTimer?.cancel();
    if (_finished) return;
    final delay = initial
        ? const Duration(milliseconds: 650)
        : ArenaCombatLogic.nextCircleDelay(_battleRandom);
    _circleSpawnTimer = Timer(delay, () {
      if (!mounted || _finished) return;
      setState(() {
        _circleX = 0.08 + _battleRandom.nextDouble() * 0.84;
        _circleY = 0.08 + _battleRandom.nextDouble() * 0.84;
        _circleIsGolden = _battleRandom.nextInt(10) == 0;
        _circleVisible = true;
      });
      _circleLifetimeTimer = Timer(ArenaCombatLogic.circleLifetime, () {
        if (!mounted || !_circleVisible || _finished) return;
        setState(() {
          _circleVisible = false;
          _combo = 0;
          _circlesMissed++;
          _battleMessage = 'Missed! Next circle incoming...';
        });
        _scheduleCircle();
      });
    });
  }

  void _collectEnergy() {
    if (!_circleVisible || _finished) return;
    _circleLifetimeTimer?.cancel();
    final gain = _circleIsGolden ? 2 : 1;
    setState(() {
      _circleVisible = false;
      _playerEnergy = min(ArenaCombatLogic.maxEnergy, _playerEnergy + gain);
      _combo++;
      _bestCombo = max(_bestCombo, _combo);
      _circlesHit++;
      _battleMessage = _circleIsGolden
          ? '+2 energy! Golden circle'
          : '+1 energy  |  $_combo combo';
    });
    AudioScope.of(context).playSfx(Sfx.uiTap, volumeScale: 0.42);
    _scheduleCircle();
  }

  void _botTick() {
    if (_finished || !mounted) return;
    setState(() {
      _botEnergy = min(ArenaCombatLogic.maxEnergy, _botEnergy + 1);
    });
    final style = ArenaCombatLogic.botStyleForTitle(
      widget.simulation.opponent.title,
    );
    if (!ArenaCombatLogic.botShouldSpend(
      energy: _botEnergy,
      style: style,
      random: _battleRandom,
    )) {
      return;
    }
    final fighter = widget.simulation.opponent.team[_botActiveIndex];
    final abilities = ArenaAbilityData.forAnimal(fighter.animalId);
    final ability = ArenaCombatLogic.chooseBotAbility(
      abilities: abilities,
      energy: _botEnergy,
      healthFraction: _botHealth[_botActiveIndex] / fighter.maxHealth,
      random: _battleRandom,
      style: style,
    );
    if (ability != null) _useBotAbility(ability);
  }

  void _usePlayerAbility(ArenaAbility ability) {
    if (_finished || _playerEnergy < ability.energyCost) return;
    final attacker = widget.simulation.playerTeam[_playerActiveIndex];
    final defender = widget.simulation.opponent.team[_botActiveIndex];
    final damage = ArenaCombatLogic.attackDamage(
      attacker: attacker,
      defender: defender,
      ability: ability,
      random: _battleRandom,
    );
    setState(() {
      _playerEnergy -= ability.energyCost;
      final dealt = _damageAfterShield(damage, playerTarget: false);
      _botHealth[_botActiveIndex] = max(0, _botHealth[_botActiveIndex] - dealt);
      _impactRevision++;
      _impactDamage = dealt;
      _impactPlayerTarget = false;
      _applyPlayerEffect(attacker, ability);
      _playerAttacking = true;
      _botAttacking = false;
      _battleMessage = '${ability.name}  -$dealt';
    });
    AudioScope.of(context).playSfx(Sfx.bossHit, volumeScale: 0.58);
    _resetAttackFlash();
    _resolveDefeat(playerTarget: false);
  }

  void _useBotAbility(ArenaAbility ability) {
    if (_finished || _botEnergy < ability.energyCost) return;
    final attacker = widget.simulation.opponent.team[_botActiveIndex];
    final defender = widget.simulation.playerTeam[_playerActiveIndex];
    final damage = ArenaCombatLogic.attackDamage(
      attacker: attacker,
      defender: defender,
      ability: ability,
      random: _battleRandom,
    );
    setState(() {
      _botEnergy -= ability.energyCost;
      final dealt = _damageAfterShield(damage, playerTarget: true);
      _playerHealth[_playerActiveIndex] = max(
        0,
        _playerHealth[_playerActiveIndex] - dealt,
      );
      _impactRevision++;
      _impactDamage = dealt;
      _impactPlayerTarget = true;
      _applyBotEffect(attacker, ability);
      _botAttacking = true;
      _playerAttacking = false;
      _battleMessage =
          '${widget.simulation.opponent.name}: ${ability.name}  -$dealt';
    });
    AudioScope.of(context).playSfx(Sfx.playerHit, volumeScale: 0.58);
    _resetAttackFlash();
    _resolveDefeat(playerTarget: true);
  }

  int _damageAfterShield(int damage, {required bool playerTarget}) {
    final shield = playerTarget ? _playerShield : _botShield;
    final absorbed = min(shield, damage);
    if (playerTarget) {
      _playerShield -= absorbed;
    } else {
      _botShield -= absorbed;
    }
    return damage - absorbed;
  }

  void _applyPlayerEffect(ArenaFighter fighter, ArenaAbility ability) {
    final amount = ArenaCombatLogic.supportAmount(fighter, ability);
    switch (ability.effect) {
      case ArenaAbilityEffect.damage:
        break;
      case ArenaAbilityEffect.shield:
        _playerShield += amount;
      case ArenaAbilityEffect.heal:
        _playerHealth[_playerActiveIndex] = min(
          fighter.maxHealth,
          _playerHealth[_playerActiveIndex] + amount,
        );
      case ArenaAbilityEffect.drain:
        final drained = min(_botEnergy, ability.effectScale.round());
        _botEnergy -= drained;
        _playerEnergy = min(
          ArenaCombatLogic.maxEnergy,
          _playerEnergy + drained,
        );
    }
  }

  void _applyBotEffect(ArenaFighter fighter, ArenaAbility ability) {
    final amount = ArenaCombatLogic.supportAmount(fighter, ability);
    switch (ability.effect) {
      case ArenaAbilityEffect.damage:
        break;
      case ArenaAbilityEffect.shield:
        _botShield += amount;
      case ArenaAbilityEffect.heal:
        _botHealth[_botActiveIndex] = min(
          fighter.maxHealth,
          _botHealth[_botActiveIndex] + amount,
        );
      case ArenaAbilityEffect.drain:
        final drained = min(_playerEnergy, ability.effectScale.round());
        _playerEnergy -= drained;
        _botEnergy = min(ArenaCombatLogic.maxEnergy, _botEnergy + drained);
    }
  }

  void _resetAttackFlash() {
    _attackTimer?.cancel();
    _attackTimer = Timer(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      setState(() {
        _playerAttacking = false;
        _botAttacking = false;
      });
    });
  }

  void _resolveDefeat({required bool playerTarget}) {
    final health = playerTarget ? _playerHealth : _botHealth;
    final active = playerTarget ? _playerActiveIndex : _botActiveIndex;
    if (health[active] > 0) return;
    final next = health.indexWhere((value) => value > 0);
    if (next < 0) {
      _finish(playerWon: !playerTarget);
      return;
    }
    setState(() {
      if (playerTarget) {
        _playerActiveIndex = next;
        _playerShield = 0;
        _battleMessage = 'Your next animal enters!';
      } else {
        _botActiveIndex = next;
        _botShield = 0;
        _battleMessage =
            '${widget.simulation.opponent.name} sends in the next animal!';
      }
    });
  }

  void _switchPlayer(int index) {
    if (_finished ||
        index == _playerActiveIndex ||
        _playerHealth[index] <= 0 ||
        _playerEnergy < ArenaCombatLogic.switchEnergyCost) {
      return;
    }
    setState(() {
      _playerEnergy -= ArenaCombatLogic.switchEnergyCost;
      _playerActiveIndex = index;
      _playerShield = 0;
      _battleMessage = 'Switched fighters  |  -1 energy';
    });
  }

  void _finish({required bool playerWon}) {
    if (_finished) return;
    _circleSpawnTimer?.cancel();
    _circleLifetimeTimer?.cancel();
    _botTimer?.cancel();
    final reward = ArenaLogic.rewardFor(
      won: playerWon,
      playerRating: widget.game.arenaRating,
      opponentRating: widget.simulation.opponent.rating,
      opponentPower: widget.simulation.opponent.totalPower,
      currentStreak: widget.game.arenaWinStreak,
    );
    setState(() {
      _finished = true;
      _circleVisible = false;
      _playerWon = playerWon;
      _reward = reward;
      _battleMessage = playerWon ? 'Arena victory!' : 'Team defeated';
    });
    if (!_rewardApplied) {
      _rewardApplied = true;
      widget.game.applyArenaResult(won: playerWon, reward: reward);
      AudioScope.of(context).playSfx(playerWon ? Sfx.victory : Sfx.defeat);
    }
  }

  @override
  void dispose() {
    _circleSpawnTimer?.cancel();
    _circleLifetimeTimer?.cancel();
    _botTimer?.cancel();
    _attackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerFighter = widget.simulation.playerTeam[_playerActiveIndex];
    final botFighter = widget.simulation.opponent.team[_botActiveIndex];
    final abilities = ArenaAbilityData.forAnimal(playerFighter.animalId);
    return PopScope(
      canPop: _finished,
      child: Scaffold(
        backgroundColor: const Color(0xFF07131C),
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _ArenaPainter())),
            SafeArea(
              child: Column(
                children: [
                  _BattleTopBar(
                    opponent: widget.simulation.opponent,
                    playerEnergy: _playerEnergy,
                    botEnergy: _botEnergy,
                    canLeave: _finished,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const circleSize = 68.0;
                        final compact = constraints.maxHeight < 440;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _ActiveFighter(
                                    fighter: botFighter,
                                    health: _botHealth[_botActiveIndex],
                                    shield: _botShield,
                                    customSprites: widget.customSprites,
                                    isOpponent: true,
                                    isAttacking: _botAttacking && !_finished,
                                    isHurt: _playerAttacking && !_finished,
                                    isVictorious:
                                        _finished && _playerWon == false,
                                    label: widget.simulation.opponent.name,
                                    compact: compact,
                                    reducedEffects:
                                        widget.preferences.reducedBattleEffects,
                                  ),
                                  _CombatPulse(
                                    message: _battleMessage,
                                    combo: _combo,
                                    finished: _finished,
                                  ),
                                  _ActiveFighter(
                                    fighter: playerFighter,
                                    health: _playerHealth[_playerActiveIndex],
                                    shield: _playerShield,
                                    customSprites: widget.customSprites,
                                    isOpponent: false,
                                    isAttacking: _playerAttacking && !_finished,
                                    isHurt: _botAttacking && !_finished,
                                    isVictorious:
                                        _finished && _playerWon == true,
                                    label: 'You',
                                    compact: compact,
                                    reducedEffects:
                                        widget.preferences.reducedBattleEffects,
                                  ),
                                ],
                              ),
                            ),
                            if (_circleVisible && !_finished)
                              Positioned(
                                key: const Key('arena-energy-circle'),
                                left:
                                    _circleX *
                                    max(0, constraints.maxWidth - circleSize),
                                top:
                                    _circleY *
                                    max(0, constraints.maxHeight - circleSize),
                                child: _EnergyCircle(
                                  golden: _circleIsGolden,
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
                  _ArenaAbilityPanel(
                    abilities: abilities,
                    energy: _playerEnergy,
                    maxEnergy: ArenaCombatLogic.maxEnergy,
                    circlesHit: _circlesHit,
                    circlesMissed: _circlesMissed,
                    enabled: !_finished,
                    onAbility: _usePlayerAbility,
                  ),
                  _BattleBenches(
                    playerTeam: widget.simulation.playerTeam,
                    opponentTeam: widget.simulation.opponent.team,
                    playerHealth: _playerHealth,
                    botHealth: _botHealth,
                    customSprites: widget.customSprites,
                    playerActiveIndex: _playerActiveIndex,
                    botActiveIndex: _botActiveIndex,
                    onPlayerTap: _switchPlayer,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_finished)
              Positioned.fill(
                child: _ArenaResultOverlay(
                  won: _playerWon!,
                  reward: _reward!,
                  rating: widget.game.arenaRating,
                  streak: widget.game.arenaWinStreak,
                  skillGrade: ArenaCombatLogic.skillGrade(
                    won: _playerWon!,
                    hits: _circlesHit,
                    misses: _circlesMissed,
                    bestCombo: _bestCombo,
                    remainingHealth: _playerHealth.fold(0, (a, b) => a + b),
                    maxHealth: widget.simulation.playerTeam.fold(
                      0,
                      (sum, fighter) => sum + fighter.maxHealth,
                    ),
                  ),
                  accuracy: _circlesHit + _circlesMissed == 0
                      ? 0
                      : (_circlesHit * 100 / (_circlesHit + _circlesMissed))
                            .round(),
                  bestCombo: _bestCombo,
                  onContinue: () => Navigator.pop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArenaRecordBanner extends StatelessWidget {
  const _ArenaRecordBanner({required this.game});
  final GameService game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF00695C)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB300), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFB300),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 34,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ArenaLogic.divisionFor(game.arenaRating),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${game.arenaRating} rating',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${game.arenaWins}W  ${game.arenaLosses}L',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${game.arenaWinStreak} win streak',
                style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.theme,
    this.actionLabel,
    this.onTap,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  final BackgroundTheme theme;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
      ),
      if (actionLabel != null && onTap != null)
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.edit, size: 17),
          label: Text(
            actionLabel!,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
    ],
  );
}

class _TeamStrip extends StatelessWidget {
  const _TeamStrip({
    required this.team,
    required this.theme,
    required this.customSprites,
    required this.emptyLabel,
    required this.onTap,
  });
  final List<ArenaFighter> team;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final String emptyLabel;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(ArenaLogic.teamSize, (index) {
      final fighter = index < team.length ? team[index] : null;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
          child: _FighterSlot(
            fighter: fighter,
            theme: theme,
            customSprites: customSprites,
            emptyLabel: emptyLabel,
            onTap: onTap,
          ),
        ),
      );
    }),
  );
}

class _FighterSlot extends StatelessWidget {
  const _FighterSlot({
    required this.fighter,
    required this.theme,
    required this.customSprites,
    required this.emptyLabel,
    this.onTap,
  });
  final ArenaFighter? fighter;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final String emptyLabel;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final animal = fighter == null
        ? null
        : GameData.animalById(fighter!.animalId);
    final mutation = fighter == null
        ? null
        : GameData.mutationById(fighter!.mutationId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 142,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: fighter == null
                  ? theme.disabledColor.withValues(alpha: 0.5)
                  : theme.cardBorderColor,
              width: 1.5,
            ),
          ),
          child: fighter == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: theme.disabledColor,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.cardTextSecondaryColor,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    GameAnimalPortrait(
                      customSprite: customSprites.getDisplaySprite(animal!.id),
                      animalId: animal.id,
                      spritePath: animal.spritePath,
                      fallbackEmoji: animal.emoji,
                      mutation: mutation,
                      size: 72,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      animal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    Text(
                      '${formatCoins(fighter!.power)} PWR',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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

class _ChallengerCard extends StatelessWidget {
  const _ChallengerCard({
    required this.opponent,
    required this.playerPower,
    required this.theme,
    required this.customSprites,
    required this.onChallenge,
  });
  final ArenaOpponent opponent;
  final int playerPower;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final VoidCallback? onChallenge;

  @override
  Widget build(BuildContext context) {
    final ratio = opponent.totalPower / max(1, playerPower);
    final difficulty = ratio > 1.12
        ? 'TOUGH'
        : ratio < 0.88
        ? 'FAVORABLE'
        : 'EVEN';
    final difficultyColor = ratio > 1.12
        ? const Color(0xFFE53935)
        : ratio < 0.88
        ? const Color(0xFF2E7D32)
        : const Color(0xFFF9A825);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.panelAccentColor.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF263238),
                  ),
                  child: Text(
                    opponent.name.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: theme.cardTextPrimaryColor,
                        ),
                      ),
                      Text(
                        opponent.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.cardTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${opponent.rating} ELO',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    Text(
                      ArenaLogic.divisionFor(opponent.rating).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < opponent.team.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  _ChallengerAnimal(
                    fighter: opponent.team[i],
                    customSprites: customSprites,
                  ),
                ],
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatCoins(opponent.totalPower)} POWER',
                        maxLines: 1,
                        style: TextStyle(
                          color: theme.cardTextPrimaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        difficulty,
                        style: TextStyle(
                          color: difficultyColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onChallenge,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.sports_martial_arts, size: 16),
                  label: const Text(
                    'CHALLENGE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengerAnimal extends StatelessWidget {
  const _ChallengerAnimal({required this.fighter, required this.customSprites});
  final ArenaFighter fighter;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(fighter.animalId)!;
    return Tooltip(
      message: '${animal.name}  Lv ${fighter.level}',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54),
        ),
        child: ClipOval(
          child: GameAnimalPortrait(
            customSprite: customSprites.getDisplaySprite(animal.id),
            animalId: animal.id,
            spritePath: animal.spritePath,
            fallbackEmoji: animal.emoji,
            mutation: GameData.mutationById(fighter.mutationId),
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _EmptyArenaCard extends StatelessWidget {
  const _EmptyArenaCard({required this.theme});
  final BackgroundTheme theme;
  @override
  Widget build(BuildContext context) => Container(
    height: 170,
    alignment: Alignment.center,
    decoration: GameTheme.cardDecoration(theme),
    child: Text(
      'Choose at least one animal to find an opponent.',
      textAlign: TextAlign.center,
      style: TextStyle(color: theme.cardTextSecondaryColor),
    ),
  );
}

class _BattleTopBar extends StatelessWidget {
  const _BattleTopBar({
    required this.opponent,
    required this.playerEnergy,
    required this.botEnergy,
    required this.canLeave,
  });
  final ArenaOpponent opponent;
  final int playerEnergy;
  final int botEnergy;
  final bool canLeave;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
    child: Row(
      children: [
        IconButton(
          onPressed: canLeave ? () => Navigator.pop(context) : null,
          icon: const Icon(Icons.close),
          color: Colors.white,
          disabledColor: Colors.white24,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'ARENA MATCH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'VS ${opponent.name.toUpperCase()}',
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
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'BOT $botEnergy',
              style: const TextStyle(
                color: Color(0xFFFF8A65),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EnergyCircle extends StatelessWidget {
  const _EnergyCircle({required this.golden, required this.onTap});
  final bool golden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: golden ? 'Golden energy circle' : 'Energy circle',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: golden ? const Color(0xFFFFC107) : const Color(0xFF26C6DA),
        shape: const CircleBorder(),
        elevation: 12,
        shadowColor: golden ? Colors.amber : Colors.cyanAccent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 68,
            child: Icon(
              golden ? Icons.bolt : Icons.add,
              color: const Color(0xFF07131C),
              size: 34,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ActiveFighter extends StatelessWidget {
  const _ActiveFighter({
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
    final portraitSize = compact ? 82.0 : 104.0;
    final frameSize = portraitSize + 10;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      offset: isAttacking ? Offset(0, isOpponent ? 0.12 : -0.12) : Offset.zero,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: isAttacking ? 1.1 : 1,
            child: Container(
              width: frameSize,
              height: frameSize,
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
                boxShadow: [
                  BoxShadow(
                    color: (isOpponent ? Colors.deepOrange : Colors.cyan)
                        .withValues(alpha: 0.35),
                    blurRadius: 20,
                  ),
                ],
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
          SizedBox(height: compact ? 3 : 6),
          Text(
            mutation.fullName(animal),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 3 : 5),
          SizedBox(
            width: compact ? 170 : 200,
            child: BattleHealthBar(
              value: fraction,
              identity:
                  '${fighter.animalId}:${fighter.mutationId}:${fighter.level}:${fighter.power}',
              height: 12,
              reducedEffects: reducedEffects,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            shield > 0
                ? '${max(0, health)} / ${fighter.maxHealth}  +$shield shield'
                : '${max(0, health)} / ${fighter.maxHealth}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CombatPulse extends StatelessWidget {
  const _CombatPulse({
    required this.message,
    required this.combo,
    required this.finished,
  });
  final String message;
  final int combo;
  final bool finished;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 160),
    child: Column(
      key: ValueKey('$message-$finished'),
      children: [
        Text(
          finished ? 'MATCH COMPLETE' : message,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
        if (!finished && combo >= 2)
          Text(
            '$combo HIT COMBO',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    ),
  );
}

class _ArenaAbilityPanel extends StatelessWidget {
  const _ArenaAbilityPanel({
    required this.abilities,
    required this.energy,
    required this.maxEnergy,
    required this.circlesHit,
    required this.circlesMissed,
    required this.enabled,
    required this.onAbility,
  });
  final List<ArenaAbility> abilities;
  final int energy;
  final int maxEnergy;
  final int circlesHit;
  final int circlesMissed;
  final bool enabled;
  final ValueChanged<ArenaAbility> onAbility;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(10, 2, 10, 7),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
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
            const Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 18),
            const SizedBox(width: 4),
            Text(
              '$energy / $maxEnergy ENERGY',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: energy / maxEnergy,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFFFFC107),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$circlesHit hit  $circlesMissed miss',
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < abilities.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _AbilityButton(
                  ability: abilities[i],
                  enabled: enabled && energy >= abilities[i].energyCost,
                  onTap: () => onAbility(abilities[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _AbilityButton extends StatelessWidget {
  const _AbilityButton({
    required this.ability,
    required this.enabled,
    required this.onTap,
  });
  final ArenaAbility ability;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton(
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        backgroundColor: ability.energyCost >= 7
            ? const Color(0xFFE65100)
            : const Color(0xFF00796B),
        disabledBackgroundColor: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ability.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${ability.energyCost} ENERGY',
            style: TextStyle(
              color: enabled ? const Color(0xFFFFD54F) : Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BattleBenches extends StatelessWidget {
  const _BattleBenches({
    required this.playerTeam,
    required this.opponentTeam,
    required this.playerHealth,
    required this.botHealth,
    required this.customSprites,
    required this.playerActiveIndex,
    required this.botActiveIndex,
    required this.onPlayerTap,
  });
  final List<ArenaFighter> playerTeam;
  final List<ArenaFighter> opponentTeam;
  final List<int> playerHealth;
  final List<int> botHealth;
  final CustomSpriteService customSprites;
  final int playerActiveIndex;
  final int botActiveIndex;
  final ValueChanged<int> onPlayerTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _BenchSide(
          team: playerTeam,
          health: playerHealth,
          customSprites: customSprites,
          activeIndex: playerActiveIndex,
          onTap: onPlayerTap,
        ),
        const Text(
          'TEAMS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        _BenchSide(
          team: opponentTeam,
          health: botHealth,
          customSprites: customSprites,
          activeIndex: botActiveIndex,
        ),
      ],
    ),
  );
}

class _BenchSide extends StatelessWidget {
  const _BenchSide({
    required this.team,
    required this.health,
    required this.customSprites,
    required this.activeIndex,
    this.onTap,
  });
  final List<ArenaFighter> team;
  final List<int> health;
  final CustomSpriteService customSprites;
  final int activeIndex;
  final ValueChanged<int>? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(team.length, (index) {
      final animal = GameData.animalById(team[index].animalId)!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap != null && health[index] > 0
              ? () => onTap!(index)
              : null,
          child: Opacity(
            opacity: health[index] > 0 ? 1 : 0.28,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: health[index] <= 0
                      ? Colors.red
                      : index == activeIndex
                      ? const Color(0xFFFFD54F)
                      : Colors.white54,
                  width: index == activeIndex ? 2.5 : 1,
                ),
              ),
              child: ClipOval(
                child: GameAnimalPortrait(
                  customSprite: customSprites.getDisplaySprite(animal.id),
                  animalId: animal.id,
                  spritePath: animal.spritePath,
                  fallbackEmoji: animal.emoji,
                  mutation: GameData.mutationById(team[index].mutationId),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      );
    }),
  );
}

class _ArenaResultOverlay extends StatelessWidget {
  const _ArenaResultOverlay({
    required this.won,
    required this.reward,
    required this.rating,
    required this.streak,
    required this.skillGrade,
    required this.accuracy,
    required this.bestCombo,
    required this.onContinue,
  });
  final bool won;
  final ArenaReward reward;
  final int rating;
  final int streak;
  final String skillGrade;
  final int accuracy;
  final int bestCombo;
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.72),
    child: Center(
      child: Container(
        width: min(360, MediaQuery.sizeOf(context).width - 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF17242D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: won ? const Color(0xFFFFD54F) : const Color(0xFF78909C),
            width: 2,
          ),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.shield_outlined,
              size: 58,
              color: won ? const Color(0xFFFFD54F) : const Color(0xFF90A4AE),
            ),
            const SizedBox(height: 8),
            Text(
              won ? 'VICTORY' : 'DEFEAT',
              style: TextStyle(
                color: won ? const Color(0xFFFFD54F) : Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${ArenaLogic.divisionFor(rating)}  |  $rating rating',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SKILL GRADE $skillGrade  |  $accuracy% accuracy  |  $bestCombo combo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF80CBC4),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RewardStat(
                  icon: Icons.trending_up,
                  value:
                      '${reward.ratingChange >= 0 ? '+' : ''}${reward.ratingChange}',
                  label: 'RATING',
                ),
                _RewardStat(
                  icon: Icons.monetization_on,
                  value: formatCoins(reward.coins),
                  label: 'COINS',
                ),
                _RewardStat(
                  icon: Icons.sports_martial_arts,
                  value: '${reward.battleTokens}',
                  label: 'TOKENS',
                ),
              ],
            ),
            if (won && streak > 1) ...[
              const SizedBox(height: 14),
              Text(
                '$streak WIN STREAK',
                style: const TextStyle(
                  color: Color(0xFF80CBC4),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: won
                      ? const Color(0xFFE65100)
                      : const Color(0xFF455A64),
                ),
                child: const Text(
                  'NEXT OPPONENT',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFFFFB74D), size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ArenaPainter extends CustomPainter {
  const _ArenaPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF07131C), Color(0xFF12343A), Color(0xFF28150D)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var y = 80.0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), line);
    }
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFB300).withValues(alpha: 0.16),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.7,
      glow,
    );
    final ring = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.86,
        height: size.height * 0.33,
      ),
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
