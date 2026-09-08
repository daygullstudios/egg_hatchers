/// Owner-approved commercial contract. Storefronts remain authoritative for
/// localized prices; these values are copy fallbacks and release assertions.
abstract final class NestariumMonetizationPolicy {
  static const adFreeEntitlementId = 'ad_free';
  static const defaultAdFreePriceUsd = 2.99;
  static const defaultAdFreePriceLabel = r'$2.99';
  static const optionalLaunchPriceUsd = 1.99;
  static const optionalLaunchPriceLabel = r'$1.99';

  /// This is intentionally false in ordinary builds. A monetized build must
  /// opt in only after the family, consent, policy, provider, and store gates
  /// documented in docs/MONETIZATION_AND_AD_OPERATIONS.md have passed.
  static const productionActivationApproved = bool.fromEnvironment(
    'NESTARIUM_MONETIZATION_APPROVED',
    defaultValue: false,
  );
}
