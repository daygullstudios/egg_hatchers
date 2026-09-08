# Nestarium monetization and ad operations

Decision recorded: 2026-09-08. This document is the product and release
contract for the first Nestarium monetization model. It is not authorization to
turn on production advertising or store checkout by itself.

## Approved product model

- The complete core game remains free.
- The permanent list price for **Remove Ads Forever** is **US $2.99**. A real
  storefront-localized price is authoritative wherever it is available.
- An honest, time-bounded **US $1.99 launch promotion** may be used later. Do
  not describe $2.99 as a discount or raise it merely to manufacture a sale.
- Removal is one non-consumable, account-scoped lifetime entitlement named
  `ad_free`. A linked/protected player is required before purchase so ownership
  can be recovered across installs and platforms.
- No real-money premium currency, paid randomized egg, paid hatch, loot box or
  paid route around an earned random reward is approved for launch.
- Interstitial and rewarded ads are not approved for the initial release.

## Banner placement contract

An anchored adaptive banner may appear only at the bottom of ordinary browsing
destinations in the persistent game shell:

- Hatchery
- Shop
- Collection
- Quests
- Custom Animals

Do not show advertising in Battles, Settings, tutorials, dialogs, editors,
manual or online battles, multiplayer/trading flows, fusion decisions, account
or progress recovery, conflict resolution, onboarding, or another focused route.
An unavailable, loading or rejected ad occupies no layout space.

## Implemented dormant boundary

The Flutter application contains a single monetization controller, an
account-scoped RevenueCat entitlement gateway, a native AdMob/UMP adaptive
banner provider, a deliberately unavailable web provider, shell placement, and
conditional Settings purchase/restore controls. Android and iOS contain
Google's published sample application IDs solely so test initialization is
possible, with app measurement explicitly delayed until initialization;
production IDs are not in source.

Ordinary builds set `NESTARIUM_MONETIZATION_APPROVED=false` implicitly. Even an
approved build remains unable to request an ad until all of these runtime gates
pass:

1. the build approval switch is true;
2. a platform RevenueCat key and ad unit are supplied outside source;
3. a Firebase player identity exists and the entitlement read succeeds;
4. the session has an explicit reviewed child/general audience treatment;
5. the consent provider says ads may be requested; and
6. the player does not own `ad_free`.

Unknown audience, uncertain ownership, provider error, missing configuration or
consent failure suppresses advertising. The purchase UI is absent unless the
store provider is configured, and purchase is disabled for an unprotected
player. A positive entitlement is cached per Firebase UID; uncertainty never
reintroduces ads.

## Production activation gates

Complete these together at a deliberate monetization release checkpoint:

1. Obtain launch-territory and intended-audience review for the actual candidate,
   including COPPA/mixed-audience, Google Play Families and Apple Kids-category
   implications. Approve the neutral age/guardian capability design.
2. Implement the reviewed per-session audience decision that calls the central
   controller. Do not use an adult default or infer age from gameplay skill.
3. Approve providers and their current family terms. Use a Google Play Families
   self-certified ads SDK where applicable, configure UMP/privacy choices and
   keep requests non-personalized with the strictest appropriate rating.
4. Create/verify the owned AdMob apps and banner units for the unchanged Android
   package and iOS bundle IDs. Replace both sample app IDs and supply real unit
   IDs only through release configuration.
5. Select and approve a web ad provider, publisher identity, child/privacy
   treatment, consent integration and bounded responsive placement. The current
   web provider must remain unavailable until then.
6. Configure RevenueCat for the existing apps, the `ad_free` entitlement,
   lifetime products and any approved web billing path. Store API keys and
   credentials outside Git.
7. Add matching non-consumable products in Google Play and App Store Connect.
   Do not submit or publish them during ordinary development.
8. Update privacy disclosures, store Data Safety/Privacy Nutrition answers,
   support/refund operations and the public product site from verified provider
   behavior—not generic templates.
9. Test purchase, cancellation, pending transactions, restore, refund/revocation,
   account switching, reinstall, offline/uncertain entitlement, cross-device and
   cross-platform ownership using sandbox accounts. Confirm no ad overlaps or
   shifts controls at every supported size and text scale.
10. Run one consolidated release gate, record owner approval, and activate only
    the reviewed platforms. A failure on one platform does not authorize a
    weaker fallback there.

### Shared Android-device scheduling

The only physical Android device is temporarily reserved for Grids & Aces Google
Play purchase testing. Continue Nestarium's family decision, provider-console
configuration, store-product drafting, Android builds, web work and automated
acceptance without it. Do not disturb the G&A install/test state. At the final
candidate boundary, after the device is released, run one consolidated Google
Play sequence covering install, protected-account purchase, cancellation,
pending/failure handling, ad removal, restart, restore, reinstall and account
recovery. A successful emulator or debug APK build does not close that gate.

## Operations and change control

The protected playtest and public preview must make no claim that ads or paid
removal are currently available while the activation switch is off. Test ad
serving, sandbox purchases and provider-console mutations require an explicit
test plan. Production serving, product publication, price changes, refunds and
store submission remain recorded owner actions.

Any later proposal for interstitials, rewarded ads, subscriptions, consumables
or premium currency is a new product decision and needs separate family,
economy, UX and disclosure review.
