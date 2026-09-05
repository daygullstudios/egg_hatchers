import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../data/tutorial_data.dart';
import '../models/background_theme.dart';
import '../navigation/app_page_route.dart';
import '../services/tutorial_target_registry.dart';
import 'game_service.dart';

enum TutorialPhase { inactive, welcome, guided }

/// Coordinates tutorial welcome choice, guided steps, and persistence.
class TutorialService extends ChangeNotifier {
  TutorialService._();
  static final TutorialService instance = TutorialService._();

  GameService? _game;
  BackgroundTheme? _theme;
  TutorialPhase _phase = TutorialPhase.inactive;
  TutorialFlow _flow = TutorialFlow.basics;
  var _stepIndex = 0;
  var _isReplay = false;
  var _pausedForDialog = false;

  TutorialPhase get phase => _phase;
  bool get isActive => _phase != TutorialPhase.inactive;
  bool get isGuided => _phase == TutorialPhase.guided;

  /// While welcome or guided tutorial is active, transient snackbars are suppressed.
  bool get shouldSuppressSnackBars => isActive;
  bool get isReplay => _isReplay;
  bool get pausedForDialog => _pausedForDialog;
  int get stepIndex => _stepIndex;
  TutorialFlow get flow => _flow;

  List<GuidedTutorialStep> get _steps => switch (_flow) {
    TutorialFlow.basics => TutorialData.steps,
    TutorialFlow.advancedSecret => TutorialData.advancedSecretSteps,
  };

  String get welcomeTitle => switch (_flow) {
    TutorialFlow.basics => TutorialData.welcomeTitle,
    TutorialFlow.advancedSecret => TutorialData.advancedSecretWelcomeTitle,
  };

  String get startButtonLabel => switch (_flow) {
    TutorialFlow.basics => TutorialData.startButtonLabel,
    TutorialFlow.advancedSecret => TutorialData.advancedSecretStartButtonLabel,
  };

  String get finishButtonLabel => switch (_flow) {
    TutorialFlow.basics => TutorialData.finishButtonLabel,
    TutorialFlow.advancedSecret => TutorialData.advancedSecretFinishButtonLabel,
  };

  GuidedTutorialStep? get currentStep {
    if (_phase != TutorialPhase.guided) return null;
    if (_stepIndex < 0 || _stepIndex >= _steps.length) {
      return null;
    }
    return _steps[_stepIndex];
  }

  BackgroundTheme? get theme => _theme;
  GameService? get game => _game;

  void attach({required GameService game, required BackgroundTheme theme}) {
    _game = game;
    _theme = theme;
  }

  void updateTheme(BackgroundTheme theme) {
    _theme = theme;
    if (isActive) notifyListeners();
  }

  void maybeAutoStartWelcome(GameService game) {
    if (_phase != TutorialPhase.inactive) return;
    if (!game.shouldAutoStartTutorial) return;
    _beginWelcome(isReplay: false, flow: TutorialFlow.basics);
  }

  void showWelcome({required bool isReplay}) {
    _beginWelcome(isReplay: isReplay, flow: TutorialFlow.basics);
  }

  void showAdvancedSecretWelcome() {
    _beginWelcome(isReplay: true, flow: TutorialFlow.advancedSecret);
  }

  void _beginWelcome({required bool isReplay, required TutorialFlow flow}) {
    _isReplay = isReplay;
    _flow = flow;
    _phase = TutorialPhase.welcome;
    _stepIndex = 0;
    _pausedForDialog = false;
    notifyListeners();
  }

  void startGuided() {
    _phase = TutorialPhase.guided;
    _stepIndex = 0;
    _scheduleRemeasure();
    notifyListeners();
  }

  void skipTutorial() {
    if (!_isReplay && _game != null) {
      _game!.skipTutorial();
    }
    _close();
  }

  void completeTutorial() {
    if (_flow == TutorialFlow.basics && !_isReplay && _game != null) {
      _game!.completeTutorial();
    }
    _close();
  }

  void _close() {
    _phase = TutorialPhase.inactive;
    _flow = TutorialFlow.basics;
    _stepIndex = 0;
    _isReplay = false;
    _pausedForDialog = false;
    notifyListeners();
  }

  void advanceNext({bool force = false}) {
    final step = currentStep;
    if (step == null) return;
    if (!force && !step.allowsManualNext && step.targetId != null) {
      if (!needsAffordabilityFallback(step)) return;
    }
    if (step.isFinish) {
      completeTutorial();
      return;
    }
    _stepIndex++;
    _scheduleRemeasure();
    notifyListeners();
  }

  void _advanceAfterAction() {
    final step = currentStep;
    if (step == null) return;
    if (step.isFinish) {
      completeTutorial();
      return;
    }
    _stepIndex++;
    _scheduleRemeasure();
    notifyListeners();
  }

  void onRouteChanged(String? routeName) {
    if (_phase != TutorialPhase.guided || _pausedForDialog) return;
    final step = currentStep;
    if (step == null) return;

    if (step.advanceOnRoute != null &&
        _routeMatches(step.advanceOnRoute, routeName)) {
      _advanceAfterAction();
      return;
    }

    _scheduleRemeasure();
    notifyListeners();
  }

