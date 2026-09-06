import 'package:flutter/material.dart';

import '../models/player_state.dart';
import '../models/progress_conflict_review.dart';
import '../services/progress_sync_service.dart';
import '../utils/format_utils.dart';

/// Review first, then confirm the replacement. Opening/cancelling never resolves.
class ProgressConflictDialog extends StatefulWidget {
  const ProgressConflictDialog({
    super.key,
    required this.sync,
    required this.playerName,
  });

  final ProgressSyncService sync;
  final String playerName;

  @override
  State<ProgressConflictDialog> createState() => _ProgressConflictDialogState();
}

class _ProgressConflictDialogState extends State<ProgressConflictDialog> {
  ProgressConflictReview? _review;
  bool? _keepDevice;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _keepDevice = null;
      _review = null;
    });
    final review = await widget.sync.prepareConflictReview();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _review = review;
      if (review == null) _error = _failureMessage;
    });
  }

  String get _failureMessage => widget.sync.state.hasConflict
      ? widget.sync.state.message
      : 'The active player or save status changed. Close this review and return to Account & Saves.';

  Future<void> _confirm() async {
    if (_saving || _review == null || _keepDevice == null) return;
    setState(() => _saving = true);
    final success = _keepDevice!
        ? await widget.sync.keepThisDevice(_review!)
        : await widget.sync.useCloud(_review!);
    if (!mounted) return;
    if (success) {
      // Re-enable PopScope before closing the completed operation.
      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      setState(() {
        _saving = false;
        _keepDevice = null;
        _review = null;
        _error = _failureMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final confirming = _keepDevice != null;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        key: ValueKey('progress-conflict-dialog-${_keepDevice ?? 'compare'}'),
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(
          confirming
              ? (_keepDevice!
                    ? 'Replace cloud save?'
                    : 'Replace device progress?')
              : 'Compare saves',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.playerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Text('Reading both saves… No progress is being replaced.'),
            if (_error != null)
              Text(_error!, key: const ValueKey('save-review-error')),
            if (review != null && !confirming) ...[
              const Text(
                'Cloud sync is paused. Your game keeps saving on this device.',
              ),
              const SizedBox(height: 12),
              _SaveSummary(
                title: 'This device',
                icon: Icons.phone_android_rounded,
                state: review.local.state,
                savedAt: review.local.savedAt,
              ),
              const SizedBox(height: 12),
              _SaveSummary(
                title: 'Cloud copy',
                icon: Icons.cloud_outlined,
                state: review.cloud.state,
                savedAt: review.cloud.savedAt,
              ),
              const SizedBox(height: 12),
              const Text(
                'More coins or a newer save does not always mean more progress. These are highlights; other progress may differ too.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Cloud totals do not include offline income calculated when restored.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Saves are not merged. Choose a source below, then confirm what it replaces.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Want a device backup first? Choose Later, then Export Save in Account & Saves.',
              ),
            ],
            if (review != null && confirming) ...[
              Text(
                _keepDevice!
                    ? 'Your latest device progress will replace the cloud copy, including income earned since this comparison.'
                    : 'The cloud copy you reviewed will replace all current game progress on this device, including progress earned since this comparison.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Progress is replaced, not merged.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Other local players, device settings, custom eggs and custom artwork stay. This does not link or delete a sign-in account.',
              ),
              const SizedBox(height: 12),
              const Text(
                'To keep a device backup, go Back, choose Later, then Export Save before continuing.',
              ),
              if (_saving) ...[
                const SizedBox(height: 12),
                const Text('Applying your choice…'),
              ],
            ],
          ],
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton.icon(
            key: ValueKey(
              confirming ? 'save-review-back' : 'save-review-later',
            ),
            autofocus: true,
            onPressed: _saving
                ? null
                : () {
                    if (confirming) {
                      setState(() => _keepDevice = null);
                    } else {
                      Navigator.pop(context, false);
                    }
                  },
            icon: Icon(
              confirming ? Icons.arrow_back_rounded : Icons.close_rounded,
            ),
            label: Text(confirming ? 'Back' : 'Later'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          if (_error != null)
            OutlinedButton.icon(
              key: const ValueKey('save-review-retry'),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          if (review != null && !confirming) ...[
            OutlinedButton.icon(
              key: const ValueKey('save-review-device'),
              onPressed: () => setState(() => _keepDevice = true),
              icon: const Icon(Icons.phone_android_rounded),
              label: const Text('Device'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
            OutlinedButton.icon(
              key: const ValueKey('save-review-cloud'),
              onPressed: () => setState(() => _keepDevice = false),
              icon: const Icon(Icons.cloud_outlined),
              label: const Text('Cloud'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ],
          if (confirming)
            FilledButton.icon(
              key: const ValueKey('save-review-confirm'),
              onPressed: _saving ? null : _confirm,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Replace'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                minimumSize: const Size(48, 48),
              ),
            ),
        ],
      ),
    );
  }
}

class _SaveSummary extends StatelessWidget {
  const _SaveSummary({
    required this.title,
    required this.icon,
    required this.state,
    required this.savedAt,
  });
  final String title;
  final IconData icon;
  final PlayerState state;
  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final localTime = savedAt.toLocal();
    final locale = MaterialLocalizations.of(context);
    final timestamp =
        '${locale.formatCompactDate(localTime)} ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(localTime), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
    final animals = state.ownedAnimals.fold<int>(
      0,
      (sum, animal) => sum + animal.quantity,
    );
    return Container(
      key: ValueKey('save-summary-$title'),
      width: double.maxFinite,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Saved: $timestamp (local time)'),
          const SizedBox(height: 8),
          Text('Coins: ${formatCoins(state.coins)}'),
          Text('Animals owned: ${formatCoins(animals)}'),
          Text(
            'Eggs hatched: ${formatCoins(state.questProgress.totalEggsHatched)}',
          ),
          Text('Rebirth level: ${formatCoins(state.rebirthLevel)}'),
          Text('Luck level: ${formatCoins(state.luckLevel)}'),
          Text(
            'Boss wins: ${formatCoins(state.questProgress.totalBossBattlesWon)}',
          ),
        ],
      ),
    );
  }
}
