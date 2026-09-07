import 'dart:async';
import 'package:flutter/foundation.dart';

enum CloudConnectionStatus { idle, connecting, slow, available, unavailable }

/// Optional network startup never owns the local-play gate. A slow operation
/// remains single-flight: timeout messaging must not start a second SDK init.
class CloudConnectionService extends ChangeNotifier {
  CloudConnectionService({
    required this.initialize,
    this.slowAfter = const Duration(seconds: 8),
  });
  final Future<bool> Function() initialize;
  final Duration slowAfter;
  CloudConnectionStatus _status = CloudConnectionStatus.idle;
  CloudConnectionStatus get status => _status;
  bool get isAvailable => status == CloudConnectionStatus.available;
  bool get isBusy => _pending != null;
  Future<void>? _pending;
  Timer? _slowTimer;
  bool _disposed = false;

  Future<void> connect() {
    if (_disposed || isAvailable) return Future.value();
    if (_pending != null) return _pending!;
    final completion = Completer<void>();
    _pending = completion.future;
    _set(CloudConnectionStatus.connecting);
    _slowTimer = Timer(slowAfter, () => _set(CloudConnectionStatus.slow));
    unawaited(_connect(completion));
    return completion.future;
  }

  Future<void> _connect(Completer<void> completion) async {
    var available = false;
    try {
      available = await initialize();
    } catch (_) {
      /* Not a storage failure. */
    }
    _slowTimer?.cancel();
    _pending = null;
    _set(
      available
          ? CloudConnectionStatus.available
          : CloudConnectionStatus.unavailable,
    );
    completion.complete();
  }

  void _set(CloudConnectionStatus value) {
    if (_disposed) return;
    _status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _slowTimer?.cancel();
    super.dispose();
  }
}
