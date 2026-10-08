import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const packetPath = 'docs/RELEASE_DECISION_PACKET.md';
const ownerDecisionFormPath = 'docs/RELEASE_OWNER_DECISION_FORM.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const assetRightsPath = 'docs/ASSET_RIGHTS_RELEASE_AUDIT.md';
const operationsPath = 'docs/RELEASE_OPERATIONS_EVIDENCE.md';
const monitoringPath = 'docs/RELEASE_MONITORING_EVIDENCE.md';
const familyAudiencePath = 'docs/FAMILY_AUDIENCE_V1.md';
const platformStorePath = 'docs/PLATFORM_STORE_READINESS.md';
const brandingPath = 'docs/PLATFORM_BRANDING_READINESS.md';
const androidBuildPath = 'android/app/build.gradle.kts';
const androidKeyExamplePath = 'android/key.properties.example';
const manifestPath = 'web/manifest.json';
const migrationPath = 'docs/NESTARIUM_MIGRATION.md';

const files = {
  [packetPath]: readFileSync(resolve(root, packetPath), 'utf8'),
  [ownerDecisionFormPath]: readFileSync(resolve(root, ownerDecisionFormPath), 'utf8'),
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [evidenceIndexPath]: readFileSync(resolve(root, evidenceIndexPath), 'utf8'),
  [assetRightsPath]: readFileSync(resolve(root, assetRightsPath), 'utf8'),
  [operationsPath]: readFileSync(resolve(root, operationsPath), 'utf8'),
  [monitoringPath]: readFileSync(resolve(root, monitoringPath), 'utf8'),
  [familyAudiencePath]: readFileSync(resolve(root, familyAudiencePath), 'utf8'),
  [platformStorePath]: readFileSync(resolve(root, platformStorePath), 'utf8'),
  [brandingPath]: readFileSync(resolve(root, brandingPath), 'utf8'),
  [androidBuildPath]: readFileSync(resolve(root, androidBuildPath), 'utf8'),
  [androidKeyExamplePath]: readFileSync(resolve(root, androidKeyExamplePath), 'utf8'),
  [manifestPath]: readFileSync(resolve(root, manifestPath), 'utf8'),
  [migrationPath]: readFileSync(resolve(root, migrationPath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

function requireFile(path) {
  if (!existsSync(resolve(root, path))) {
    failures.push(`${path}: expected release-decision evidence file to exist`);
  }
}

for (const path of Object.keys(files)) {
  requireFile(path);
}

for (const heading of [
  '### 1. Launch platforms',
  '### 2. Launch countries',
  '### 3. Release owner and rollback decision maker',
  '### 4. Final logo and platform branding approval',
  '### 5. Music and shipped-asset rights',
  '### 6. Monitoring, backups and alerts',
  '### 7. Family/privacy review path',
]) {
  requirePhrase(packetPath, heading);
}

for (const phrase of [
  'does not change runtime behavior',
  'does not change runtime behavior, publish a store listing, route a public',
  'Keep the unchecked roadmap items open until the',
  'Web only.',
  'Web plus Android.',
  'Web plus iOS.',
  'Web plus Android and iOS.',
  'Android source exists',
  'iOS source exists',
  'Do not assume the US-only privacy rules',
  'One release owner who can say whether the candidate is ready.',
  'One rollback decision maker who can decide to revert routing',
  'Approved: yes.',
  'Commit `99bd909` replaced the approved source image',
  'Confirm the source and commercial-use rights',
  'Approve the production privacy-safe monitoring and operations model',
  'Allowed operational fields.',
  'Log retention and support-access rules.',
  'Alert destinations.',
  'Backup cadence.',
  'Restore rehearsal owner and schedule.',
  'Choose how the professional family-audience/privacy review will happen',
  'First release platforms:',
  'First launch countries:',
  'Release owner:',
  'Rollback decision maker:',
  'Final logo approved: yes',
  'Music rights confirmed for the three listed files: yes/no',
  'Production monitoring/alerts owner:',
  'Family/privacy review owner or plan:',
  'docs/RELEASE_OWNER_DECISION_FORM.md',
  'continue polishing only non-publishing work',
]) {
  requirePhrase(packetPath, phrase);
}

for (const phrase of [
  'does not approve launch',
  'Decision Identity',
  'Launch Scope',
  'First release platforms',
  'First launch countries/regions',
  'Public playable route approval',
  'Store submission approval',
  'Bot Arena remains in 1.0',
  'Future events remain excluded from 1.0',
  'Rights And Branding',
  'Music rights confirmed for `assets/sounds/music/hatchery_chill_loop.mp3`',
  'Music rights confirmed for `assets/sounds/music/boss_music.wav`',
  'Music rights confirmed for `assets/sounds/music/final_boss_music.mp3`',
  'Family And Privacy',
  'Parent/guardian capability flow approved',
  'Candidate support/account-deletion instructions approved',
  'Monitoring And Operations',
  'Production monitoring/alerts owner',
  'Backup restore drill owner',
  'Multiplayer And Beta',
  'Trusted production session owner',
  'Load/capacity target and owner',
  'Closed beta entry approved',
  'Platform And Store',
  'Android credential owner',
  'iOS credential owner',
  'Support/deletion link verification owner',
  'Explicit Stop Conditions',
]) {
  requirePhrase(ownerDecisionFormPath, phrase);
}

for (const musicFile of [
  'assets/sounds/music/hatchery_chill_loop.mp3',
  'assets/sounds/music/boss_music.wav',
  'assets/sounds/music/final_boss_music.mp3',
]) {
  requirePhrase(packetPath, musicFile);
  requirePhrase(assetRightsPath, musicFile);
}

for (const item of [
  '[ ] Confirm launch platforms: web, Android and/or iOS.',
  '[ ] Confirm launch countries.',
  '[ ] Name one release owner and one rollback decision maker.',
  '[ ] Obtain professional audience/privacy review for the intended ages 8-12,',
  '[ ] Add production error monitoring that matches the approved privacy model.',
  '[ ] Confirm backups, restore procedures, rate limits and operational alerts.',
  '[ ] Confirm commercial rights and source records for every shipped asset.',
  '[x] Approve the final Nestarium logo and regenerate platform branding assets.',
  'Collect the owner decisions in `docs/RELEASE_DECISION_PACKET.md`',
]) {
  requirePhrase(roadmapPath, item);
}

for (const phrase of [
  'docs/RELEASE_DECISION_PACKET.md',
  'docs/RELEASE_OWNER_DECISION_FORM.md',
  'Open release dependencies: launch platforms, launch countries, release owner',
  'Open release dependencies: music rights, volume normalization and platform audio',
  'Open release dependencies: approved production monitoring, alert destinations',
  'Start with `docs/RELEASE_DECISION_PACKET.md`.',
]) {
  requirePhrase(evidenceIndexPath, phrase);
}

for (const phrase of [
  'android/app/build.gradle.kts',
  'android/key.properties',
]) {
  requirePhrase(packetPath, phrase);
}

for (const phrase of [
  'hasReleaseSigning',
  'signingConfigs',
]) {
  requirePhrase(androidBuildPath, phrase);
}

requirePhrase(androidKeyExamplePath, 'storeFile=../upload-keystore.jks');
requirePhrase(manifestPath, '"name": "Nestarium"');
requirePhrase(migrationPath, 'playtest.playnestarium.com');
requirePhrase(migrationPath, 'playnestarium.com');
requirePhrase(platformStorePath, 'selected launch platforms');
requirePhrase(platformStorePath, 'launch countries');
requirePhrase(brandingPath, 'approved source');
requirePhrase(operationsPath, 'named release owner and rollback decision maker');
requirePhrase(monitoringPath, 'Alert destinations');
requirePhrase(familyAudiencePath, 'Professional review required');

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Release decision audit: owner decisions, launch blockers, rights, monitoring and family-review dependencies verified.',
);
