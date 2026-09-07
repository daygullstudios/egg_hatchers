import 'package:flutter/material.dart';

import '../services/device_settings_store.dart';

/// Non-blocking recovery remains reachable even after leaving Settings. It does
/// not stop gameplay or confuse device preferences with cloud progress saves.
class SettingsSaveHost extends StatefulWidget {
  const SettingsSaveHost({
    super.key,
    required this.store,
    required this.navigatorKey,
    required this.child,
  });

  final DeviceSettingsStore store;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<SettingsSaveHost> createState() => _SettingsSaveHostState();
}

class _SettingsSaveHostState extends State<SettingsSaveHost> {
  bool _reviewing = false;

  Future<void> _review() async {
    final context = widget.navigatorKey.currentState?.overlay?.context;
    if (context == null || _reviewing) return;
    setState(() => _reviewing = true);
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => SettingsSaveDialog(store: widget.store),
      );
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.store.needsAttention && !_reviewing)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Semantics(
                    liveRegion: true,
                    child: FilledButton.icon(
                      key: const ValueKey('settings-save-attention'),
                      onPressed: _review,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF803600),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text(
                        'Settings unsaved',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class SettingsSaveDialog extends StatelessWidget {
  const SettingsSaveDialog({super.key, required this.store});
  final DeviceSettingsStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final unsaved = store.hasUnsavedChanges;
      return AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.all(16),
        title: Text(unsaved ? 'Settings not yet saved' : 'Settings saved'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unsaved
                  ? 'Your choices still work in this session, but saving them on this device has not been confirmed. Keep the app open and retry before closing or refreshing.'
                  : 'Your choices have been checked and saved on this device.',
            ),
            if (unsaved) ...[
              const SizedBox(height: 12),
              for (final label in store.unsavedLabels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                store.isSaving
                    ? 'Still waiting for storage. Retry becomes available when this attempt finishes. You can keep playing.'
                    : 'A change may already have saved. Retry checks it first and saves only what is still needed.',
              ),
            ],
          ],
        ),
        actions: [
          if (unsaved)
            FilledButton.icon(
              key: const ValueKey('settings-save-retry'),
              onPressed: store.isSaving ? null : store.retry,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(store.isSaving ? 'Saving…' : 'Retry saving'),
            ),
          TextButton.icon(
            key: const ValueKey('settings-save-close'),
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.check_rounded),
            label: Text(unsaved ? 'Keep playing' : 'Done'),
          ),
        ],
      );
    },
  );
}
