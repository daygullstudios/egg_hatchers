import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player_account.dart';
import '../services/game_service.dart';
import '../services/save_service.dart';
import '../services/save_transfer_file.dart';
import '../services/save_transfer_service.dart';

/// The held game remains mounted but inaccessible below this recovery surface.
/// Never offer reload/reset/switch/import as a fix for an unverified live save.
class UnsavedProgressScreen extends StatefulWidget {
  const UnsavedProgressScreen({
    super.key,
    required this.game,
    this.account,
    required this.onRetry,
    this.transfer,
    this.download,
    this.copy,
    this.web = kIsWeb,
  });
  final GameService game;
  final PlayerAccount? account;
  final Future<void> Function() onRetry;
  final SaveTransferService? transfer;
  final Future<void> Function(String, String)? download;
  final Future<void> Function(String)? copy;
  final bool web;
  @override
  State<UnsavedProgressScreen> createState() => _UnsavedProgressScreenState();
}

class _UnsavedProgressScreenState extends State<UnsavedProgressScreen> {
  bool _busy = false, _emergencyBusy = false;
  String? _message;

  Future<void> _backup({required bool emergency}) async {
    if (emergency ? _emergencyBusy : _busy) return;
    setState(() {
      if (emergency) {
        _emergencyBusy = true;
      } else {
        _busy = true;
      }
      _message = null;
    });
    try {
      final String source;
      if (emergency) {
        source = SaveTransferService.emergencyProgressSnapshot(
          account: widget.account,
          progress: widget.game.state,
        );
      } else {
        source = await (widget.transfer ?? SaveTransferService())
            .exportWithUnsavedProgress(
              account: widget.account!,
              progress: widget.game.state,
            );
      }
      if (widget.web) {
        await (widget.download ?? downloadSaveFile)(
          source,
          'nestarium-${emergency ? 'emergency-progress' : 'recovery-save'}.json',
        );
        _message =
            'Download requested. Check that the file was saved before closing this game.';
      } else {
        await (widget.copy ??
            (text) => Clipboard.setData(ClipboardData(text: text)))(source);
        _message =
            'Copied. Paste into a private file and keep it safe before closing this game.';
      }
      if (emergency) {
        _message =
            '$_message This snapshot needs support to restore; it is not a full save import.';
      }
    } catch (_) {
      _message = emergency
          ? 'Could not export the snapshot. Keep this game open and try again.'
          : 'Could not read a complete recovery backup. Export an emergency snapshot below to preserve the progress held in memory.';
    } finally {
      if (mounted) {
        setState(() {
          if (emergency) {
            _emergencyBusy = false;
          } else {
            _busy = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.game,
    builder: (context, _) {
      final pending = widget.game.saveInFlight;
      final changed =
          widget.game.progressWriteFailure?.failure ==
          ProgressWriteFailure.changed;
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.save_as_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  pending
                      ? 'Saving is taking longer'
                      : 'Progress is not safely saved',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.account?.displayName ?? 'Current player'} · ${widget.game.coins} coins',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Play and income are paused. Your latest progress is still held in this open game. Do not refresh, close it, clear app/browser data, or switch players until it is saved or backed up.',
                ),
                const SizedBox(height: 12),
                Text(
                  changed
                      ? 'The stored save changed or could not be verified. We will not overwrite an unexpected copy. Export your progress before seeking help.'
                      : pending
                      ? 'The current write is still pending. A second write will not start. You can export an emergency snapshot without waiting for storage.'
                      : 'Storage may be full or unavailable. Free space elsewhere without deleting this app’s data, then retry. A failed write is not proof that progress was saved.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: pending || _busy ? null : widget.onRetry,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.sync),
                  label: Text(pending ? 'Write in progress' : 'Retry saving'),
                ),
                const SizedBox(height: 12),
                if (widget.account != null) ...[
                  OutlinedButton.icon(
                    onPressed: _busy || pending
                        ? null
                        : () => _backup(emergency: false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      widget.web
                          ? 'Download recovery backup'
                          : 'Copy recovery backup',
                    ),
                  ),
                  const Text(
                    'Includes your unsaved progress and other local saves/settings only if storage can still be read. Review the file before any future import; normal imports replace local saves, not merge them.',
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: _emergencyBusy
                      ? null
                      : () => _backup(emergency: true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.security_outlined),
                  label: Text(
                    widget.web
                        ? 'Download emergency snapshot'
                        : 'Copy emergency snapshot',
                  ),
                ),
                const Text(
                  'Memory-only fallback: this player’s progress, not other players, settings or custom art. Not a normal import file; support-assisted recovery may be needed. Keep it private.',
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(_message!)),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
