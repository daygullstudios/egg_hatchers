import 'package:flutter/widgets.dart';

import '../services/progress_sync_service.dart';

class ProgressSyncScope extends InheritedNotifier<ProgressSyncService> {
  const ProgressSyncScope({
    super.key,
    required ProgressSyncService sync,
    required super.child,
  }) : super(notifier: sync);

  static ProgressSyncService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ProgressSyncScope>()
        ?.notifier;
  }
}
