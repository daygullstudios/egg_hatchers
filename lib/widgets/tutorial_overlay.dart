import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/tutorial_data.dart';
import '../models/background_theme.dart';
import '../services/game_service.dart';
import '../services/tutorial_service.dart';
import '../theme/game_theme.dart';
import '../utils/snackbar_utils.dart';
import 'phone_width_layout.dart';
import 'tutorial_highlight.dart';
import 'tutorial_targets.dart';

/// Dim overlay with circular spotlight, callout bubble, and tap blocking.
class TutorialSpotlightOverlay extends StatefulWidget {
  const TutorialSpotlightOverlay({
    super.key,
    required this.service,
    required this.theme,
    required this.topRouteName,
    required this.contentKey,
  });

  final TutorialService service;
  final BackgroundTheme theme;
  final String? topRouteName;
  final GlobalKey contentKey;

  @override
  State<TutorialSpotlightOverlay> createState() =>
      _TutorialSpotlightOverlayState();
}

class _TutorialSpotlightOverlayState extends State<TutorialSpotlightOverlay> {
  Rect? _targetRect;
  String? _measuredStepId;
  var _measureGeneration = 0;
  String? _lastAutoScrolledStepKey;

  TutorialService get service => widget.service;

  @override
  void initState() {
    super.initState();
    service.addListener(_scheduleMeasure);
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant TutorialSpotlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topRouteName != widget.topRouteName ||
        oldWidget.service.stepIndex != widget.service.stepIndex) {
      _scheduleMeasure();
    }
  }

  @override
  void dispose() {
    service.removeListener(_scheduleMeasure);
    super.dispose();
  }

  void _scheduleMeasure() {
    final generation = ++_measureGeneration;
    final scheduledStep = service.currentStep;
    final stepKey = service.isGuided && scheduledStep != null
        ? '${service.flow.name}:${scheduledStep.id}'
        : null;
    final shouldAutoScroll =
        stepKey != null && _lastAutoScrolledStepKey != stepKey;
    _lastAutoScrolledStepKey = stepKey;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || generation != _measureGeneration) return;
      clearGameSnackBars(context);

      final step = service.currentStep;
      if (shouldAutoScroll && step?.targetId != null) {
        await TutorialTargets.scrollTargetIntoView(step!.targetId);
      }
      if (!mounted || generation != _measureGeneration) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _measureGeneration) return;
        _remeasureTarget();
      });
    });
  }

  void _remeasureTarget() {
    final step = service.currentStep;
    if (step == null || step.targetId == null) {
      if (_targetRect != null || _measuredStepId != null) {
        setState(() {
          _targetRect = null;
          _measuredStepId = null;
        });
      }
      return;
    }

    final rect = TutorialTargets.measure(
      step.targetId,
      overlayContext: context,
      padding: 0,
    );

    final mediaQuery = MediaQuery.of(context);
    final viewport = Rect.fromLTRB(
      0,
      mediaQuery.padding.top,
      mediaQuery.size.width,
      mediaQuery.size.height - mediaQuery.padding.bottom,
    );
    final visibleRect =
        rect != null && TutorialTargets.isFullyVisible(rect, viewport)
        ? rect.inflate(8).intersect(viewport)
        : null;

    TutorialTargets.debugLogMeasure(
      stepId: step.id,
      targetId: step.targetId,
      rect: visibleRect,
    );

    if (_measuredStepId != step.id || _targetRect != visibleRect) {
      setState(() {
        _targetRect = visibleRect;
        _measuredStepId = step.id;
      });
    }

    if (visibleRect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final retry = TutorialTargets.measure(
          step.targetId,
          overlayContext: context,
          padding: 0,
        );
        final retryVisible =
            retry != null && TutorialTargets.isFullyVisible(retry, viewport)
            ? retry.inflate(8).intersect(viewport)
            : null;
        if (retryVisible != null && retryVisible != _targetRect) {
          TutorialTargets.debugLogMeasure(
            stepId: step.id,
            targetId: step.targetId,
            rect: retryVisible,
          );
          setState(() {
            _targetRect = retryVisible;
            _measuredStepId = step.id;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (service.phase == TutorialPhase.welcome) {
      return _WelcomeOverlay(service: service, theme: widget.theme);
    }
    if (service.phase != TutorialPhase.guided || service.pausedForDialog) {
      return const SizedBox.shrink();
    }

    final step = service.currentStep;
    if (step == null) return const SizedBox.shrink();

    if (!service.isStepVisibleOnCurrentRoute(widget.topRouteName)) {
      return const SizedBox.shrink();
    }

    final targetFound = _targetRect != null && _measuredStepId == step.id;
    final useFallback = service.isFallbackMode(step, targetFound: targetFound);
    final targetRect = useFallback ? null : _targetRect;
    final text = service.displayText(step, targetFound: targetFound);
    final showNext = service.showNextButton(step, targetFound: targetFound);
    final showTargetFallback = service.showTargetFallbackButton(
      step,
      targetFound: targetFound,
    );
    final proxyTap = service.allowsProxyTargetTap(
      step,
      targetFound: targetFound,
    );
    final showReturn = service.showReturnToHatcheryButton(
      step,
      targetFound: targetFound,
    );

    if (targetRect == null) {
      return _FallbackCardOverlay(
        service: service,
        theme: widget.theme,
        text: text,
        showNext: showNext || showTargetFallback,
        isFinish: step.isFinish,
        onNext: showTargetFallback
            ? () => service.invokeTargetFallback(step)
            : null,
        nextLabel: showTargetFallback ? step.fallbackActionLabel : null,
        showReturnToHatchery: showReturn,
        onReturnToHatchery: showReturn
            ? service.invokeReturnToHatcheryFallback
            : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layerSize = constraints.biggest;
        return _SpotlightLayer(
          service: service,
          theme: widget.theme,
          targetRect: targetRect,
          layerSize: layerSize,
          text: text,
          showNext: showNext,
          isFinish: step.isFinish,
          proxyTapEnabled: proxyTap,
          targetId: step.targetId,
          contentKey: widget.contentKey,
        );
      },
    );
  }
}

class _WelcomeOverlay extends StatelessWidget {
  const _WelcomeOverlay({required this.service, required this.theme});

  final TutorialService service;
  final BackgroundTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: PhoneWidthLayout(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: GameTheme.panelDecoration(theme),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      service.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: GameTheme.sectionTitle(theme, size: 22),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: service.startGuided,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        service.startButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: service.skipTutorial,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.cardTextPrimaryColor,
                        side: BorderSide(
                          color: theme.panelAccentColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text(TutorialData.exitButtonLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackCardOverlay extends StatelessWidget {
  const _FallbackCardOverlay({
    required this.service,
    required this.theme,
    required this.text,
    required this.showNext,
    required this.isFinish,
    this.onNext,
    this.nextLabel,
    this.showReturnToHatchery = false,
    this.onReturnToHatchery,
  });

  final TutorialService service;
  final BackgroundTheme theme;
  final String text;
  final bool showNext;
  final bool isFinish;
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool showReturnToHatchery;
  final VoidCallback? onReturnToHatchery;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxCardHeight = math.max(
      120.0,
      mediaQuery.size.height -
          mediaQuery.padding.vertical -
          kToolbarHeight -
          48,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(
          color: Colors.black.withValues(alpha: 0.55),
          dismissible: false,
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: PhoneWidthLayout(
              useSafeArea: false,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  kToolbarHeight + 12,
                  24,
                  24,
                ),
                child: _CalloutCard(
                  theme: theme,
                  text: text,
                  showNext: showNext,
                  isFinish: isFinish,
                  onNext: onNext ?? () => service.advanceNext(force: true),
                  onSkip: service.skipTutorial,
                  nextLabel:
                      nextLabel ??
                      (isFinish ? service.finishButtonLabel : 'Next'),
                  maxHeight: maxCardHeight,
                  showReturnToHatchery: showReturnToHatchery,
                  onReturnToHatchery: onReturnToHatchery,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightLayer extends StatelessWidget {
  const _SpotlightLayer({
    required this.service,
    required this.theme,
    required this.targetRect,
    required this.layerSize,
    required this.text,
    required this.showNext,
    required this.isFinish,
    required this.proxyTapEnabled,
    required this.targetId,
    required this.contentKey,
  });

  final TutorialService service;
  final BackgroundTheme theme;
  final Rect targetRect;
  final Size layerSize;
  final String text;
  final bool showNext;
  final bool isFinish;
  final bool proxyTapEnabled;
  final String? targetId;
  final GlobalKey contentKey;

  @override
  Widget build(BuildContext context) {
    final metrics = TutorialHighlightMetrics.forTarget(targetRect);
    final highlightBounds = metrics.bounds;
    final calloutPlacement = _CalloutPlacement.forTarget(
      highlightBounds,
      layerSize,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        TutorialSpotlightDimMask(
          metrics: metrics,
          layerSize: layerSize,
          dimColor: Colors.black.withValues(alpha: 0.62),
          blockOutsideTouches: true,
          contentKey: contentKey,
        ),
        IgnorePointer(
          child: TutorialTargetHighlight(
            metrics: metrics,
            layerSize: layerSize,
          ),
        ),
        if (proxyTapEnabled && targetId != null)
          Positioned.fromRect(
            rect: highlightBounds,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => service.invokeTargetTap(targetId!),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        _TargetDirectionArrow(
          layerSize: layerSize,
          targetCenter: highlightBounds.center,
          placement: calloutPlacement,
        ),
        Positioned(
          left: calloutPlacement.left,
          top: calloutPlacement.top,
          width: calloutPlacement.width,
          height: calloutPlacement.maxHeight,
          child: Align(
            alignment: calloutPlacement.arrowDirection == _ArrowDirection.down
                ? Alignment.bottomCenter
                : Alignment.topCenter,
            child: _CalloutCard(
              theme: theme,
              text: text,
              showNext: showNext,
              isFinish: isFinish,
              onNext: () => service.advanceNext(force: true),
              onSkip: service.skipTutorial,
              nextLabel: isFinish ? service.finishButtonLabel : 'Next',
              arrowDirection: calloutPlacement.arrowDirection,
              maxHeight: calloutPlacement.maxHeight,
            ),
          ),
        ),
      ],
    );
  }
}

enum _ArrowDirection { up, down, left, right }

class _TargetDirectionArrow extends StatelessWidget {
  const _TargetDirectionArrow({
    required this.layerSize,
    required this.targetCenter,
    required this.placement,
  });

  final Size layerSize;
  final Offset targetCenter;
  final _CalloutPlacement placement;

  static const _arrowColor = Color(0xFFFFEB3B);

  @override
  Widget build(BuildContext context) {
    final start = placement.arrowAnchor;
    if (start == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: layerSize,
        painter: _TargetArrowPainter(
          from: start,
          to: targetCenter,
          color: _arrowColor,
        ),
      ),
    );
  }
}

class _TargetArrowPainter extends CustomPainter {
  _TargetArrowPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final direction = (to - from);
    if (direction.distance < 24) return;

    final unit = direction / direction.distance;
    final tip = to - unit * 12;
    final tail = from + unit * 8;

    final shaftPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(tail, tip, shaftPaint);

    final perpendicular = Offset(-unit.dy, unit.dx);
    const headSize = 10.0;
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        tip.dx - perpendicular.dx * headSize * 0.55,
        tip.dy - perpendicular.dy * headSize * 0.55,
      )
      ..lineTo(
        tip.dx + perpendicular.dx * headSize * 0.55,
        tip.dy + perpendicular.dy * headSize * 0.55,
      )
      ..close();

    canvas.drawPath(
      head,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TargetArrowPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color;
  }
}

class _CalloutPlacement {
  const _CalloutPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.arrowDirection,
    required this.maxHeight,
  });

  final double left;
  final double top;
  final double width;
  final _ArrowDirection arrowDirection;
  final double maxHeight;

  Offset? get arrowAnchor {
    final centerX = left + width / 2;
    switch (arrowDirection) {
      case _ArrowDirection.up:
        return Offset(centerX, top);
      case _ArrowDirection.down:
        return Offset(centerX, top + maxHeight);
      case _ArrowDirection.left:
        return Offset(left + width, top + maxHeight / 2);
      case _ArrowDirection.right:
        return Offset(left, top + maxHeight / 2);
    }
  }

  static _CalloutPlacement forTarget(Rect hole, Size layerSize) {
    const margin = 16.0;
    const preferredWidth = 280.0;
    const preferredHeight = 300.0;
    const minimumUsableHeight = 140.0;

    final calloutWidth = math.min(
      preferredWidth,
      math.max(1.0, layerSize.width - margin * 2),
    );

    final centerX = hole.center.dx;
    final centeredLeft = (centerX - calloutWidth / 2)
        .clamp(
          margin,
          math.max(margin, layerSize.width - calloutWidth - margin),
        )
        .toDouble();

    final belowTop = hole.bottom + margin;
    final belowHeight = math.max(
      0.0,
      math.min(preferredHeight, layerSize.height - margin - belowTop),
    );
    final aboveBottom = hole.top - margin;
    final aboveHeight = math.max(
      0.0,
      math.min(preferredHeight, aboveBottom - margin),
    );

    if (belowHeight >= minimumUsableHeight ||
        aboveHeight >= minimumUsableHeight) {
      if (belowHeight >= aboveHeight) {
        return _CalloutPlacement(
          left: centeredLeft,
          top: belowTop,
          width: calloutWidth,
          arrowDirection: _ArrowDirection.up,
          maxHeight: belowHeight,
        );
      }
      return _CalloutPlacement(
        left: centeredLeft,
        top: aboveBottom - aboveHeight,
        width: calloutWidth,
        arrowDirection: _ArrowDirection.down,
        maxHeight: aboveHeight,
      );
    }

    // A very large target can leave no clean side for a readable prompt. In
    // that case the prompt wins: keep it fully on-screen and allow it to
    // overlap the spotlight instead of placing its controls off-screen.
    final viewportHeight = math.max(1.0, layerSize.height - margin * 2);
    final fallbackHeight = math.min(preferredHeight, viewportHeight);
    final targetIsBelowCard = hole.center.dy >= layerSize.height / 2;
    return _CalloutPlacement(
      left: centeredLeft,
      top: targetIsBelowCard
          ? margin
          : layerSize.height - margin - fallbackHeight,
      width: calloutWidth,
      arrowDirection: targetIsBelowCard
          ? _ArrowDirection.down
          : _ArrowDirection.up,
      maxHeight: fallbackHeight,
    );
  }
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({
    required this.theme,
    required this.text,
    required this.showNext,
    required this.isFinish,
    required this.onNext,
    required this.onSkip,
    required this.nextLabel,
    this.arrowDirection,
    this.maxHeight,
    this.showReturnToHatchery = false,
    this.onReturnToHatchery,
  });

  final BackgroundTheme theme;
  final String text;
  final bool showNext;
  final bool isFinish;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;
  final _ArrowDirection? arrowDirection;
  final double? maxHeight;
  final bool showReturnToHatchery;
  final VoidCallback? onReturnToHatchery;

  @override
  Widget build(BuildContext context) {
    final hasVerticalPointer =
        arrowDirection == _ArrowDirection.up ||
        arrowDirection == _ArrowDirection.down;
    final panelMaxHeight = maxHeight == null
        ? null
        : math.max(96.0, maxHeight! - (hasVerticalPointer ? 40 : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrowDirection == _ArrowDirection.up)
          _ArrowPointer(direction: arrowDirection!, theme: theme),
        Container(
          constraints: panelMaxHeight == null
              ? null
              : BoxConstraints(maxHeight: panelMaxHeight),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: GameTheme.panelDecoration(theme).copyWith(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 64),
                      child: _ScrollableTutorialText(
                        text: text,
                        color: theme.cardTextPrimaryColor,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -8,
                      child: TextButton.icon(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: theme.cardTextSecondaryColor,
                        ),
                        label: Text(
                          TutorialData.exitButtonLabel,
                          style: TextStyle(
                            color: theme.cardTextSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showReturnToHatchery && onReturnToHatchery != null) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onReturnToHatchery,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(
                    TutorialData.returnToHatcheryFallbackLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              if (showNext) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(
                    isFinish
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    nextLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (arrowDirection == _ArrowDirection.down)
          _ArrowPointer(direction: arrowDirection!, theme: theme),
      ],
    );
  }
}

class _ScrollableTutorialText extends StatefulWidget {
  const _ScrollableTutorialText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  State<_ScrollableTutorialText> createState() =>
      _ScrollableTutorialTextState();
}

class _ScrollableTutorialTextState extends State<_ScrollableTutorialText> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          widget.text,
          style: TextStyle(
            color: widget.color,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ArrowPointer extends StatelessWidget {
  const _ArrowPointer({required this.direction, required this.theme});

  final _ArrowDirection direction;
  final BackgroundTheme theme;

  static const _arrowColor = Color(0xFFFFEB3B);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (direction) {
      case _ArrowDirection.up:
        icon = Icons.arrow_drop_up;
      case _ArrowDirection.down:
        icon = Icons.arrow_drop_down;
      case _ArrowDirection.left:
        icon = Icons.arrow_left;
      case _ArrowDirection.right:
        icon = Icons.arrow_right;
    }

    return Icon(
      icon,
      size: 40,
      color: _arrowColor,
      shadows: const [
        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
      ],
    );
  }
}

/// Back-compat entry point for replay and external callers.
class TutorialOverlay {
  TutorialOverlay._();

  static void show(
    BuildContext context, {
    required GameService game,
    required BackgroundTheme theme,
    bool isReplay = false,
  }) {
    TutorialService.instance.attach(game: game, theme: theme);
    TutorialService.instance.showWelcome(isReplay: isReplay);
  }

  static void showAdvancedSecret(
    BuildContext context, {
    required GameService game,
    required BackgroundTheme theme,
  }) {
    TutorialService.instance.attach(game: game, theme: theme);
    TutorialService.instance.showAdvancedSecretWelcome();
  }
}
