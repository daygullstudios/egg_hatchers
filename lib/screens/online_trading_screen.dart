import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../models/background_theme.dart';
import '../models/online_lobby.dart';
import '../models/online_trade.dart';
import '../models/owned_animal.dart';
import '../models/player_account.dart';
import '../services/custom_sprite_service.dart';
import '../services/game_service.dart';
import '../services/online_lobby_service.dart';
import '../services/trading_service.dart';
import '../widgets/game_background.dart';
import '../widgets/game_sprite.dart';
import '../widgets/phone_width_layout.dart';
import '../widgets/online_lobby_scope.dart';
import '../widgets/online_player_list.dart';

class OnlineTradingScreen extends StatefulWidget {
  const OnlineTradingScreen({
    super.key,
    required this.game,
    required this.account,
    required this.theme,
    required this.customSprites,
    this.trading,
    this.directRoomId,
    this.lobby,
  });

  final GameService game;
  final PlayerAccount account;
  final BackgroundTheme theme;
  final CustomSpriteService customSprites;
  final TradingService? trading;
  final String? directRoomId;
  final OnlineLobbyService? lobby;

  @override
  State<OnlineTradingScreen> createState() => _OnlineTradingScreenState();
}

class _OnlineTradingScreenState extends State<OnlineTradingScreen> {
  late final TradingService _trading;
  late final bool _ownsTrading;
  var _completionApplied = false;
  var _joinedDirectRoom = false;

  @override
  void initState() {
    super.initState();
    _trading = widget.trading ?? TradingService();
    _ownsTrading = widget.trading == null;
    _trading.addListener(_onTradingChanged);
    _trading.connect();
  }

  void _onTradingChanged() {
    if (!mounted) return;
    final completion = _trading.completion;
    _joinDirectRoomIfReady();
    if (completion != null && !_completionApplied) {
      _completionApplied = true;
      widget.game.applyOnlineTrade(
        sent: completion.sent,
        received: completion.received,
      );
    }
    setState(() {});
  }

  OnlineTraderSnapshot _traderSnapshot() => OnlineTraderSnapshot(
    account: widget.account,
    inventory: widget.game.tradableAnimals,
  );

  void _joinDirectRoomIfReady() {
    final roomId = widget.directRoomId;
    if (roomId == null ||
        _joinedDirectRoom ||
        _trading.state != TradingConnectionState.ready ||
        widget.game.tradableAnimals.isEmpty) {
      return;
    }
    _joinedDirectRoom = true;
    _completionApplied = false;
    _trading.joinInvitedTrade(roomId, _traderSnapshot());
  }

  void _findTrader() {
    final inventory = widget.game.tradableAnimals;
    if (inventory.isEmpty) return;
    _completionApplied = false;
    _trading.findTrader(_traderSnapshot());
  }

  @override
  void dispose() {
    if (_trading.state == TradingConnectionState.searching) {
      _trading.cancelSearch();
    } else if (_trading.state == TradingConnectionState.trading) {
      _trading.leaveTrade();
    }
    _trading.removeListener(_onTradingChanged);
    if (_ownsTrading) _trading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PhoneWidthAppBar(
        title: 'Online Trading',
        titleStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
        backgroundColor: const Color(0xFF063B36),
        foregroundColor: Colors.white,
      ),
      body: GameBackground(
        theme: widget.theme,
        child: PhoneWidthLayout(
          padding: EdgeInsets.zero,
          child: AnimatedBuilder(
            animation: Listenable.merge([_trading, widget.game]),
            builder: (context, _) {
              return switch (_trading.state) {
                TradingConnectionState.trading => _tradeView(),
                TradingConnectionState.completed => _completeView(),
                _ => _lobbyView(),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _lobbyView() {
    final inventory = widget.game.tradableAnimals;
    final lobby = widget.lobby ?? OnlineLobbyScope.maybeOf(context);
    final searching = _trading.state == TradingConnectionState.searching;
    final connected = _trading.state == TradingConnectionState.ready;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _TraderBanner(account: widget.account),
        const SizedBox(height: 14),
        _StatusPanel(
          icon: searching ? Icons.radar : Icons.swap_horiz,
          title: searching ? 'Finding a trader' : 'Trading Hub',
          message:
              _trading.message ??
              '${inventory.length} animal stacks available to trade',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            key: const ValueKey('find-online-trader-button'),
            onPressed: searching
                ? _trading.cancelSearch
                : connected && inventory.isNotEmpty
                ? _findTrader
                : null,
            icon: searching
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_search),
            label: Text(searching ? 'CANCEL SEARCH' : 'FIND TRADER'),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Available Animals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (inventory.isEmpty)
          const _StatusPanel(
            icon: Icons.lock_outline,
            title: 'No tradable animals',
            message:
                'Protected and special reward animals stay in your collection.',
          )
        else
          for (final animal in inventory)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnimalTradeTile(
                owned: animal,
                customSprites: widget.customSprites,
              ),
            ),
        if (lobby != null) ...[
          const SizedBox(height: 18),
          OnlinePlayerList(
            players: lobby.players,
            activity: OnlineInviteKind.trade,
            lobby: lobby,
            customSprites: widget.customSprites,
          ),
        ],
      ],
    );
  }

  Widget _tradeView() {
    final trade = _trading.trade!;
    final inventory = widget.game.tradableAnimals;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _TraderBanner(account: trade.opponent, opponent: true),
        const SizedBox(height: 14),
        _StatusPanel(
          icon: Icons.sync_alt,
          title: 'Live Trade',
          message: trade.message,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _OfferCard(
                label: 'YOUR OFFER',
                offer: trade.selfOffer,
                confirmed: trade.selfConfirmed,
                customSprites: widget.customSprites,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.swap_horiz, size: 28),
            ),
            Expanded(
              child: _OfferCard(
                label: 'THEIR OFFER',
                offer: trade.opponentOffer,
                confirmed: trade.opponentConfirmed,
                customSprites: widget.customSprites,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            key: const ValueKey('confirm-online-trade-button'),
            onPressed:
                trade.selfOffer != null &&
                    trade.opponentOffer != null &&
                    !trade.selfConfirmed
                ? _trading.confirm
                : null,
            icon: Icon(trade.selfConfirmed ? Icons.verified : Icons.handshake),
            label: Text(trade.selfConfirmed ? 'CONFIRMED' : 'CONFIRM TRADE'),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Choose Your Offer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        for (final animal in inventory)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AnimalTradeTile(
              owned: animal,
              selected: _sameAnimal(animal, trade.selfOffer),
              customSprites: widget.customSprites,
              onTap: () => _trading.offer(animal),
            ),
          ),
      ],
    );
  }

  Widget _completeView() {
    final completion = _trading.completion!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.verified, color: Color(0xFF32C989), size: 76),
        const SizedBox(height: 12),
        const Text(
          'TRADE COMPLETE',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        _OfferCard(
          label: 'YOU RECEIVED',
          offer: completion.received,
          confirmed: true,
          customSprites: widget.customSprites,
        ),
        const SizedBox(height: 10),
        _OfferCard(
          label: 'YOU TRADED',
          offer: completion.sent,
          confirmed: true,
          customSprites: widget.customSprites,
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('DONE'),
          ),
        ),
      ],
    );
  }
}

