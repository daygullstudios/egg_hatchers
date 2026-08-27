import 'package:flutter/material.dart';

import '../services/account_service.dart';

/// Provides the signed-in local player profile to game screens.
class AccountScope extends InheritedNotifier<AccountService> {
  const AccountScope({
    super.key,
    required AccountService accounts,
    required super.child,
  }) : super(notifier: accounts);

  static AccountService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccountScope>();
    assert(scope != null, 'AccountScope not found in widget tree');
    return scope!.notifier!;
  }
}
