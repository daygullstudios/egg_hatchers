import 'package:flutter/widgets.dart';

import '../services/account_protection_service.dart';

class AccountProtectionScope
    extends InheritedNotifier<AccountProtectionService> {
  const AccountProtectionScope({
    super.key,
    required AccountProtectionService protection,
    required super.child,
  }) : super(notifier: protection);

  static AccountProtectionService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AccountProtectionScope>()
        ?.notifier;
  }
}
