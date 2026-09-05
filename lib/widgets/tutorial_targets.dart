import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/tutorial_data.dart';

/// Registry of [GlobalKey] targets for the guided tutorial spotlight.
class TutorialTargets {
  TutorialTargets._();

  static final GlobalKey shopButton = GlobalKey(debugLabel: 'tutorialShop');
  static final GlobalKey basicEggBuyButton = GlobalKey(
    debugLabel: 'tutorialBasicEggBuy',
  );
  static final GlobalKey screenBackButton = GlobalKey(
    debugLabel: 'tutorialScreenBack',
  );
  static final GlobalKey animalsSection = GlobalKey(
    debugLabel: 'tutorialAnimals',
  );
  static final GlobalKey upgradeButton = GlobalKey(
    debugLabel: 'tutorialUpgrade',
  );
  static final GlobalKey collectionButton = GlobalKey(
    debugLabel: 'tutorialCollection',
  );
  static final GlobalKey fusionSection = GlobalKey(
    debugLabel: 'tutorialFusion',
  );
  static final GlobalKey questsButton = GlobalKey(debugLabel: 'tutorialQuests');
  static final GlobalKey battlesButton = GlobalKey(
    debugLabel: 'tutorialBattles',
  );
  static final GlobalKey battlesExplainSection = GlobalKey(
    debugLabel: 'tutorialBattlesExplain',
  );
  static final GlobalKey rebirthPanel = GlobalKey(
    debugLabel: 'tutorialRebirth',
  );
  static final GlobalKey secretStatsSection = GlobalKey(
    debugLabel: 'tutorialSecretStats',
  );
  static final GlobalKey secretLateGameGuide = GlobalKey(
    debugLabel: 'tutorialSecretLateGame',
  );
  static final GlobalKey secretRottenShellGuide = GlobalKey(
    debugLabel: 'tutorialSecretRottenShell',
  );

  static GlobalKey? keyFor(String? targetId) {
    switch (targetId) {
      case TutorialTargetIds.shopButton:
        return shopButton;
      case TutorialTargetIds.basicEggBuyButton:
        return basicEggBuyButton;
      case TutorialTargetIds.screenBackButton:
        return screenBackButton;
      case TutorialTargetIds.animalsSection:
        return animalsSection;
      case TutorialTargetIds.upgradeButton:
        return upgradeButton;
      case TutorialTargetIds.collectionButton:
        return collectionButton;
      case TutorialTargetIds.fusionSection:
        return fusionSection;
      case TutorialTargetIds.questsButton:
        return questsButton;
      case TutorialTargetIds.battlesButton:
        return battlesButton;
      case TutorialTargetIds.battlesExplainSection:
        return battlesExplainSection;
      case TutorialTargetIds.rebirthPanel:
        return rebirthPanel;
      case TutorialTargetIds.secretStatsSection:
        return secretStatsSection;
      case TutorialTargetIds.secretLateGameGuide:
        return secretLateGameGuide;
      case TutorialTargetIds.secretRottenShellGuide:
        return secretRottenShellGuide;
      default:
        return null;
    }
  }

  static String? labelFor(String? targetId) => targetId;

  static Rect? measure(
    String? targetId, {
    required BuildContext overlayContext,
    double padding = 8,
  }) {
    final key = keyFor(targetId);
    if (key == null) return null;
    return measureKey(key, overlayContext: overlayContext, padding: padding);
  }

  static Rect? measureKey(
    GlobalKey key, {
    required BuildContext overlayContext,
    double padding = 8,
  }) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;

    final targetBox = targetContext.findRenderObject();
    if (targetBox is! RenderBox || !targetBox.hasSize) return null;

    final overlayBox = overlayContext.findRenderObject();
    if (overlayBox is! RenderBox || !overlayBox.hasSize) return null;

    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final bottomRight = targetBox.localToGlobal(
      targetBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );

    if (bottomRight.dx <= topLeft.dx || bottomRight.dy <= topLeft.dy) {
      return null;
    }

    return Rect.fromPoints(topLeft, bottomRight).inflate(padding);
  }

  static bool isFullyVisible(Rect target, Rect viewport) {
    return target.left >= viewport.left &&
        target.top >= viewport.top &&
        target.right <= viewport.right &&
        target.bottom <= viewport.bottom;
  }

  static Future<void> scrollTargetIntoView(
    String? targetId, {
    Duration duration = const Duration(milliseconds: 320),
    double alignment = 0.32,
  }) async {
    final targetContext = keyFor(targetId)?.currentContext;
    if (targetContext == null) return;

    try {
      await Scrollable.ensureVisible(
        targetContext,
        duration: duration,
        curve: Curves.easeInOut,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      if (!targetContext.mounted) return;
      await _correctPartiallyVisibleTarget(targetContext, duration: duration);
    } catch (_) {
      // Target may not live inside a scrollable ancestor.
    }
  }

  static Future<void> _correctPartiallyVisibleTarget(
    BuildContext targetContext, {
    required Duration duration,
  }) async {
    final scrollable = Scrollable.maybeOf(targetContext);
    final targetBox = targetContext.findRenderObject();
    final viewportBox = scrollable?.context.findRenderObject();
    if (scrollable == null ||
        targetBox is! RenderBox ||
        viewportBox is! RenderBox ||
        !targetBox.hasSize ||
        !viewportBox.hasSize) {
      return;
    }

    final targetRect = Rect.fromPoints(
      targetBox.localToGlobal(Offset.zero),
      targetBox.localToGlobal(targetBox.size.bottomRight(Offset.zero)),
    );
    final viewportRect = Rect.fromPoints(
      viewportBox.localToGlobal(Offset.zero),
      viewportBox.localToGlobal(viewportBox.size.bottomRight(Offset.zero)),
    ).deflate(12);
    if (isFullyVisible(targetRect, viewportRect)) return;

    final position = scrollable.position;
    final correction = position.axis == Axis.vertical
        ? targetRect.top < viewportRect.top
              ? targetRect.top - viewportRect.top
              : targetRect.bottom - viewportRect.bottom
        : targetRect.left < viewportRect.left
        ? targetRect.left - viewportRect.left
        : targetRect.right - viewportRect.right;
    final scrollDelta = switch (position.axisDirection) {
      AxisDirection.down || AxisDirection.right => correction,
      AxisDirection.up || AxisDirection.left => -correction,
    };
    final destination = (position.pixels + scrollDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((destination - position.pixels).abs() < 0.5) return;

    if (duration == Duration.zero) {
      position.jumpTo(destination);
    } else {
      await position.animateTo(
        destination,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }
  }

  static void debugLogMeasure({
    required String stepId,
    required String? targetId,
    required Rect? rect,
  }) {
    if (!kDebugMode) return;
    final label = labelFor(targetId) ?? targetId ?? 'none';
    if (rect == null) {
      debugPrint('[Tutorial] step=$stepId target=$label rect=NOT_FOUND');
    } else {
      debugPrint(
        '[Tutorial] step=$stepId target=$label '
        'rect=${rect.left.toStringAsFixed(1)},'
        '${rect.top.toStringAsFixed(1)} '
        '${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)}',
      );
    }
  }
}
