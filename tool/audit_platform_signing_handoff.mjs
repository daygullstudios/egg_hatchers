import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const handoffPath = 'docs/PLATFORM_SIGNING_HANDOFF.md';
const readinessPath = 'docs/PLATFORM_STORE_READINESS.md';
const storeChecklistPath = 'docs/STORE_LISTING_DRAFT_CHECKLIST.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const decisionPath = 'docs/RELEASE_DECISION_PACKET.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';
const androidIgnorePath = 'android/.gitignore';
const androidKeyExamplePath = 'android/key.properties.example';

const handoff = readFileSync(resolve(root, handoffPath), 'utf8');
const readiness = readFileSync(resolve(root, readinessPath), 'utf8');
const storeChecklist = readFileSync(resolve(root, storeChecklistPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const decision = readFileSync(resolve(root, decisionPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');
const releaseEvidenceAudit = readFileSync(resolve(root, releaseEvidenceAuditPath), 'utf8');
const androidIgnore = readFileSync(resolve(root, androidIgnorePath), 'utf8');
const androidKeyExample = readFileSync(resolve(root, androidKeyExamplePath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const heading of [
  '## Handoff identity',
  '## Android signing handoff',
  '## iOS signing handoff',
  '## Shared store handoff',
  '## Evidence to attach',
  '## Repository safety check',
]) {
  requirePhrase(handoffPath, handoff, heading);
}

for (const phrase of [
  'does not select a platform',
  'create credentials',
  'approve store submission',
  'Selected platforms',
  'Credential owner',
  'Credential storage location reference',
]) {
  requirePhrase(handoffPath, handoff, phrase);
}

for (const phrase of [
  'Google Play upload keystore outside the repository',
  'approved password manager',
  'android/key.properties.example',
  'android/key.properties',
  '*.jks',
  '*.keystore',
  'signed App Bundle',
  'App Bundle path and checksum',
  'package name',
  'version code',
  'Google Play Data Safety answers',
]) {
  requirePhrase(handoffPath, handoff, phrase);
}

for (const phrase of [
  'Apple Developer account',
  'Team ID',
  'bundle identifier',
  'certificates',
  'provisioning profiles',
  'App Store Connect credentials',
  'real-device test',
  'archive/build identifier',
  'Apple privacy answers',
]) {
  requirePhrase(handoffPath, handoff, phrase);
}

for (const phrase of [
  'docs/STORE_LISTING_DRAFT_CHECKLIST.md',
  'docs/FAMILY_PRIVACY_REVIEW_INTAKE.md',
  'docs/MUSIC_RIGHTS_AND_LISTENING_SIGNOFF.md',
  'docs/ASSET_RIGHTS_RELEASE_AUDIT.md',
  'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md',
  'dirty working tree',
  'release owner and rollback decision',
]) {
  requirePhrase(handoffPath, handoff, phrase);
}

for (const phrase of [
  'Candidate commit and tag/build',
  'Selected platforms and launch countries',
  'Android App Bundle checksum',
  'iOS archive/build identifier',
  'Store listing copy source version',
  'Screenshot capture commit and device list',
  'Support/account-deletion URL verification result',
  'Signing credential storage reference without secrets',
  'Owner approval for store submission',
]) {
  requirePhrase(handoffPath, handoff, phrase);
}

for (const phrase of [
  'Android remains blocked',
  'Credential protection',
  'android/key.properties',
  '**/*.keystore',
  '**/*.jks',
  'iOS source is present',
  'Store metadata and disclosure work must wait',
]) {
  requirePhrase(readinessPath, readiness, phrase);
}

for (const phrase of [
  'Android signed App Bundle path/checksum',
  'iOS archive/build identifier and real-device test result',
  'Owner approval for store submission',
]) {
  requirePhrase(storeChecklistPath, storeChecklist, phrase);
}

for (const phrase of [
  'Android App Bundle path/checksum',
  'iOS archive/build identifier',
  'Store Data Safety/Privacy answers source reference',
  'Store submission approval, if selected',
]) {
  requirePhrase(candidatePath, candidate, phrase);
}

for (const phrase of [
  'First release platforms:',
  'First launch countries:',
]) {
  requirePhrase(decisionPath, decision, phrase);
}

for (const item of [
  '[ ] Configure Android release signing and protect the signing credentials.',
  '[ ] Build and inspect a signed Android App Bundle if Android is selected.',
  '[ ] Configure iOS signing and run real-device testing if iOS is selected.',
  '[ ] Complete store names, descriptions, screenshots, ratings and disclosures.',
  '[ ] Complete Google Play Data Safety and Apple privacy answers from the actual',
  '[ ] Verify account-deletion and support links from each selected store.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const ignored of ['key.properties', '**/*.keystore', '**/*.jks']) {
  requirePhrase(androidIgnorePath, androidIgnore, ignored);
}

for (const field of [
  'storePassword=replace-with-keystore-password',
  'keyPassword=replace-with-key-password',
  'keyAlias=upload',
  'storeFile=../upload-keystore.jks',
]) {
  requirePhrase(androidKeyExamplePath, androidKeyExample, field);
}

for (const privatePath of [
  'android/key.properties',
  'android/upload-keystore.jks',
  'android/upload-keystore.keystore',
]) {
  if (existsSync(resolve(root, privatePath))) {
    failures.push(`${privatePath}: private signing material must not be present in the repository checkout`);
  }
}

for (const phrase of [
  handoffPath,
  'node tool/audit_platform_signing_handoff.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_platform_signing_handoff.mjs',
  'Verify platform signing handoff',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, handoffPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Platform signing handoff audit: credential boundaries, Android/iOS evidence, and store submission gates verified.',
);
