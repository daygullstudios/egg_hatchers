import 'package:flutter/material.dart';

import '../services/save_transfer_service.dart';
import '../utils/format_utils.dart';

/// Two-step review. Once writers are paused, leaving means restarting, never
/// returning to an old in-memory game that might overwrite imported progress.
class SaveImportReviewDialog extends StatefulWidget {
  const SaveImportReviewDialog({
    super.key,
    required this.preview,
    required this.stageImport,
    required this.restart,
  });
  final SaveImportPreview preview;
  final Future<void> Function(SaveImportPreview) stageImport;
  final VoidCallback restart;

  @override
  State<SaveImportReviewDialog> createState() => _SaveImportReviewDialogState();
}

class _SaveImportReviewDialogState extends State<SaveImportReviewDialog> {
  var _confirming = false, _started = false, _busy = false;
  String? _error;

  Future<void> _import() async {
    if (_started) return;
    setState(() {
      _started = true;
      _busy = true;
    });
    try {
      await widget.stageImport(widget.preview);
      widget.restart();
    } catch (_) {
      // Do not echo the file, preference keys, or platform exception payload.
      _error =
          'The import could not be prepared or restarted. Restart to check '
          'the saved import and recovery state. Do not clear browser data.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final buttonStyle = FilledButton.styleFrom(minimumSize: const Size(48, 48));
    return PopScope(
      canPop: !_started,
      child: AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        title: Text(
          _started
              ? 'Restart required'
              : _confirming
              ? 'Replace local saves?'
              : 'Review import',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_started && !_confirming) ...[
              const Text('Preview only. Nothing has been imported.'),
              if (preview.exportedAt != null)
                Text(
                  'Exported: ${preview.exportedAt!.toLocal().toString().split('.').first}',
                ),
              const SizedBox(height: 12),
              Text(
                '${preview.players.length} local player${preview.players.length == 1 ? '' : 's'} in this file',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final player in preview.players) ...[
                const SizedBox(height: 12),
                Text(
                  player.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (preview.progress[player.id] case final state?)
                  Text(
                    '${formatCoins(state.coins)} coins · ${state.ownedAnimals.fold<int>(0, (sum, animal) => sum + animal.quantity)} animals · Rebirth ${state.rebirthLevel}',
                  )
                else
                  const Text('No separate progress stored for this player.'),
              ],
              if (preview.hasLegacyProgress)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Includes an older device-wide save. The existing player migration will preserve it.',
                  ),
                ),
            ],
            if (!_started) ...[
              const SizedBox(height: 16),
              const Text(
                'Replaces ALL local players, progress, settings, custom eggs and artwork in this browser. Saves are not merged.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cloud accounts are not imported or deleted. This does not transfer a Google sign-in or choose between device and cloud progress.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Want to keep this device’s progress? Cancel and Export Save first. A temporary recovery copy protects interrupted imports; it is not a permanent backup.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Close all other Nestarium game tabs, including older versions. Import & restart pauses this game, then checks and replaces saves before the game opens again.',
              ),
            ],
            if (_started)
              Text(
                _error ??
                    (_busy
                        ? 'Pausing saves and preparing the import…'
                        : 'The file is staged. Restart to finish checking and importing it.'),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        actions: [
          if (!_started)
            TextButton.icon(
              autofocus: true,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          if (!_started && _confirming)
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => setState(() => _confirming = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          if (!_started)
            FilledButton.icon(
              key: const ValueKey('settings-confirm-import-save'),
              style: buttonStyle,
              onPressed: _confirming
                  ? _import
                  : () => setState(() => _confirming = true),
              icon: Icon(_confirming ? Icons.restart_alt : Icons.arrow_forward),
              label: Text(_confirming ? 'Import & restart' : 'Continue'),
            ),
          if (_started && !_busy)
            FilledButton.icon(
              key: const ValueKey('settings-restart-after-import'),
              style: buttonStyle,
              onPressed: widget.restart,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart game'),
            ),
        ],
      ),
    );
  }
}