  bool _routeMatches(String? expected, String? routeName) {
    if (expected == null) return false;
    if (expected == kHatcheryRouteName) {
      return _isHatcheryRoute(routeName);
    }
    return routeName == expected;
  }

  void notifyEggPurchased() {
    if (_phase != TutorialPhase.guided || _pausedForDialog) return;
    final step = currentStep;
    if (step?.advanceOnAction == TutorialAction.eggPurchased) {
      _advanceAfterAction();
    }
  }

  void notifyHatchDialogOpening() {
    _pausedForDialog = true;
    notifyListeners();
  }

  void notifyHatchDialogClosed() {
    _pausedForDialog = false;
    if (_phase != TutorialPhase.guided) return;
    _scheduleRemeasure();
    notifyListeners();
  }

  void notifyAnimalUpgraded() {
    if (_phase != TutorialPhase.guided || _pausedForDialog) return;
    final step = currentStep;
    if (step?.advanceOnAction == TutorialAction.animalUpgraded) {
      _advanceAfterAction();
    }
  }

  void invokeTargetTap(String targetId) {
    if (_phase != TutorialPhase.guided || _pausedForDialog) return;
    final step = currentStep;
    if (step?.targetId != targetId) return;
    TutorialTargetRegistry.handlerFor(targetId)?.call();
  }

  bool needsAffordabilityFallback(GuidedTutorialStep step) {
    final game = _game;
    if (game == null) return false;

    if (step.id == 'buyEgg') {
      final basicEgg = GameData.eggs.first;
      return !game.canAfford(basicEgg);
    }
    if (step.id == 'upgrade') {
      if (game.ownedAnimals.isEmpty) return true;
      final owned = game.normalAnimals.isNotEmpty
          ? game.normalAnimals.first
          : game.mutatedAnimals.first;
      final animal = GameData.animalById(owned.animalId);
      if (animal == null) return true;
      return !game.canAffordUpgrade(
        animal.id,
        owned.mutationId,
        isProtected: owned.isProtected,
      );
    }
    return false;
  }

  bool isFallbackMode(GuidedTutorialStep step, {required bool targetFound}) {
    if (!targetFound) return true;
    return needsAffordabilityFallback(step);
  }

  bool shouldUseFallback(GuidedTutorialStep step) {
    if (step.targetId == null) return true;
    return needsAffordabilityFallback(step);
  }

  String displayText(GuidedTutorialStep step, {required bool targetFound}) {
    if (isFallbackMode(step, targetFound: targetFound) &&
        step.fallbackText != null) {
      return step.fallbackText!;
    }
    return step.text;
  }

  bool showNextButton(GuidedTutorialStep step, {required bool targetFound}) {
    if (step.isFinish) return true;
    if (step.manualNext) return true;
    if (_usesTargetFallback(step, targetFound: targetFound)) return false;
    if (isFallbackMode(step, targetFound: targetFound)) return true;
    return false;
  }

  bool showTargetFallbackButton(
    GuidedTutorialStep step, {
    required bool targetFound,
  }) {
    if (!_usesTargetFallback(step, targetFound: targetFound)) return false;
    return TutorialTargetRegistry.handlerFor(step.targetId) != null;
  }

  void invokeTargetFallback(GuidedTutorialStep step) {
    if (currentStep != step || step.targetId == null) return;
    invokeTargetTap(step.targetId!);
  }

  bool _usesTargetFallback(
    GuidedTutorialStep step, {
    required bool targetFound,
  }) {
    if (targetFound || step.fallbackActionLabel == null) return false;
    return !needsAffordabilityFallback(step);
  }

  bool showReturnToHatcheryButton(
    GuidedTutorialStep step, {
    required bool targetFound,
  }) {
    return step.isBackStep && !targetFound;
  }

  void invokeReturnToHatcheryFallback() {
    TutorialTargetRegistry.handlerFor(
      TutorialTargetIds.screenBackButton,
    )?.call();
  }

  bool allowsProxyTargetTap(
    GuidedTutorialStep step, {
    required bool targetFound,
  }) {
    if (!step.requiresTargetTap) return false;
    if (isFallbackMode(step, targetFound: targetFound)) return false;
    return TutorialTargetRegistry.handlerFor(step.targetId) != null;
  }

  bool isStepVisibleOnCurrentRoute(String? routeName) {
    final step = currentStep;
    if (step == null) return false;
    if (step.requiredRoute == null) return true;
    if (step.requiredRoute == kHatcheryRouteName) {
      return _isHatcheryRoute(routeName);
    }
    return routeName == step.requiredRoute;
  }

  bool _isHatcheryRoute(String? routeName) {
    return routeName == null || routeName == kHatcheryRouteName;
  }

  void _scheduleRemeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isActive) notifyListeners();
    });
  }

  void requestScrollRemeasure() {
    if (_phase != TutorialPhase.guided || _pausedForDialog) return;
    _scheduleRemeasure();
  }

  void devStartTutorialNow() {
    _beginWelcome(isReplay: true, flow: TutorialFlow.basics);
  }
}
