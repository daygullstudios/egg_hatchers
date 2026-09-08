import 'package:flutter/widgets.dart';

import 'banner_ad_provider_stub.dart'
    if (dart.library.io) 'banner_ad_provider_mobile.dart'
    if (dart.library.js_interop) 'banner_ad_provider_web.dart';

enum AdAudienceTreatment { unknown, childDirected, generalAudience }

abstract interface class BannerAdProvider {
  bool get configured;

  Future<bool> initialize(AdAudienceTreatment treatment);

  Widget buildBanner({required double availableWidth});

  Future<void> showPrivacyOptions();
}

BannerAdProvider createBannerAdProvider() => createPlatformBannerAdProvider();
