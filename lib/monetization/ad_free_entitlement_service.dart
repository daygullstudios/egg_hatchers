import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monetization_policy.dart';

final class AdFreePurchaseResult {
  const AdFreePurchaseResult({required this.success, required this.message});

  final bool success;
  final String message;
}

abstract interface class AdFreeEntitlementGateway implements Listenable {
  bool get configured;
  bool get hasAdFree;
  bool get entitlementCheckSucceeded;
  bool get busy;
  String? get localizedPrice;

  Future<void> initialize();
  Future<AdFreePurchaseResult> purchase();
  Future<AdFreePurchaseResult> restore();
}

/// RevenueCat-backed lifetime ad removal. A positive local cache and any
/// uncertain entitlement response both suppress ads; uncertainty never punishes
/// a player with advertising.
final class AdFreeEntitlementService extends ChangeNotifier
    implements AdFreeEntitlementGateway {
  AdFreeEntitlementService({
    this.activationApproved =
        NestariumMonetizationPolicy.productionActivationApproved,
  });

  static const _cacheKeyPrefix = 'nestarium_ad_free_entitlement_v1';
  static const _webApiKey = String.fromEnvironment('REVENUECAT_WEB_API_KEY');
  static const _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const _iosApiKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');

  final bool activationApproved;

  bool _initialized = false;
  bool _sdkConfigured = false;
  bool _configured = false;
  bool _hasAdFree = false;
  bool _entitlementCheckSucceeded = false;
  bool _busy = false;
  String? _localizedPrice;
  Package? _adFreePackage;
  StreamSubscription<User?>? _authSubscription;
  String? _currentAppUserId;

  @override
  bool get configured => _configured;
  @override
  bool get hasAdFree => _hasAdFree;
  @override
  bool get entitlementCheckSucceeded => _entitlementCheckSucceeded;
  @override
  bool get busy => _busy;
  @override
  String? get localizedPrice => _localizedPrice;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final apiKey = _apiKeyForPlatform();
    if (!activationApproved || apiKey.isEmpty || Firebase.apps.isEmpty) return;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChange,
    );
  }

  @override
  Future<AdFreePurchaseResult> purchase() async {
    if (!_configured || _adFreePackage == null) {
      return const AdFreePurchaseResult(
        success: false,
        message: 'Ad removal is not available on this build yet.',
      );
    }
    if (_busy) {
      return const AdFreePurchaseResult(
        success: false,
        message: 'A purchase is already in progress.',
      );
    }
    _setBusy(true);
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(_adFreePackage!),
      );
      await _applyCustomerInfo(result.customerInfo);
      return AdFreePurchaseResult(
        success: _hasAdFree,
        message: _hasAdFree
            ? 'Ads removed on this Nestarium account.'
            : 'The store did not activate ad removal.',
      );
    } catch (error) {
      return AdFreePurchaseResult(
        success: false,
        message: _purchaseErrorMessage(error),
      );
    } finally {
      _setBusy(false);
    }
  }

  @override
  Future<AdFreePurchaseResult> restore() async {
    if (!_configured) {
      return const AdFreePurchaseResult(
        success: false,
        message: 'Purchase restoration is not available on this build yet.',
      );
    }
    if (_busy) {
      return const AdFreePurchaseResult(
        success: false,
        message: 'A store request is already in progress.',
      );
    }
    _setBusy(true);
    try {
      final info = await Purchases.restorePurchases();
      await _applyCustomerInfo(info);
      return AdFreePurchaseResult(
        success: _hasAdFree,
        message: _hasAdFree
            ? 'Ad removal restored.'
            : 'No ad-removal purchase was found.',
      );
    } catch (_) {
      return const AdFreePurchaseResult(
        success: false,
        message: 'The store could not restore purchases. Try again later.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _refreshCustomerInfo() async {
    try {
      await _applyCustomerInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      _entitlementCheckSucceeded = false;
    }
  }

  Future<void> _refreshOffering() async {
    try {
      final offering = (await Purchases.getOfferings()).current;
      final package =
          offering?.lifetime ??
          offering?.getPackage(r'$rc_lifetime') ??
          offering?.getPackage(NestariumMonetizationPolicy.adFreeEntitlementId);
      _adFreePackage = package;
      _localizedPrice = package?.storeProduct.priceString;
    } catch (_) {
      _adFreePackage = null;
      _localizedPrice = null;
    }
  }

  Future<void> _applyCustomerInfo(CustomerInfo info) async {
    final active = info.entitlements.active.containsKey(
      NestariumMonetizationPolicy.adFreeEntitlementId,
    );
    _entitlementCheckSucceeded = true;
    _hasAdFree = active;
    final appUserId = _currentAppUserId;
    if (appUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKeyFor(appUserId), active);
    }
    notifyListeners();
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      _currentAppUserId = null;
      _configured = false;
      _entitlementCheckSucceeded = false;
      _hasAdFree = false;
      notifyListeners();
      return;
    }
    if (_currentAppUserId == user.uid && _configured) return;
    _currentAppUserId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    _hasAdFree = prefs.getBool(_cacheKeyFor(user.uid)) ?? false;
    _entitlementCheckSucceeded = false;
    notifyListeners();
    try {
      if (!_sdkConfigured) {
        final configuration = PurchasesConfiguration(_apiKeyForPlatform())
          ..appUserID = user.uid
          ..automaticDeviceIdentifierCollectionEnabled = false
          ..diagnosticsEnabled = false;
        await Purchases.configure(configuration);
        _sdkConfigured = true;
        Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
        await Future.wait([_refreshCustomerInfo(), _refreshOffering()]);
      } else {
        final info = (await Purchases.logIn(user.uid)).customerInfo;
        await _applyCustomerInfo(info);
        await _refreshOffering();
      }
      _configured = true;
      notifyListeners();
    } catch (_) {
      _configured = false;
      _entitlementCheckSucceeded = false;
      notifyListeners();
    }
  }

  static String _cacheKeyFor(String appUserId) => '$_cacheKeyPrefix.$appUserId';

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  String _apiKeyForPlatform() {
    if (kIsWeb) return _webApiKey;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidApiKey,
      TargetPlatform.iOS => _iosApiKey,
      _ => '',
    };
  }

  static String _purchaseErrorMessage(Object error) {
    if (error is PlatformException) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return 'Purchase cancelled.';
      }
    }
    return 'The store could not complete the purchase. Try again later.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
