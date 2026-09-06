import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'save_transfer_service.dart';

bool get saveImportLockAvailable {
  try {
    return !web.window.navigator.locks.isUndefinedOrNull;
  } catch (_) {
    return false;
  }
}

/// Each updated game tab holds a shared lease for its lifetime. Import/recovery
/// requires exclusivity; never steal another tab's lease or queue behind it.
Future<Future<void> Function()> acquireSaveStorageLease({
  bool exclusive = false,
}) => _acquire('nestarium-local-save-runtime', exclusive: exclusive);

Future<Future<void> Function()> acquireSaveImportStagingLease() =>
    _acquire('nestarium-local-save-import-stage', exclusive: true);

Future<Future<void> Function()> _acquire(
  String name, {
  required bool exclusive,
}) async {
  if (!saveImportLockAvailable) {
    if (exclusive) {
      throw const SaveTransferException(
        'This browser cannot safely coordinate save imports. Use an updated browser.',
      );
    }
    return () async {};
  }
  final acquired = Completer<Future<void> Function()>();
  final release = Completer<void>();
  final released = Completer<void>();
  final request = web.window.navigator.locks
      .request(
        name,
        web.LockOptions(
          mode: exclusive ? 'exclusive' : 'shared',
          ifAvailable: exclusive,
        ),
        ((web.Lock? lock) {
          if (lock == null) {
            acquired.completeError(
              const SaveTransferException(
                'Close other Nestarium game tabs, then retry. No save replacement can run while another updated game tab is open.',
              ),
            );
            return Future<JSAny?>.value(null).toJS;
          }
          acquired.complete(() async {
            if (!release.isCompleted) release.complete();
            await released.future;
          });
          return release.future.then<JSAny?>((_) => null).toJS;
        }).toJS,
      )
      .toDart;
  unawaited(
    request.then<void>(
      (_) {
        released.complete();
      },
      onError: (Object error, StackTrace stack) {
        if (!acquired.isCompleted) acquired.completeError(error, stack);
        if (!released.isCompleted) released.complete();
      },
    ),
  );
  return acquired.future;
}
