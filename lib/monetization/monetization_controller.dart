import 'dart:async';

import 'package:flutter/widgets.dart';

import 'ad_free_entitlement_service.dart';
import 'banner_ad_provider.dart';
import 'monetization_policy.dart';

/// Central fail-open boundary for ads and the lifetime ad-free entitlement.
/// An explicit build gate, a reviewed per-session audience treatment, a
/// successful entitlement read, and provider consent must all pass before an ad
/// can appear.
final class MonetizationController extends ChangeNotifier {
  MonetizationController({
    AdFreeEntitlementGateway? entitlement,
    BannerAdProvider? bannerProvider,
    this.activationApproved =
        NestariumMonetizationPolicy.productionActivationApproved,
  }) : _entitlement = entitlement ?? AdFreeEntitlementService(),
       _bannerProvider = bannerProvider ?? createBannerAdProvider();

  static final instance = MonetizationController();

  final AdFreeEntitlementGateway _entitlement;
  final BannerAdProvider _bannerProvider;
  final bool activationApproved;

  bool _initialized = false;
  bool _providerReady = false;
  bool _providerStarting = false;
  AdAudienceTreatment _audienceTreatment = AdAudienceTreatment.unknown;

  bool get hasAdFree => _entitlement.hasAdFree;
  bool get purchasesConfigured =>
      activationApproved &&
      _entitlement.configured &&
      _entitlement.entitlementCheckSucceeded;
  bool get entitlementBusy => _entitlement.busy;
  bool get entitlementCheckSucceeded => _entitlement.entitlementCheckSucceeded;
  String? get localizedAdFreePrice => _entitlement.localizedPrice;
  AdAudienceTreatment get audienceTreatment => _audienceTreatment;

  bool get mayDisplayBanner =>
      activationApproved &&
      _audienceTreatment != AdAudienceTreatment.unknown &&
      _providerReady &&
      _bannerProvider.configured &&
      _entitlement.entitlementCheckSucceeded &&
      !_entitlement.hasAdFree;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _entitlement.addListener(_handleEntitlementChanged);
    if (activationApproved) await _entitlement.initialize();
    await _initializeProviderIfPermitted();
    notifyListeners();
  }

  /// Called only by the future reviewed age/guardian capability boundary.
  /// Unknown immediately suppresses ads and is always the startup default.
  Future<void> setAudienceTreatmentForSession(
    AdAudienceTreatment treatment,
  ) async {
    if (_audienceTreatment == treatment) return;
    _audienceTreatment = treatment;
    _providerReady = false;
    notifyListeners();
    await _initializeProviderIfPermitted();
  }

  Future<AdFreePurchaseResult> purchaseAdFree({
    required bool accountProtected,
  }) => accountProtected
      ? _entitlement.purchase()
      : Future.value(
          const AdFreePurchaseResult(
            success: false,
            message:
                'Protect this player before purchasing so ad removal can be recovered.',
          ),
        );

  Future<AdFreePurchaseResult> restoreAdFree({
    required bool accountProtected,
  }) => accountProtected
      ? _entitlement.restore()
      : Future.value(
          const AdFreePurchaseResult(
            success: false,
            message:
                'Protect this player before restoring purchases across devices.',
          ),
        );

  Future<void> showPrivacyOptions() => _bannerProvider.showPrivacyOptions();

  Widget buildBanner({required double availableWidth}) => mayDisplayBanner
      ? _bannerProvider.buildBanner(availableWidth: availableWidth)
      : const SizedBox.shrink();

  Future<void> _initializeProviderIfPermitted() async {
    if (!activationApproved ||
        _providerStarting ||
        _providerReady ||
        !_bannerProvider.configured ||
        _audienceTreatment == AdAudienceTreatment.unknown ||
        !_entitlement.entitlementCheckSucceeded ||
        _entitlement.hasAdFree) {
      return;
    }
    _providerStarting = true;
    try {
      _providerReady = await _bannerProvider.initialize(_audienceTreatment);
    } catch (_) {
      _providerReady = false;
    } finally {
      _providerStarting = false;
      notifyListeners();
    }
  }

  void _handleEntitlementChanged() {
    if (_entitlement.hasAdFree || !_entitlement.entitlementCheckSucceeded) {
      _providerReady = false;
    } else {
      unawaited(_initializeProviderIfPermitted());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _entitlement.removeListener(_handleEntitlementChanged);
    super.dispose();
  }
}
