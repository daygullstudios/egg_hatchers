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
import '../utils/snackbar_utils.dart';
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
  String? _shownCancellation;

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
    final cancellation = _trading.cancellationMessage;
    if (cancellation != null && cancellation != _shownCancellation) {
      _shownCancellation = cancellation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showGameSnackBar(
            context,
            message: cancellation,
            duration: kGameSnackBarDurationImportant,
          );
        }
      });
    }
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

  Future<void> _chooseRequestedAnimal(OnlineTradeState trade) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.68,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Request from ${trade.opponent.displayName}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: trade.opponentInventory.isEmpty
                    ? const Center(child: Text('No animals can be requested.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        itemCount: trade.opponentInventory.length,
                        itemBuilder: (context, index) {
                          final animal = trade.opponentInventory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AnimalTradeTile(
                              owned: animal,
                              customSprites: widget.customSprites,
                              actionLabel: 'REQUEST',
                              onTap: () {
                                _trading.requestAnimal(animal);
                                Navigator.pop(sheetContext);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _offerRequestedAnimal(OwnedAnimal requested) {
    for (final owned in widget.game.tradableAnimals) {
      if (_sameAnimal(owned, requested)) {
        _trading.offer(owned);
        return;
      }
    }
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
        _TradeChatPanel(
          messages: _trading.chatMessages,
          opponentName: trade.opponent.displayName,
          customSprites: widget.customSprites,
          onSend: _trading.sendChat,
          onRequestAnimal: () => _chooseRequestedAnimal(trade),
          onOfferRequested: _offerRequestedAnimal,
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
    this.actionLabel,
  });
  final OwnedAnimal owned;
  final CustomSpriteService customSprites;
  final bool selected;
  final VoidCallback? onTap;
  final String? actionLabel;

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
              if (actionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Color(0xFF32C989),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (onTap != null)
                Icon(selected ? Icons.check_circle : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeChatPanel extends StatelessWidget {
  const _TradeChatPanel({
    required this.messages,
    required this.opponentName,
    required this.customSprites,
    required this.onSend,
    required this.onRequestAnimal,
    required this.onOfferRequested,
  });

  final List<TradeChatMessage> messages;
  final String opponentName;
  final CustomSpriteService customSprites;
  final ValueChanged<TradeChatTag> onSend;
  final VoidCallback onRequestAnimal;
  final ValueChanged<OwnedAnimal> onOfferRequested;

  @override
  Widget build(BuildContext context) {
    final visibleMessages = messages.length > 5
        ? messages.sublist(messages.length - 5)
        : messages;
    return Container(
      key: const ValueKey('trade-chat-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102D35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF32C989)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.forum, color: Color(0xFF83E6C1), size: 19),
              SizedBox(width: 7),
              Text(
                'Trade Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleMessages.isEmpty)
            const Text(
              'Use the choices below to negotiate safely.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            )
          else
            for (final message in visibleMessages)
              _TradeChatBubble(
                message: message,
                opponentName: opponentName,
                customSprites: customSprites,
                onOfferRequested: onOfferRequested,
              ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TradeChatChoice(
                label: 'YES',
                onPressed: () => onSend(TradeChatTag.yes),
              ),
              _TradeChatChoice(
                label: 'NO',
                onPressed: () => onSend(TradeChatTag.no),
              ),
              _TradeChatChoice(
                label: 'IS THIS FAIR?',
                onPressed: () => onSend(TradeChatTag.isThisFair),
              ),
              _TradeChatChoice(
                label: 'REQUEST ANIMAL',
                icon: Icons.pets,
                onPressed: onRequestAnimal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TradeChatChoice extends StatelessWidget {
  const _TradeChatChoice({
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TradeChatBubble extends StatelessWidget {
  const _TradeChatBubble({
    required this.message,
    required this.opponentName,
    required this.customSprites,
    required this.onOfferRequested,
  });

  final TradeChatMessage message;
  final String opponentName;
  final CustomSpriteService customSprites;
  final ValueChanged<OwnedAnimal> onOfferRequested;

  @override
  Widget build(BuildContext context) {
    final animal = message.animal == null
        ? null
        : GameData.animalById(message.animal!.animalId);
    final speaker = message.fromSelf ? 'You' : opponentName;
    final text = switch (message.tag) {
      TradeChatTag.yes => '$speaker: Yes',
      TradeChatTag.no => '$speaker: No',
      TradeChatTag.isThisFair => '$speaker: Is this fair?',
      TradeChatTag.requestAnimal =>
        message.fromSelf
            ? 'You requested ${animal?.name ?? 'an animal'}'
            : '$opponentName wants ${animal?.name ?? 'an animal'}',
    };
    return Align(
      alignment: message.fromSelf
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 285),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: message.fromSelf
              ? const Color(0xFF175A50)
              : const Color(0xFF233C55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (animal != null) ...[
              GameAnimalPortrait(
                customSprite: customSprites.getDisplaySprite(animal.id),
                animalId: animal.id,
                spritePath: animal.spritePath,
                fallbackEmoji: animal.emoji,
                mutation: GameData.mutationById(message.animal!.mutationId),
                size: 34,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            if (!message.fromSelf && message.animal != null)
              TextButton(
                onPressed: () => onOfferRequested(message.animal!),
                child: const Text('OFFER'),
              ),
          ],
        ),
      ),
    );
  }
}
