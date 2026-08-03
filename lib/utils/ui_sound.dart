import 'package:flutter/widgets.dart';

import '../data/audio_assets.dart';
import '../widgets/audio_scope.dart';
import '../widgets/purchase_celebration.dart';

/// Shared UI/reward SFX helpers (respect SFX toggle + volume via [AudioService]).
abstract final class UiSound {
  UiSound._();

  static void click(BuildContext context) {
    AudioScope.maybeOf(context)?.playSfx(Sfx.uiTap, volumeScale: 0.58);
  }

  static void confirm(BuildContext context) {
    AudioScope.maybeOf(context)?.playSfx(Sfx.confirm, volumeScale: 0.72);
  }

  static void purchase(BuildContext context) {
    AudioScope.maybeOf(context)?.playSfx(Sfx.purchase, volumeScale: 0.84);
    PurchaseCelebration.show(context);
  }

  static void locked(BuildContext context) {
    AudioScope.maybeOf(context)?.playSfx(Sfx.errorLocked);
  }

  static void rewardTriumph(BuildContext context) {
    AudioScope.maybeOf(context)?.playRewardTriumph();
  }

  static void rewardBigTriumph(BuildContext context) {
    AudioScope.maybeOf(context)?.playBigRewardTriumph();
  }
}
