import 'dart:async';
import 'package:flutter/material.dart';

import '../services/save_storage_lease.dart';
import '../services/save_transfer_service.dart';
import '../services/cloud_connection_service.dart';
import 'app_theme_background.dart';

/// Owns the lifetime storage lease and completes import/recovery before any
/// Firebase or game service can read or mutate the replacement data.
class SaveImportBootstrap extends StatefulWidget {
  const SaveImportBootstrap({
    super.key,
    required this.appBuilder,
    required this.initializeCloud,
    this.transfer,
    this.acquireLease,
  });
  final Widget Function(CloudConnectionService) appBuilder;
  final Future<bool> Function() initializeCloud;
  final SaveTransferService? transfer;
  final Future<Future<void> Function()> Function({bool exclusive})?
  acquireLease;
  @override
  State<SaveImportBootstrap> createState() => _SaveImportBootstrapState();
}

class _SaveImportBootstrapState extends State<SaveImportBootstrap> {
  late final _transfer = widget.transfer ?? SaveTransferService();
  late final _cloud = CloudConnectionService(
    initialize: widget.initializeCloud,
  );
  Future<void> Function()? _release;
  bool _ready = false, _busy = true, _canCancel = false;
  var _running = false;
  bool _slow = false;
  Timer? _slowTimer;
  String? _error;
  SaveImportBootResult? _result;
  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<Future<void> Function()> _lease({bool exclusive = false}) =>
      (widget.acquireLease ?? acquireSaveStorageLease)(exclusive: exclusive);

  Future<void> _boot({bool cancel = false}) async {
    if (_running || _ready || !mounted) return;
    _running = true;
    _slow = false;
    _slowTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _slow = true);
    });
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
        _result = null;
      });
    }
    try {
      var release = await _lease();
      if (!mounted) {
        await release();
        return;
      }
      _release = release;
      final pending = await _transfer.hasPendingImport();
      if (!mounted) return;
      if (pending) {
        _canCancel = true;
        await release();
        _release = null;
        release = await _lease(exclusive: true);
        try {
          if (cancel) {
            await _transfer.cancelPendingImport();
            _result = SaveImportBootResult.originalRestored;
          } else {
            _result = await _transfer.finishPendingImport();
          }
        } finally {
          await release();
        }
        _canCancel = false;
      } else {
        // Import/storage safety is mandatory. Network availability is not.
        unawaited(_cloud.connect());
        if (mounted) _ready = true;
      }
    } catch (error) {
      await _release?.call();
      _release = null;
      _error = error is SaveTransferException
          ? error.message
          : 'Local saves could not be checked. Do not clear browser data. Retry when storage is available.';
    } finally {
      _slowTimer?.cancel();
      _running = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _cloud.dispose();
    unawaited(_release?.call());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.appBuilder(_cloud);
    final imported = _result == SaveImportBootResult.imported;
    final recovered = _result == SaveImportBootResult.originalRestored;
    final backupRestored = _result == SaveImportBootResult.backupRestored;
    return MaterialApp(
      title: 'Nestarium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF65B1AB)),
      builder: (_, child) => PortraitAppShell(child: child!),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 44),
                  const SizedBox(height: 16),
                  Text(
                    _busy
                        ? 'Checking local saves…'
                        : _error != null
                        ? (_canCancel ? 'Import paused' : 'Startup paused')
                        : imported
                        ? 'Import complete'
                        : backupRestored
                        ? 'Local backup restored'
                        : recovered
                        ? 'Original saves restored'
                        : 'Local saves ready',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_busy) ...[
                    const CircularProgressIndicator(),
                    if (_slow) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'The local save check is taking longer than expected. Keep app/browser data. It must finish before play can start; no second check or replacement will be started while it is pending.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    Text(
                      _error ??
                          (backupRestored
                              ? 'The reviewed backup is now this player’s local progress. The original copies are retained in a recovery archive. Cloud progress and sign-in were not changed.'
                              : imported
                              ? 'The imported local players are ready. Cloud accounts were not imported or deleted.'
                              : recovered
                              ? 'The import did not replace your original local players. You can open them now.'
                              : 'No pending import remains. Open the game to view the saved players.'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => _boot(),
                      icon: Icon(
                        _error != null ? Icons.refresh : Icons.play_arrow,
                      ),
                      label: Text(_error != null ? 'Retry' : 'Open game'),
                    ),
                    if (_canCancel)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => _boot(cancel: true),
                        icon: const Icon(Icons.undo),
                        label: const Text('Keep original saves'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
