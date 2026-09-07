import 'dart:async';
import 'package:flutter/material.dart';
import '../services/custom_content_store.dart';
import '../services/unsaved_exit_guard.dart';

/// Keeps the actual operation in flight (no timeout/replayed parallel writes).
Future<bool> runCustomContentAction(
  BuildContext context, {
  required String title,
  required Future<void> Function() action,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ActionDialog(title: title, action: action),
    ) ??
    false;

class _ActionDialog extends StatefulWidget {
  const _ActionDialog({required this.title, required this.action});
  final String title;
  final Future<void> Function() action;
  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  bool _pending = true;
  bool _slow = false;
  String? _error;
  Timer? _watch;
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setDraftExitGuard(this, true);
    _watch?.cancel();
    setState(() {
      _pending = true;
      _slow = false;
      _error = null;
    });
    _watch = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _slow = true);
    });
    try {
      await widget.action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = error is CustomContentException
              ? error.message
              : 'The change could not be confirmed. Keep this screen open and retry. '
                    'Refreshing may lose unsaved work.';
        });
      }
    } finally {
      _watch?.cancel();
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    setDraftExitGuard(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_pending,
    child: AlertDialog(
      scrollable: true,
      title: Text(_error == null ? widget.title : 'Change not confirmed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pending) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            _error ??
                (_slow
                    ? 'This is taking longer than expected. Keep this screen open. '
                          'The operation is still running; a second attempt cannot start yet.'
                    : 'Checking the saved copy on this device…'),
          ),
        ],
      ),
      actions: _pending
          ? null
          : [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Return to screen'),
              ),
              FilledButton.icon(
                onPressed: _run,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
    ),
  );
}

/// Header and system Back share the same discard decision.
class CustomDraftScope extends StatefulWidget {
  const CustomDraftScope({
    super.key,
    required this.dirty,
    required this.child,
    this.isDirty,
  });
  final bool dirty;
  final bool Function()? isDirty;
  final Widget child;
  static Future<void> leave(BuildContext context) async {
    await context.findAncestorStateOfType<_CustomDraftScopeState>()?._leave();
  }

  @override
  State<CustomDraftScope> createState() => _CustomDraftScopeState();
}

class _CustomDraftScopeState extends State<CustomDraftScope> {
  bool _asking = false;
  @override
  void initState() {
    super.initState();
    setDraftExitGuard(this, widget.dirty);
  }

  @override
  void didUpdateWidget(CustomDraftScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    setDraftExitGuard(this, widget.dirty);
  }

  Future<void> _leave() async {
    if (_asking) return;
    _asking = true;
    final discard =
        !(widget.isDirty?.call() ?? widget.dirty) ||
        await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                scrollable: true,
                title: const Text('Discard unsaved draft?'),
                content: const Text(
                  'Your draft is only held on this screen. Leaving will lose it. '
                  'A previously unconfirmed save may already be on the device.',
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(dialog, false),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Keep editing'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(dialog, true),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Discard draft'),
                  ),
                ],
              ),
            ) ==
            true;
    _asking = false;
    if (discard && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    setDraftExitGuard(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: widget.child,
  );
}

class CustomDraftBackButton extends StatelessWidget {
  const CustomDraftBackButton({super.key});
  @override
  Widget build(BuildContext context) =>
      BackButton(onPressed: () => CustomDraftScope.leave(context));
}
