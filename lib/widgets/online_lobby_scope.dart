import 'package:flutter/material.dart';

import '../services/online_lobby_service.dart';

class OnlineLobbyScope extends InheritedNotifier<OnlineLobbyService> {
  const OnlineLobbyScope({
    super.key,
    required OnlineLobbyService lobby,
    required super.child,
  }) : super(notifier: lobby);

  static OnlineLobbyService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnlineLobbyScope>()?.notifier;
}
