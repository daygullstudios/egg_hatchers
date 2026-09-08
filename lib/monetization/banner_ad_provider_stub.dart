import 'package:flutter/widgets.dart';

import 'banner_ad_provider.dart';

BannerAdProvider createPlatformBannerAdProvider() =>
    _UnavailableBannerProvider();

final class _UnavailableBannerProvider implements BannerAdProvider {
  @override
  bool get configured => false;

  @override
  Future<bool> initialize(AdAudienceTreatment treatment) async => false;

  @override
  Widget buildBanner({required double availableWidth}) =>
      const SizedBox.shrink();

  @override
  Future<void> showPrivacyOptions() async {}
}
