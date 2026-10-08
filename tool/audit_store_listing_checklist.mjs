import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const checklistPath = 'docs/STORE_LISTING_DRAFT_CHECKLIST.md';
const screenshotManifestPath = 'docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md';
const platformPath = 'docs/PLATFORM_STORE_READINESS.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidencePath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';

const files = {
  [checklistPath]: readFileSync(resolve(root, checklistPath), 'utf8'),
  [screenshotManifestPath]: readFileSync(resolve(root, screenshotManifestPath), 'utf8'),
  [platformPath]: readFileSync(resolve(root, platformPath), 'utf8'),
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [evidencePath]: readFileSync(resolve(root, evidencePath), 'utf8'),
  [candidatePath]: readFileSync(resolve(root, candidatePath), 'utf8'),
  [runbookPath]: readFileSync(resolve(root, runbookPath), 'utf8'),
  [workflowPath]: readFileSync(resolve(root, workflowPath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

if (!existsSync(resolve(root, checklistPath))) {
  failures.push(`${checklistPath}: missing store listing checklist`);
}

for (const phrase of [
  'does not select Android or iOS',
  'App name: Nestarium',
  'Do not promise public multiplayer removal of Bot Arena',
  'future events',
  'Corruption 3D battles',
  'premium currency',
  'paid randomized rewards',
  'developer tools hidden',
  'docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md',
  'candidate commit, build artifact, device/browser/OS, private-data check',
  'Cloudflare temporary tunnels',
  'Preset-message-only communication',
  'custom animal sprites are local to the device',
  'Google Play Data Safety and Apple privacy answers must come from the exact',
  'Do not add client analytics',
  'Owner approval for store submission',
  'Keep the roadmap platform/store items open',
]) {
  requirePhrase(checklistPath, phrase);
}

for (const phrase of [
  'does not approve store submission or public launch',
  'Candidate Git commit',
  'Selected launch platforms',
  'Screenshot capture owner',
  'Capture only the exact release candidate build',
  'Hide developer-only controls before capture',
  'Do not use Cloudflare temporary tunnel URLs',
  'private Save Transfer files',
  'Future-event/monetization claims absent',
  'Hatchery first-player flow',
  'Egg Shop',
  'Collection and fusion',
  'Manual boss fight',
  'Settings account/save controls',
  'Narrow phone layout',
  'release candidate record cites this manifest',
]) {
  requirePhrase(screenshotManifestPath, phrase);
}

for (const linked of [
  'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
  'docs/PUBLIC_POLICY_READINESS.md',
  'docs/FAMILY_AUDIENCE_V1.md',
  'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md',
  'docs/RELEASE_MONITORING_EVIDENCE.md',
  'docs/RELEASE_OPERATIONS_EVIDENCE.md',
  'docs/MONETIZATION_AND_AD_OPERATIONS.md',
]) {
  requirePhrase(checklistPath, linked);
  if (!existsSync(resolve(root, linked))) {
    failures.push(`${linked}: linked store-listing evidence does not exist`);
  }
}

for (const phrase of [
  'Store metadata and disclosure work must wait',
  'docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md',
  'Support and account-deletion links from every selected store',
]) {
  requirePhrase(platformPath, phrase);
}

for (const item of [
  '[ ] Complete store names, descriptions, screenshots, ratings and disclosures.',
  '[ ] Complete Google Play Data Safety and Apple privacy answers from the actual',
  '[ ] Verify account-deletion and support links from each selected store.',
]) {
  requirePhrase(roadmapPath, item);
}

for (const field of [
  'Store Data Safety/Privacy answers source reference',
  'Store screenshot manifest result',
  'Support/account-deletion URL',
  'Store submission approval',
]) {
  requirePhrase(candidatePath, field);
}

requirePhrase(evidencePath, checklistPath);
requirePhrase(evidencePath, screenshotManifestPath);
requirePhrase(runbookPath, 'node tool/audit_store_listing_checklist.mjs');
requirePhrase(runbookPath, screenshotManifestPath);
requirePhrase(runbookPath, 'Store listing checklist audit');
requirePhrase(workflowPath, 'node tool/audit_store_listing_checklist.mjs');
requirePhrase(workflowPath, 'Verify store listing checklist');

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Store listing checklist audit: metadata, screenshot manifest, ratings, privacy answers and open store gates verified.',
);