bool _sameAnimal(OwnedAnimal first, OwnedAnimal? second) {
  return second != null &&
      first.animalId == second.animalId &&
      first.mutationId == second.mutationId &&
      first.level == second.level &&
      first.sourceEggId == second.sourceEggId;
}

class _TraderBanner extends StatelessWidget {
  const _TraderBanner({required this.account, this.opponent = false});
  final PlayerAccount account;
  final bool opponent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2D35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF32C989), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: account.avatarColor,
            child: Text(
              account.displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '@${account.username}',
                  style: const TextStyle(color: Color(0xFF83E6C1)),
                ),
              ],
            ),
          ),
          Text(
            opponent ? 'TRADING WITH' : 'ONLINE',
            style: const TextStyle(
              color: Color(0xFF83E6C1),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF32C989)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(message, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.label,
    required this.offer,
    required this.confirmed,
    required this.customSprites,
  });
  final String label;
  final OwnedAnimal? offer;
  final bool confirmed;
  final CustomSpriteService customSprites;

  @override
  Widget build(BuildContext context) {
    final animal = offer == null ? null : GameData.animalById(offer!.animalId);
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102D35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: confirmed ? const Color(0xFF32C989) : Colors.white24,
          width: confirmed ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF83E6C1),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (animal == null)
            const Icon(Icons.add_box_outlined, color: Colors.white38, size: 44)
          else ...[
            GameAnimalPortrait(
              customSprite: customSprites.getDisplaySprite(animal.id),
              animalId: animal.id,
              spritePath: animal.spritePath,
              fallbackEmoji: animal.emoji,
              mutation: GameData.mutationById(offer!.mutationId),
              size: 58,
            ),
            Text(
              animal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${GameData.mutationById(offer!.mutationId)?.displayName ?? 'Normal'}  Lv ${offer!.level}',
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
          if (confirmed)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.verified, color: Color(0xFF32C989), size: 18),
            ),
        ],
      ),
    );
  }
}

class _AnimalTradeTile extends StatelessWidget {
  const _AnimalTradeTile({
    required this.owned,
    required this.customSprites,
    this.selected = false,
    this.onTap,
  });
  final OwnedAnimal owned;
  final CustomSpriteService customSprites;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final animal = GameData.animalById(owned.animalId)!;
    final mutation = GameData.mutationById(owned.mutationId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF32C989) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: GameAnimalPortrait(
                  customSprite: customSprites.getDisplaySprite(animal.id),
                  animalId: animal.id,
                  spritePath: animal.spritePath,
                  fallbackEmoji: animal.emoji,
                  mutation: mutation,
                  size: 46,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${mutation?.displayName ?? 'Normal'}  |  Level ${owned.level}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text('x${owned.quantity}'),
              if (onTap != null)
                Icon(selected ? Icons.check_circle : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
