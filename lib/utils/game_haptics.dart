import 'dart:async';

import 'package:flutter/services.dart';

class GameHaptics {
  const GameHaptics._();

  static void selection({required bool enabled}) {
    if (enabled) unawaited(_ignoreUnsupported(HapticFeedback.selectionClick()));
  }

  static void attack({required bool enabled}) {
    if (enabled) unawaited(_ignoreUnsupported(HapticFeedback.mediumImpact()));
  }

  static void damage({required bool enabled}) {
    if (enabled) unawaited(_ignoreUnsupported(HapticFeedback.heavyImpact()));
  }

  static void result({required bool enabled, required bool won}) {
    if (!enabled) return;
    unawaited(
      _ignoreUnsupported(
        won ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact(),
      ),
    );
  }

  static Future<void> _ignoreUnsupported(Future<void> feedback) async {
    try {
      await feedback;
    } catch (_) {
      // Haptics are optional and unavailable on some web/desktop platforms.
    }
  }
}
