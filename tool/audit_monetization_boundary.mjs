import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const operationsPath = 'docs/MONETIZATION_AND_AD_OPERATIONS.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const familyPath = 'docs/FAMILY_AUDIENCE_V1.md';
const policyPath = 'lib/monetization/monetization_policy.dart';
const controllerTestPath = 'test/monetization_controller_test.dart';
const webProviderPath = 'lib/monetization/banner_ad_provider_web.dart';
const stubProviderPath = 'lib/monetization/banner_ad_provider_stub.dart';
const mobileProviderPath = 'lib/monetization/banner_ad_provider_mobile.dart';
const entitlementPath = 'lib/monetization/ad_free_entitlement_service.dart';
const shellPath = 'lib/screens/main_game_shell.dart';
const settingsPath = 'lib/screens/settings_screen.dart';
const androidManifestPath = 'android/app/src/main/AndroidManifest.xml';
const iosInfoPath = 'ios/Runner/Info.plist';
const pubspecPath = 'pubspec.yaml';

const operations = readFileSync(resolve(root, operationsPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const family = readFileSync(resolve(root, familyPath), 'utf8');
const policy = readFileSync(resolve(root, policyPath), 'utf8');
const controllerTest = readFileSync(resolve(root, controllerTestPath), 'utf8');
const webProvider = readFileSync(resolve(root, webProviderPath), 'utf8');
const stubProvider = readFileSync(resolve(root, stubProviderPath), 'utf8');
const mobileProvider = readFileSync(resolve(root, mobileProviderPath), 'utf8');
const entitlement = readFileSync(resolve(root, entitlementPath), 'utf8');
const shell = readFileSync(resolve(root, shellPath), 'utf8');
const settings = readFileSync(resolve(root, settingsPath), 'utf8');
const androidManifest = readFileSync(resolve(root, androidManifestPath), 'utf8');
const iosInfo = readFileSync(resolve(root, iosInfoPath), 'utf8');
const pubspec = readFileSync(resolve(root, pubspecPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'not authorization to',
  'complete core game remains free',
  'Remove Ads Forever',
  'US $2.99',
  'US $1.99 launch promotion',
  '`ad_free`',
  'No real-money premium currency',
  'paid randomized egg',
  'Interstitial and rewarded ads are not approved',
  'NESTARIUM_MONETIZATION_APPROVED=false',
  'Unknown audience, uncertain ownership, provider error, missing configuration or',
  'protected playtest and public preview must make no claim',
]) {
  requirePhrase(operationsPath, operations, phrase);
}

for (const destination of [
  'Hatchery',
  'Shop',
  'Collection',
  'Quests',
  'Custom Animals',
]) {
  requirePhrase(operationsPath, operations, destination);
}

for (const forbiddenSurface of [
  'Battles',
  'Settings',
  'manual or online battles',
  'multiplayer/trading flows',
  'progress recovery',
]) {
  requirePhrase(operationsPath, operations, forbiddenSurface);
}

for (const phrase of [
  "adFreeEntitlementId = 'ad_free'",
  'defaultAdFreePriceUsd = 2.99',
  "defaultAdFreePriceLabel = r'$2.99'",
  'optionalLaunchPriceUsd = 1.99',
  "optionalLaunchPriceLabel = r'$1.99'",
  'NESTARIUM_MONETIZATION_APPROVED',
  'defaultValue: false',
]) {
  requirePhrase(policyPath, policy, phrase);
}

for (const phrase of [
  'ordinary builds never initialize monetization providers',
  'purchase and restore reject unprotected player ownership',
  'unknown audience treatment suppresses approved providers',
  'banner requires a successful entitlement check and no purchase',
  'banner slot occupies no space until every gate passes',
]) {
  requirePhrase(controllerTestPath, controllerTest, phrase);
}

for (const [path, text] of [
  [webProviderPath, webProvider],
  [stubProviderPath, stubProvider],
]) {
  for (const phrase of [
    'configured => false',
    'initialize(AdAudienceTreatment treatment) async => false',
    'SizedBox.shrink',
  ]) {
    requirePhrase(path, text, phrase);
  }
}

for (const phrase of [
  'ADMOB_ANDROID_BANNER_ID',
  'ADMOB_IOS_BANNER_ID',
  'NESTARIUM_TEST_ADS_ENABLED',
  'kDebugMode && _testAdsEnabled',
  'AdRequest(nonPersonalizedAds: true)',
  'ConsentInformation.instance.canRequestAds()',
  'AgeRestrictedTreatment.child',
]) {
  requirePhrase(mobileProviderPath, mobileProvider, phrase);
}

for (const phrase of [
  'REVENUECAT_WEB_API_KEY',
  'REVENUECAT_ANDROID_API_KEY',
  'REVENUECAT_IOS_API_KEY',
  'automaticDeviceIdentifierCollectionEnabled = false',
  'diagnosticsEnabled = false',
  'uncertain entitlement response both suppress ads',
]) {
  requirePhrase(entitlementPath, entitlement, phrase);
}

for (const phrase of [
  'MonetizationBannerSlot',
  'MainGameDestination.hatchery',
  'MainGameDestination.shop',
  'MainGameDestination.collection',
  'MainGameDestination.quests',
  'MainGameDestination.customAnimals',
  'MainGameDestination.battles',
  'MainGameDestination.settings',
]) {
  requirePhrase(shellPath, shell, phrase);
}

for (const phrase of [
  'purchasesConfigured',
  'Remove Ads Forever',
  'One purchase removes banner ads forever on this protected Nestarium account.',
]) {
  requirePhrase(settingsPath, settings, phrase);
}

for (const phrase of [
  'ca-app-pub-3940256099942544~3347511713',
  'DELAY_APP_MEASUREMENT_INIT',
]) {
  requirePhrase(androidManifestPath, androidManifest, phrase);
}

for (const phrase of [
  'ca-app-pub-3940256099942544~1458002511',
  'GADDelayAppMeasurementInit',
]) {
  requirePhrase(iosInfoPath, iosInfo, phrase);
}

for (const phrase of [
  'google_mobile_ads:',
  'purchases_flutter:',
]) {
  requirePhrase(pubspecPath, pubspec, phrase);
}

for (const phrase of [
  'Dormant monetization boundary',
  'protected-playtest builds cannot request ads or expose checkout',
]) {
  requirePhrase(familyPath, family, phrase);
}

for (const phrase of [
  '[ ] Keep monetization dormant unless its separate operations plan is complete.',
  'Active banner ads or Remove Ads checkout until every monetization gate passes.',
  'Interstitial ads, rewarded ads, premium currency and paid randomized rewards.',
]) {
  requirePhrase(roadmapPath, roadmap, phrase);
}

requirePhrase(evidenceIndexPath, evidenceIndex, 'docs/MONETIZATION_AND_AD_OPERATIONS.md');

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Monetization boundary audit: default-off ads, purchase gates, placement limits and release blockers verified.',
);
