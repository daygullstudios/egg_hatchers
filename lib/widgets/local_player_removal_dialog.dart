import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/player_account.dart';

/// Confirms local removal only; never implies a backend account deletion.
class LocalPlayerRemovalDialog extends StatelessWidget {
  const LocalPlayerRemovalDialog({super.key, required this.account});

  final PlayerAccount account;

  @override
  Widget build(BuildContext context) {
    final location = kIsWeb ? 'this browser' : 'this device';
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const ValueKey('local-player-removal-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Remove local player?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Removes this player’s progress, custom eggs and custom artwork '
            'from $location. Other players and device settings stay.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Cloud data and sign-in accounts are not deleted.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (account.isGuest) ...[
            const SizedBox(height: 12),
            const Text(
              'A guest cloud copy does not guarantee you can get this player back.',
            ),
          ],
          const SizedBox(height: 12),
          const Text('There is no undo.'),
          const SizedBox(height: 8),
          const Text(
            'To keep a backup, choose Keep player, '
            'then Export Save in Account & Saves.',
          ),
        ],
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton.icon(
          key: const ValueKey('settings-cancel-remove-local-player'),
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Keep player'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        FilledButton.icon(
          // Keep the existing automation target while correcting its UI label.
          key: const ValueKey('settings-confirm-delete-account'),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.person_remove_outlined),
          label: const Text('Remove'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }
}
