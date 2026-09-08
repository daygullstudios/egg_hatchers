import 'package:flutter/widgets.dart';

import 'banner_ad_provider.dart';

/// Web banner serving remains unavailable until an approved H5/display provider,
/// consent integration, publisher ID, and responsive slot are provisioned.
BannerAdProvider createPlatformBannerAdProvider() =>
    _DormantWebBannerProvider();

final class _DormantWebBannerProvider implements BannerAdProvider {
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
