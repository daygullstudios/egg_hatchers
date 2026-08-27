import 'package:flutter/material.dart';

import '../models/online_lobby.dart';
import '../services/online_lobby_service.dart';
import 'phone_width_layout.dart';

class OnlineLobbyHost extends StatefulWidget {
  const OnlineLobbyHost({
    super.key,
    required this.lobby,
    required this.onSessionReady,
    required this.child,
  });

  final OnlineLobbyService lobby;
  final ValueChanged<OnlineSessionLaunch> onSessionReady;
  final Widget child;

  @override
  State<OnlineLobbyHost> createState() => _OnlineLobbyHostState();
}

class _OnlineLobbyHostState extends State<OnlineLobbyHost> {
  String? _handledRoomId;

  @override
  void initState() {
    super.initState();
    widget.lobby.addListener(_onLobbyChanged);
  }

  @override
  void didUpdateWidget(covariant OnlineLobbyHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lobby == widget.lobby) return;
    oldWidget.lobby.removeListener(_onLobbyChanged);
    widget.lobby.addListener(_onLobbyChanged);
  }

  void _onLobbyChanged() {
    if (!mounted) return;
    setState(() {});
    final launch = widget.lobby.sessionLaunch;
    if (launch == null || launch.roomId == _handledRoomId) return;
    _handledRoomId = launch.roomId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSessionReady(launch);
    });
  }

  @override
  void dispose() {
    widget.lobby.removeListener(_onLobbyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.lobby.incomingInvite;
    final message = widget.lobby.latestMessage;
    return Stack(
      children: [
        widget.child,
        if (invite != null)
          _BottomLeftOnlineCard(
            key: ValueKey(invite.id),
            child: _InviteCard(invite: invite, lobby: widget.lobby),
          )
        else if (message != null)
          _BottomLeftOnlineCard(
            key: ValueKey('${message.from.id}:${message.tag}'),
            child: _MessageCard(message: message, lobby: widget.lobby),
          ),
      ],
    );
  }
}

class _BottomLeftOnlineCard extends StatelessWidget {
  const _BottomLeftOnlineCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phoneLeft = ((width - kPhoneMaxContentWidth) / 2).clamp(0.0, width);
    return Positioned(
      left: phoneLeft + 10,
      right: width > kPhoneMaxContentWidth ? null : 10,
      bottom: MediaQuery.paddingOf(context).bottom + 12,
      width: width > kPhoneMaxContentWidth ? 390 : null,
      child: SafeArea(top: false, child: child),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.lobby});
  final OnlineInvite invite;
  final OnlineLobbyService lobby;

  @override
  Widget build(BuildContext context) {
    final action = invite.kind == OnlineInviteKind.trade ? 'trade' : 'battle';
    return Material(
      elevation: 12,
      color: const Color(0xFF111B3D),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF70D9FF), width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: invite.from.avatarColor,
              child: Text(
                invite.from.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${invite.from.username} wants to $action you',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('decline-online-invite'),
              tooltip: 'Decline',
              onPressed: () => lobby.respondToInvite(false),
              color: const Color(0xFFFF5B69),
              icon: const Icon(Icons.close),
            ),
            IconButton(
              key: const ValueKey('accept-online-invite'),
              tooltip: 'Accept',
              onPressed: () => lobby.respondToInvite(true),
              color: const Color(0xFF42D98B),
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.lobby});
  final OnlinePresetMessage message;
  final OnlineLobbyService lobby;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: const Color(0xFF102D35),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            const Icon(Icons.forum, color: Color(0xFF83E6C1)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${message.from.username}: ${onlineMessageTags[message.tag] ?? message.tag}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: lobby.clearLatestMessage,
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
