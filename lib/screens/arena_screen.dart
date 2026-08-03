import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
import '../utils/battle_power_logic.dart';
import '../utils/format_utils.dart';
import '../widgets/audio_scope.dart';
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
  ArenaOpponent? _opponent;

  @override
  void initState() {
    super.initState();
    _team = ArenaLogic.recommendedTeam(widget.game.state.ownedAnimals);
    _refreshOpponent();
  }

  void _refreshOpponent() {
    if (_team.isEmpty) {
      _opponent = null;
      return;
    }
    _opponent = ArenaLogic.generateOpponent(
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
      _refreshOpponent();
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

  Future<void> _fight(BackgroundTheme theme) async {
    final opponent = _opponent;
    if (_team.isEmpty || opponent == null) return;
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
    setState(_refreshOpponent);
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
                    team: _team.map(ArenaLogic.fighterFromOwned).toList(),
                    theme: theme,
                    customSprites: widget.customSprites,
                    emptyLabel: 'Choose an animal',
                    onTap: () => _chooseTeam(theme),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeading(
                    title: 'Opponent',
                    actionLabel: 'REROLL',
                    onTap: () => setState(_refreshOpponent),
                    theme: theme,
                    icon: Icons.refresh,
                  ),
                  const SizedBox(height: 10),
                  if (_opponent != null)
                    _OpponentCard(
                      opponent: _opponent!,
                      theme: theme,
                      customSprites: widget.customSprites,
                    )
                  else
                    _EmptyArenaCard(theme: theme),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _team.isEmpty ? null : () => _fight(theme),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.sports_martial_arts),
                      label: Text(
                        _team.isEmpty ? 'CHOOSE A TEAM' : 'ENTER ARENA',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
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
  Timer? _timer;
  late final List<int> _playerHealth;
  late final List<int> _botHealth;
  late final ArenaReward _reward;
  var _stepIndex = -1;
  var _finished = false;
  var _rewardApplied = false;

  @override
  void initState() {
    super.initState();
    _playerHealth = widget.simulation.playerTeam
        .map((fighter) => fighter.maxHealth)
        .toList();
    _botHealth = widget.simulation.opponent.team
        .map((fighter) => fighter.maxHealth)
        .toList();
    _reward = ArenaLogic.rewardFor(
      won: widget.simulation.playerWon,
      playerRating: widget.game.arenaRating,
      opponentRating: widget.simulation.opponent.rating,
      opponentPower: widget.simulation.opponent.totalPower,
      currentStreak: widget.game.arenaWinStreak,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AudioScope.of(context).playMusic(MusicTrack.bossBattle);
      _timer = Timer.periodic(
        const Duration(milliseconds: 560),
        (_) => _advance(),
      );
    });
  }

  void _advance() {
    if (_stepIndex + 1 >= widget.simulation.steps.length) {
      _finish();
      return;
    }
    final nextIndex = _stepIndex + 1;
    final step = widget.simulation.steps[nextIndex];
    setState(() {
      _stepIndex = nextIndex;
      if (step.playerAttacks) {
        _botHealth[step.targetIndex] = step.targetHealthAfter;
      } else {
        _playerHealth[step.targetIndex] = step.targetHealthAfter;
      }
    });
    final audio = AudioScope.of(context);
    audio.playSfx(
      step.playerAttacks ? Sfx.bossHit : Sfx.playerHit,
      volumeScale: 0.45,
    );
  }

  void _finish() {
    if (_finished) return;
    _timer?.cancel();
    setState(() => _finished = true);
    if (!_rewardApplied) {
      _rewardApplied = true;
      widget.game.applyArenaResult(
        won: widget.simulation.playerWon,
        reward: _reward,
      );
      AudioScope.of(
        context,
      ).playSfx(widget.simulation.playerWon ? Sfx.victory : Sfx.defeat);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _stepIndex >= 0
        ? widget.simulation.steps[_stepIndex]
        : null;
    final playerActive = _firstAlive(_playerHealth);
    final botActive = _firstAlive(_botHealth);
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
                    step: min(_stepIndex + 1, widget.simulation.steps.length),
                    totalSteps: widget.simulation.steps.length,
                    canLeave: _finished,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActiveFighter(
                            fighter:
                                widget.simulation.opponent.team[botActive.clamp(
                                  0,
                                  widget.simulation.opponent.team.length - 1,
                                )],
                            health: botActive < _botHealth.length
                                ? _botHealth[botActive]
                                : 0,
                            customSprites: widget.customSprites,
                            isOpponent: true,
                            isAttacking:
                                activeStep?.playerAttacks == false &&
                                !_finished,
                            label: widget.simulation.opponent.name,
                          ),
                          _VersusPulse(step: activeStep, finished: _finished),
                          _ActiveFighter(
                            fighter:
                                widget.simulation.playerTeam[playerActive.clamp(
                                  0,
                                  widget.simulation.playerTeam.length - 1,
                                )],
                            health: playerActive < _playerHealth.length
                                ? _playerHealth[playerActive]
                                : 0,
                            customSprites: widget.customSprites,
                            isOpponent: false,
                            isAttacking:
                                activeStep?.playerAttacks == true && !_finished,
                            label: 'You',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BattleBenches(
                    playerTeam: widget.simulation.playerTeam,
                    opponentTeam: widget.simulation.opponent.team,
                    playerHealth: _playerHealth,
                    botHealth: _botHealth,
                    customSprites: widget.customSprites,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_finished)
              Positioned.fill(
                child: _ArenaResultOverlay(
                  won: widget.simulation.playerWon,
                  reward: _reward,
                  rating: widget.game.arenaRating,
                  streak: widget.game.arenaWinStreak,
                  onContinue: () => Navigator.pop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _firstAlive(List<int> health) {
    final index = health.indexWhere((value) => value > 0);
    return index < 0 ? health.length - 1 : index;
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
    required this.actionLabel,
    required this.onTap,
    required this.theme,
    this.icon,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onTap;
  final BackgroundTheme theme;
  final IconData? icon;
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
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon ?? Icons.edit, size: 17),
        label: Text(
          actionLabel,
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

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponent,
    required this.theme,
    required this.customSprites,
  });
  final ArenaOpponent opponent;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: GameTheme.cardDecoration(
      theme,
      borderColor: const Color(0xFFE65100),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE0B2),
              ),
              child: const Icon(Icons.smart_toy, color: Color(0xFFE65100)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponent.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.cardTextPrimaryColor,
                    ),
                  ),
                  Text(
                    opponent.title,
                    style: TextStyle(
                      fontSize: 12,
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
                  '${opponent.rating}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.cardTextPrimaryColor,
                  ),
                ),
                Text(
                  ArenaLogic.divisionFor(opponent.rating),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TeamStrip(
          team: opponent.team,
          theme: theme,
          customSprites: customSprites,
          emptyLabel: '',
          onTap: () {},
        ),
      ],
    ),
  );
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
    required this.step,
    required this.totalSteps,
    required this.canLeave,
  });
  final ArenaOpponent opponent;
  final int step;
  final int totalSteps;
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
        SizedBox(
          width: 56,
          child: Text(
            '$step/$totalSteps',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActiveFighter extends StatelessWidget {
  const _ActiveFighter({
    required this.fighter,
    required this.health,
    required this.customSprites,
    required this.isOpponent,
    required this.isAttacking,
    required this.label,
  });
  final ArenaFighter fighter;
  final int health;
  final CustomSpriteService customSprites;
  final bool isOpponent;
  final bool isAttacking;
  final String label;
  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(fighter.animalId)!;
    final mutation = GameData.mutationById(fighter.mutationId)!;
    final fraction = (health / fighter.maxHealth).clamp(0.0, 1.0);
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
              width: 128,
              height: 128,
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
                  size: 116,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mutation.fullName(animal),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 210,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 12,
                backgroundColor: Colors.white12,
                color: fraction > 0.45
                    ? const Color(0xFF66BB6A)
                    : fraction > 0.2
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFEF5350),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${max(0, health)} / ${fighter.maxHealth}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VersusPulse extends StatelessWidget {
  const _VersusPulse({required this.step, required this.finished});
  final ArenaBattleStep? step;
  final bool finished;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 160),
    child: Text(
      finished
          ? 'MATCH COMPLETE'
          : step == null
          ? 'READY'
          : '-${step!.damage}',
      key: ValueKey('${step?.damage}-${step?.targetHealthAfter}-$finished'),
      style: TextStyle(
        color: step?.targetDefeated == true
            ? const Color(0xFFFFD54F)
            : Colors.white,
        fontSize: step?.targetDefeated == true ? 22 : 18,
        fontWeight: FontWeight.w900,
        shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
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
  });
  final List<ArenaFighter> playerTeam;
  final List<ArenaFighter> opponentTeam;
  final List<int> playerHealth;
  final List<int> botHealth;
  final CustomSpriteService customSprites;
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
  });
  final List<ArenaFighter> team;
  final List<int> health;
  final CustomSpriteService customSprites;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(team.length, (index) {
      final animal = GameData.animalById(team[index].animalId)!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Opacity(
          opacity: health[index] > 0 ? 1 : 0.28,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: health[index] > 0 ? Colors.white54 : Colors.red,
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
    required this.onContinue,
  });
  final bool won;
  final ArenaReward reward;
  final int rating;
  final int streak;
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
