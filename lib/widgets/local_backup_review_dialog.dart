import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../utils/format_utils.dart';

class LocalBackupReviewDialog extends StatefulWidget {
  const LocalBackupReviewDialog({
    super.key,
    required this.review,
    required this.stage,
    required this.restart,
  });
  final ProgressReadException review;
  final Future<void> Function(ProgressReadException) stage;
  final VoidCallback restart;
  @override
  State<LocalBackupReviewDialog> createState() =>
      _LocalBackupReviewDialogState();
}

class _LocalBackupReviewDialogState extends State<LocalBackupReviewDialog> {
  bool _confirm = false, _started = false, _busy = false;
  String? _error;
  Future<void> _restore() async {
    if (_started) return;
    setState(() {
      _started = true;
      _busy = true;
    });
    try {
      await widget.stage(widget.review);
      widget.restart();
    } catch (_) {
      _error =
          'Recovery could not finish preparing or restarting. Restart to check the request. Keep app/browser data; your original copies must not be cleared.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.review.backupSnapshot!;
    final state = snapshot.state;
    return PopScope(
      canPop: !_started,
      child: AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        title: Text(
          _started
              ? 'Restart required'
              : _confirm
              ? 'Restore this local backup?'
              : 'Review local backup',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_started) ...[
              const Text(
                'Preview only. Your saved copies have not been changed.',
              ),
              const SizedBox(height: 12),
              Text(
                'Saved: ${snapshot.savedAt.toLocal().toString().split('.').first}',
              ),
              Text(
                '${formatCoins(state.coins)} coins · ${state.ownedAnimals.fold<int>(0, (sum, animal) => sum + animal.quantity)} animals · Rebirth ${state.rebirthLevel}',
              ),
              const SizedBox(height: 16),
              const Text(
                'This is an older local copy, not your cloud save. Recent progress may be missing.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Only this player’s local progress is restored. The original copies are kept in a recovery archive on this device. Download a backup to keep a separate copy. Other players, settings, sign-in and cloud progress are not replaced.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Cancel to Download backup or Copy backup first. Close all other game tabs, including older versions. Restore & restart checks the same copies again before making changes.',
              ),
            ] else
              Text(
                _error ??
                    (_busy
                        ? 'Preparing safe recovery…'
                        : 'Restart to finish checking the local backup.'),
              ),
            if (_busy) const LinearProgressIndicator(),
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
          if (!_started && _confirm)
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => setState(() => _confirm = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          if (!_started)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _confirm
                  ? _restore
                  : () => setState(() => _confirm = true),
              icon: Icon(_confirm ? Icons.restore : Icons.arrow_forward),
              label: Text(_confirm ? 'Restore & restart' : 'Continue'),
            ),
          if (_started && !_busy)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: widget.restart,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart game'),
            ),
        ],
      ),
    );
  }
}
