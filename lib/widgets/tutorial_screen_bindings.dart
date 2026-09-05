import 'package:flutter/material.dart';

import '../data/tutorial_data.dart';
import '../services/tutorial_target_registry.dart';

/// Registers per-screen tutorial proxy handlers while the screen is mounted.
class TutorialScreenBindings extends StatefulWidget {
  const TutorialScreenBindings({
    super.key,
    required this.onReturnToHatchery,
    required this.child,
    this.handlers = const {},
    this.enabled = true,
  });

  final VoidCallback onReturnToHatchery;
  final Map<String, VoidCallback> handlers;
  final Widget child;
  final bool enabled;

  @override
  State<TutorialScreenBindings> createState() => _TutorialScreenBindingsState();
}

class _TutorialScreenBindingsState extends State<TutorialScreenBindings> {
  final Map<String, VoidCallback> _registeredHandlers = {};

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant TutorialScreenBindings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _unregister();
      return;
    }
    _register();
  }

  void _register() {
    if (!widget.enabled) return;
    _unregister();
    _registeredHandlers[TutorialTargetIds.screenBackButton] =
        widget.onReturnToHatchery;
    _registeredHandlers.addAll(widget.handlers);
    for (final entry in _registeredHandlers.entries) {
      TutorialTargetRegistry.register(entry.key, entry.value);
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _unregister() {
    for (final entry in _registeredHandlers.entries) {
      TutorialTargetRegistry.unregister(entry.key, onlyIfHandler: entry.value);
    }
    _registeredHandlers.clear();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
