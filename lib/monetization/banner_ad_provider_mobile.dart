import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'banner_ad_provider.dart';

BannerAdProvider createPlatformBannerAdProvider() =>
    MobileAdMobBannerProvider();

final class MobileAdMobBannerProvider implements BannerAdProvider {
  static const _androidProductionUnit = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
  );
  static const _iosProductionUnit = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
  );
  static const _testAdsEnabled = bool.fromEnvironment(
    'NESTARIUM_TEST_ADS_ENABLED',
    defaultValue: false,
  );
  static const _androidTestUnit = 'ca-app-pub-3940256099942544/9214589741';
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/2435281174';

  bool _initialized = false;
  bool _mayRequestAds = false;
  AdAudienceTreatment? _configuredTreatment;

  String get _productionUnit => switch (defaultTargetPlatform) {
    TargetPlatform.android => _androidProductionUnit,
    TargetPlatform.iOS => _iosProductionUnit,
    _ => '',
  };

  String get _unitId => kDebugMode && _testAdsEnabled
      ? switch (defaultTargetPlatform) {
          TargetPlatform.android => _androidTestUnit,
          TargetPlatform.iOS => _iosTestUnit,
          _ => '',
        }
      : _productionUnit;

  @override
  bool get configured => _unitId.isNotEmpty;

  @override
  Future<bool> initialize(AdAudienceTreatment treatment) async {
    if (treatment == AdAudienceTreatment.unknown || !configured) return false;
    if (_initialized && _configuredTreatment == treatment) {
      return _mayRequestAds;
    }
    _mayRequestAds = await _requestConsent(treatment);
    if (!_mayRequestAds) return false;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: treatment == AdAudienceTreatment.childDirected
            ? MaxAdContentRating.g
            : MaxAdContentRating.pg,
        ageRestrictedTreatment: treatment == AdAudienceTreatment.childDirected
            ? AgeRestrictedTreatment.child
            : AgeRestrictedTreatment.unspecified,
      ),
    );
    if (!_initialized) {
      await MobileAds.instance.initialize();
      _initialized = true;
    }
    _configuredTreatment = treatment;
    return true;
  }

  Future<bool> _requestConsent(AdAudienceTreatment treatment) async {
    final completion = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        tagForUnderAgeOfConsent: treatment == AdAudienceTreatment.childDirected,
      ),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        completion.complete(await ConsentInformation.instance.canRequestAds());
      },
      (_) => completion.complete(false),
    );
    return completion.future;
  }

  @override
  Widget buildBanner({required double availableWidth}) {
    if (!_initialized || !_mayRequestAds || !configured) {
      return const SizedBox.shrink();
    }
    return _AdaptiveBannerSurface(
      unitId: _unitId,
      availableWidth: availableWidth,
    );
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!_initialized) return;
    await ConsentForm.showPrivacyOptionsForm((_) {});
  }
}

class _AdaptiveBannerSurface extends StatefulWidget {
  const _AdaptiveBannerSurface({
    required this.unitId,
    required this.availableWidth,
  });

  final String unitId;
  final double availableWidth;

  @override
  State<_AdaptiveBannerSurface> createState() => _AdaptiveBannerSurfaceState();
}

class _AdaptiveBannerSurfaceState extends State<_AdaptiveBannerSurface> {
  BannerAd? _banner;
  AdSize? _size;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _AdaptiveBannerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.availableWidth - widget.availableWidth).abs() >= 1 ||
        oldWidget.unitId != widget.unitId) {
      _banner?.dispose();
      _banner = null;
      _size = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (_loading || widget.availableWidth < 1) return;
    _loading = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      widget.availableWidth.floor(),
    );
    if (!mounted || size == null) {
      _loading = false;
      return;
    }
    final banner = BannerAd(
      adUnitId: widget.unitId,
      size: size,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _size = size;
            _loading = false;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loading = false);
        },
      ),
    );
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    final size = _size;
    if (banner == null || size == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: SizedBox(
            width: size.width.toDouble(),
            height: size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }
}
