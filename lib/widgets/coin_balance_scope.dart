import 'package:flutter/widgets.dart';

/// Makes the live player coin balance available to shared navigation chrome.
class CoinBalanceScope extends InheritedWidget {
  const CoinBalanceScope({
    super.key,
    required this.coins,
    required super.child,
  });

  final int coins;

  static CoinBalanceScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CoinBalanceScope>();
  }

  @override
  bool updateShouldNotify(CoinBalanceScope oldWidget) {
    return coins != oldWidget.coins;
  }
}
