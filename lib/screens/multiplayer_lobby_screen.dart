import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/audio_assets.dart';
import '../models/arena.dart';
import '../models/background_theme.dart';
import '../models/multiplayer.dart';
import '../models/owned_animal.dart';
import '../models/player_account.dart';
import '../navigation/app_page_route.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/multiplayer_service.dart';
import '../services/preferences_service.dart';
import '../utils/arena_logic.dart';
import '../utils/battle_power_logic.dart';
import '../utils/format_utils.dart';
import '../widgets/game_background.dart';
import '../widgets/game_sprite.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/account_scope.dart';
import '../widgets/audio_scope.dart';
import 'multiplayer_battle_screen.dart';

typedef FindOnlineMatch =
    Future<void> Function(MultiplayerPlayerSnapshot player);

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({
    super.key,
    required this.game,
    required this.preferences,
    required this.customSprites,
    required this.account,
    this.onFindMatch,
    this.multiplayer,
  });

  final GameService game;
  final PreferencesService preferences;
  final CustomSpriteService customSprites;
  final PlayerAccount account;
  final FindOnlineMatch? onFindMatch;
  final MultiplayerService? multiplayer;

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  List<OwnedAnimal> _team = [];
  bool _searching = false;
  MultiplayerService? _multiplayer;
  bool _ownsMultiplayer = false;
  String? _shownMatchId;

  bool get _teamReady => _team.length == ArenaLogic.teamSize;

  @override
  void initState() {
    super.initState();
    _team = ArenaLogic.recommendedTeam(widget.game.state.ownedAnimals);
    if (widget.onFindMatch == null) {
      _multiplayer = widget.multiplayer ?? MultiplayerService();
      _ownsMultiplayer = widget.multiplayer == null;
      _multiplayer!.addListener(_onMultiplayerChanged);
      _multiplayer!.connect();
    }
  }

  void _onMultiplayerChanged() {
    if (!mounted) return;
    setState(() {});
    final multiplayer = _multiplayer;
    if (multiplayer?.state == MultiplayerConnectionState.matched &&
        multiplayer!.matchId != null &&
        multiplayer.matchId != _shownMatchId) {
      _shownMatchId = multiplayer.matchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatchFound(multiplayer);
      });
    }
  }

  Future<void> _showMatchFound(MultiplayerService multiplayer) async {
    final opponent = multiplayer.opponent;
    if (opponent == null) return;
    final theme = widget.preferences.selectedTheme;
    final startBattle = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111B3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF70D9FF), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Color(0xFFFFD45C)),
            SizedBox(width: 8),
            Text('Opponent found!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(opponent.avatarColorValue),
                child: Text(
                  opponent.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                opponent.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '@${opponent.username}',
                style: const TextStyle(
                  color: Color(0xFF70D9FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _SnapshotTeamStrip(
                team: opponent.team,
                theme: theme,
                customSprites: widget.customSprites,
              ),
              const SizedBox(height: 14),
              const Text(
                'Your teams are locked in. Collect energy and defeat every animal on the opposing team.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFC5D0FF), height: 1.3),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.sports_martial_arts),
            label: const Text('BATTLE'),
          ),
        ],
      ),
    );
    if (!mounted || startBattle != true) return;
    final player = MultiplayerPlayerSnapshot.fromPlayer(
      account: widget.account,
      team: _team.map(ArenaLogic.fighterFromOwned).toList(growable: false),
      rating: widget.game.arenaRating,
    );
    await pushThemedAppRoute<void>(
      context,
      theme: theme,
      settings: const RouteSettings(name: kMultiplayerBattleRouteName),
      builder: (_) => MultiplayerBattleScreen(
        multiplayer: multiplayer,
        game: widget.game,
        player: player,
        opponent: opponent,
        customSprites: widget.customSprites,
      ),
    );
    if (mounted) {
      AudioScope.maybeOf(context)?.playMusic(MusicTrack.hatchery);
    }
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
                top: Radius.circular(22),
              ),
              border: Border(
                top: BorderSide(color: theme.panelAccentColor, width: 2),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose your online team',
                                style: TextStyle(
                                  color: theme.cardTextPrimaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
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
                      itemBuilder: (context, index) {
                        final item = owned[index];
                        final selected = selectedKeys.contains(
                          ArenaLogic.ownedKey(item),
                        );
                        final animal = GameData.animalById(item.animalId)!;
                        final mutation = GameData.mutationById(
                          item.mutationId,
                        )!;
                        return Material(
                          color: selected
                              ? theme.primaryColor.withValues(alpha: 0.14)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
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
                                    size: 54,
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
                                            color: theme.cardTextPrimaryColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Lv ${item.level} | ${formatCoins(BattlePowerLogic.battlePowerForOwnedAnimal(item))} power',
                                          style: TextStyle(
                                            color: theme.cardTextSecondaryColor,
                                            fontSize: 12,
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
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _findMatch() async {
    if (!_teamReady || _searching) return;
    final snapshot = MultiplayerPlayerSnapshot.fromPlayer(
      account: widget.account,
      team: _team.map(ArenaLogic.fighterFromOwned).toList(),
      rating: widget.game.arenaRating,
    );
    if (widget.onFindMatch == null) {
      _multiplayer?.findMatch(snapshot);
      return;
    }
    setState(() => _searching = true);
    try {
      await widget.onFindMatch!(snapshot);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _chooseAnotherAccount() {
    final accounts = AccountScope.of(context);
    _multiplayer?.cancelSearch();
    Navigator.of(context).popUntil((route) => route.isFirst);
    accounts.chooseAnotherAccount();
  }

  @override
  void dispose() {
    _multiplayer?.removeListener(_onMultiplayerChanged);
    if (_ownsMultiplayer) _multiplayer?.dispose();
    super.dispose();
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
        final fighters = _team.map(ArenaLogic.fighterFromOwned).toList();
        final totalPower = fighters.fold<int>(
          0,
          (sum, fighter) => sum + fighter.power,
        );
        final connectionState = _multiplayer?.state;
        final serverConnected =
            widget.onFindMatch != null ||
            connectionState == MultiplayerConnectionState.ready ||
            connectionState == MultiplayerConnectionState.searching ||
            connectionState == MultiplayerConnectionState.matched;
        final searching =
            _searching ||
            connectionState == MultiplayerConnectionState.searching;
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PhoneWidthAppBar(
            title: 'Online Arena',
            titleStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
            backgroundColor: const Color(0xFF111B3D),
            foregroundColor: Colors.white,
            actions: [
              CompactAppBarIconAction(
                icon: Icons.switch_account,
                tooltip: 'Switch account',
                onPressed: _chooseAnotherAccount,
              ),
            ],
          ),
          body: GameBackground(
            theme: theme,
            child: PhoneWidthLayout(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  _PlayerBanner(
                    account: widget.account,
                    rating: widget.game.arenaRating,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Battle team',
                          style: TextStyle(
                            color: theme.textPrimaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _chooseTeam(theme),
                        icon: const Icon(Icons.edit, size: 17),
                        label: const Text('EDIT'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _OnlineTeamStrip(
                    team: fighters,
                    theme: theme,
                    customSprites: widget.customSprites,
                    onTap: () => _chooseTeam(theme),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: theme.secondaryColor, size: 19),
                      const SizedBox(width: 4),
                      Text(
                        '${formatCoins(totalPower)} total power',
                        style: TextStyle(
                          color: theme.textSecondaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _ConnectionPanel(
                    theme: theme,
                    state: widget.onFindMatch != null
                        ? MultiplayerConnectionState.ready
                        : connectionState ??
                              MultiplayerConnectionState.connecting,
                    message: _multiplayer?.message,
                    onRetry: _multiplayer?.retry,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const ValueKey('find-online-match-button'),
                      onPressed: _teamReady && serverConnected
                          ? searching
                                ? _multiplayer?.cancelSearch
                                : _findMatch
                          : null,
                      icon: searching
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.travel_explore),
                      label: Text(
                        searching
                            ? 'CANCEL SEARCH'
                            : !_teamReady
                            ? 'SELECT 3 ANIMALS'
                            : serverConnected
                            ? 'FIND MATCH'
                            : connectionState ==
                                  MultiplayerConnectionState.connecting
                            ? 'CONNECTING...'
                            : 'RETRY CONNECTION',
                        style: const TextStyle(fontWeight: FontWeight.w900),
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

class _PlayerBanner extends StatelessWidget {
  const _PlayerBanner({required this.account, required this.rating});

  final PlayerAccount account;
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B3D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF70D9FF), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: account.avatarColor,
            child: Text(
              account.displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '@${account.username}',
                  style: const TextStyle(
                    color: Color(0xFF70D9FF),
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
                ArenaLogic.divisionFor(rating).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFD45C),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$rating rating',
                style: const TextStyle(color: Color(0xFFA9B8E8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.theme,
    required this.state,
    required this.message,
    required this.onRetry,
  });

  final BackgroundTheme theme;
  final MultiplayerConnectionState state;
  final String? message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final connected = state == MultiplayerConnectionState.ready;
    final searching = state == MultiplayerConnectionState.searching;
    final connecting = state == MultiplayerConnectionState.connecting;
    return Container(
      key: const ValueKey('online-matchmaking-status'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.cardBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            connected
                ? Icons.cloud_done
                : searching
                ? Icons.radar
                : connecting
                ? Icons.cloud_sync
                : Icons.cloud_off,
            color: connected || searching ? Colors.green : theme.secondaryColor,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? 'Match server connected'
                      : searching
                      ? 'Searching for an opponent'
                      : connecting
                      ? 'Connecting to match server'
                      : 'Match server unavailable',
                  style: TextStyle(
                    color: theme.cardTextPrimaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message ??
                      (connected
                          ? 'Your account and team are ready for matchmaking.'
                          : connecting
                          ? 'This should only take a moment.'
                          : 'Start the local match server, then retry.'),
                  style: TextStyle(
                    color: theme.cardTextSecondaryColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (state == MultiplayerConnectionState.offline &&
                    onRetry != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('RETRY'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineTeamStrip extends StatelessWidget {
  const _OnlineTeamStrip({
    required this.team,
    required this.theme,
    required this.customSprites,
    required this.onTap,
  });

  final List<ArenaFighter> team;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(ArenaLogic.teamSize, (index) {
        final fighter = index < team.length ? team[index] : null;
        final animal = fighter == null
            ? null
            : GameData.animalById(fighter.animalId);
        final mutation = fighter == null
            ? null
            : GameData.mutationById(fighter.mutationId);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 136,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.cardBorderColor),
                  ),
                  child: fighter == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: theme.cardTextSecondaryColor,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose',
                              style: TextStyle(
                                color: theme.cardTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            GameAnimalPortrait(
                              customSprite: customSprites.getDisplaySprite(
                                animal!.id,
                              ),
                              animalId: animal.id,
                              spritePath: animal.spritePath,
                              fallbackEmoji: animal.emoji,
                              mutation: mutation!,
                              size: 70,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              animal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.cardTextPrimaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Lv ${fighter.level}',
                              style: TextStyle(
                                color: theme.cardTextSecondaryColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
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

class _SnapshotTeamStrip extends StatelessWidget {
  const _SnapshotTeamStrip({
    required this.team,
    required this.theme,
    required this.customSprites,
  });

  final List<MultiplayerFighterSnapshot> team;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _OnlineTeamStrip(
        team: team
            .map(
              (fighter) => ArenaFighter(
                animalId: fighter.animalId,
                mutationId: fighter.mutationId,
                level: fighter.level,
                power: fighter.power,
              ),
            )
            .toList(growable: false),
        theme: theme,
        customSprites: customSprites,
        onTap: () {},
      ),
    );
  }
}
