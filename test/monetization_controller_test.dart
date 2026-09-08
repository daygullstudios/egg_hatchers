import 'package:egg_hatchers/monetization/ad_free_entitlement_service.dart';
import 'package:egg_hatchers/monetization/banner_ad_provider.dart';
import 'package:egg_hatchers/monetization/monetization_controller.dart';
import 'package:egg_hatchers/monetization/monetization_policy.dart';
import 'package:egg_hatchers/widgets/monetization_banner_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('approved lifetime prices remain the release contract', () {
    expect(NestariumMonetizationPolicy.defaultAdFreePriceUsd, 2.99);
    expect(NestariumMonetizationPolicy.defaultAdFreePriceLabel, r'$2.99');
    expect(NestariumMonetizationPolicy.optionalLaunchPriceUsd, 1.99);
    expect(NestariumMonetizationPolicy.optionalLaunchPriceLabel, r'$1.99');
  });

  test('ordinary builds never initialize monetization providers', () async {
    final entitlement = _FakeEntitlement();
    final banner = _FakeBannerProvider();
    final controller = MonetizationController(
      entitlement: entitlement,
      bannerProvider: banner,
      activationApproved: false,
    );

    await controller.initialize();
    await controller.setAudienceTreatmentForSession(
      AdAudienceTreatment.generalAudience,
    );

    expect(entitlement.initializeCalls, 0);
    expect(banner.initializeCalls, 0);
    expect(controller.purchasesConfigured, isFalse);
    expect(controller.mayDisplayBanner, isFalse);
    controller.dispose();
  });

  test('purchase and restore reject unprotected player ownership', () async {
    final entitlement = _FakeEntitlement();
    final controller = MonetizationController(
      entitlement: entitlement,
      bannerProvider: _FakeBannerProvider(),
      activationApproved: true,
    );
    await controller.initialize();

    final purchase = await controller.purchaseAdFree(accountProtected: false);
    final restore = await controller.restoreAdFree(accountProtected: false);

    expect(purchase.success, isFalse);
    expect(restore.success, isFalse);
    expect(entitlement.purchaseCalls, 0);
    expect(entitlement.restoreCalls, 0);
    controller.dispose();
  });

  test('unknown audience treatment suppresses approved providers', () async {
    final entitlement = _FakeEntitlement();
    final banner = _FakeBannerProvider();
    final controller = MonetizationController(
      entitlement: entitlement,
      bannerProvider: banner,
      activationApproved: true,
    );

    await controller.initialize();

    expect(entitlement.initializeCalls, 1);
    expect(banner.initializeCalls, 0);
    expect(controller.mayDisplayBanner, isFalse);
    controller.dispose();
  });

  test(
    'banner requires a successful entitlement check and no purchase',
    () async {
      final entitlement = _FakeEntitlement();
      final banner = _FakeBannerProvider();
      final controller = MonetizationController(
        entitlement: entitlement,
        bannerProvider: banner,
        activationApproved: true,
      );

      await controller.initialize();
      await controller.setAudienceTreatmentForSession(
        AdAudienceTreatment.childDirected,
      );

      expect(banner.initializeCalls, 1);
      expect(banner.lastTreatment, AdAudienceTreatment.childDirected);
      expect(controller.mayDisplayBanner, isTrue);

      await controller.setAudienceTreatmentForSession(
        AdAudienceTreatment.generalAudience,
      );
      expect(banner.initializeCalls, 2);
      expect(banner.lastTreatment, AdAudienceTreatment.generalAudience);

      entitlement.setEntitlement(hasAdFree: true, checkSucceeded: true);
      expect(controller.mayDisplayBanner, isFalse);

      entitlement.setEntitlement(hasAdFree: false, checkSucceeded: false);
      expect(controller.mayDisplayBanner, isFalse);
      controller.dispose();
    },
  );

  testWidgets('banner slot occupies no space until every gate passes', (
    tester,
  ) async {
    final entitlement = _FakeEntitlement();
    final banner = _FakeBannerProvider();
    final controller = MonetizationController(
      entitlement: entitlement,
      bannerProvider: banner,
      activationApproved: true,
    );
    await controller.initialize();

    Future<void> pumpSlot({required bool placementAllowed}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  MonetizationBannerSlot(
                    controller: controller,
                    placementAllowed: placementAllowed,
                  ),
                ],
              ),
            ),
          ),
        );

    await pumpSlot(placementAllowed: true);
    expect(find.byKey(const ValueKey('fake-banner')), findsNothing);

    await controller.setAudienceTreatmentForSession(
      AdAudienceTreatment.generalAudience,
    );
    await pumpSlot(placementAllowed: false);
    expect(find.byKey(const ValueKey('fake-banner')), findsNothing);

    await pumpSlot(placementAllowed: true);
    expect(find.byKey(const ValueKey('fake-banner')), findsOneWidget);
    controller.dispose();
  });
}

final class _FakeEntitlement extends ChangeNotifier
    implements AdFreeEntitlementGateway {
  @override
  final bool configured = true;
  @override
  bool hasAdFree = false;
  @override
  bool entitlementCheckSucceeded = true;
  @override
  bool busy = false;
  @override
  String? localizedPrice = r'$2.99';
  int initializeCalls = 0;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> initialize() async => initializeCalls += 1;

  void setEntitlement({required bool hasAdFree, required bool checkSucceeded}) {
    this.hasAdFree = hasAdFree;
    entitlementCheckSucceeded = checkSucceeded;
    notifyListeners();
  }

  @override
  Future<AdFreePurchaseResult> purchase() async {
    purchaseCalls += 1;
    return const AdFreePurchaseResult(success: true, message: 'Purchased');
  }

  @override
  Future<AdFreePurchaseResult> restore() async {
    restoreCalls += 1;
    return const AdFreePurchaseResult(success: true, message: 'Restored');
  }
}

final class _FakeBannerProvider implements BannerAdProvider {
  int initializeCalls = 0;
  AdAudienceTreatment? lastTreatment;

  @override
  bool configured = true;

  @override
  Widget buildBanner({required double availableWidth}) =>
      const SizedBox(key: ValueKey('fake-banner'), height: 50);

  @override
  Future<bool> initialize(AdAudienceTreatment treatment) async {
    initializeCalls += 1;
    lastTreatment = treatment;
    return true;
  }

  @override
  Future<void> showPrivacyOptions() async {}
}
