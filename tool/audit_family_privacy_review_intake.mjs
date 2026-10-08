import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const intakePath = 'docs/FAMILY_PRIVACY_REVIEW_INTAKE.md';
const responseTemplatePath = 'docs/FAMILY_PRIVACY_REVIEW_RESPONSE_TEMPLATE.md';
const familyPath = 'docs/FAMILY_AUDIENCE_V1.md';
const capabilityEvidencePath = 'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md';
const policyPath = 'docs/PUBLIC_POLICY_READINESS.md';
const decisionPath = 'docs/RELEASE_DECISION_PACKET.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const intake = readFileSync(resolve(root, intakePath), 'utf8');
const responseTemplate = readFileSync(resolve(root, responseTemplatePath), 'utf8');
const family = readFileSync(resolve(root, familyPath), 'utf8');
const capabilityEvidence = readFileSync(resolve(root, capabilityEvidencePath), 'utf8');
const policy = readFileSync(resolve(root, policyPath), 'utf8');
const decision = readFileSync(resolve(root, decisionPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');
const releaseEvidenceAudit = readFileSync(
  resolve(root, releaseEvidenceAuditPath),
  'utf8',
);

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const path of [
  intakePath,
  responseTemplatePath,
  familyPath,
  capabilityEvidencePath,
  policyPath,
  decisionPath,
]) {
  if (!existsSync(resolve(root, path))) {
    failures.push(`${path}: required family/privacy review file does not exist`);
  }
}

for (const heading of [
  '## Review identity',
  '## Product audience to review',
  '## Data and capability questions',
  '## Current technical evidence',
  '## Required reviewer output',
  '## Acceptance evidence after implementation',
  '## Stop conditions',
]) {
  requirePhrase(intakePath, intake, heading);
}

for (const phrase of [
  'not legal clearance',
  'launch approval',
  'store submission approval',
  'approval to collect child data',
  'ages 8-12, teens, and adults',
  'Do not relabel the game as 13+',
  'preset-only',
  'open text chat',
  'public custom-art sharing',
  'Custom eggs are retired',
  'Monetization remains dormant',
]) {
  requirePhrase(intakePath, intake, phrase);
}

for (const phrase of [
  'Which age bands are allowed',
  'What age/region question may be asked',
  'guardian consent or parent-managed permission process',
  'separate guardian permissions',
  'consent evidence',
  'retention windows and deletion triggers',
  'parent/guardian request',
  'Google Play Data Safety',
  'Apple privacy answers',
  'Google Sign-In',
  'firebase_crashlytics',
  'firebase_analytics',
  'sentry_flutter',
]) {
  requirePhrase(intakePath, intake, phrase);
}

for (const phrase of [
  'docs/FAMILY_AUDIENCE_V1.md',
  'docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md',
  'docs/PUBLIC_POLICY_READINESS.md',
  'docs/RELEASE_DECISION_PACKET.md',
  'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md',
  'docs/RELEASE_SECURITY_REVIEW.md',
  'docs/RELEASE_MONITORING_EVIDENCE.md',
  'docs/RELEASE_OPERATIONS_EVIDENCE.md',
  'docs/MONETIZATION_AND_AD_OPERATIONS.md',
  'docs/CLOSED_BETA_TESTER_PACKET.md',
]) {
  requirePhrase(intakePath, intake, phrase);
}

for (const phrase of [
  'Hosted capabilities fail closed',
  'Battle, trading, preset-message, and profile-discovery capabilities',
  'Profile discovery is not approved',
  'preset-only',
  'Reports use bounded preset reasons',
  'Blocks prevent battle and trade matching',
  'public information site is separated',
  'Client analytics and crash telemetry SDKs are absent',
]) {
  requirePhrase(intakePath, intake, phrase);
}

for (const phrase of [
  'Audience classification',
  'Approved age/region handling text',
  'Capability matrix',
  'Data inventory',
  'Support/account-deletion verification process',
  'Monitoring/logging boundary',
  'Accepted risks',
  'Reviewer approval date and owner sign-off',
  'docs/FAMILY_PRIVACY_REVIEW_RESPONSE_TEMPLATE.md',
]) {
  requirePhrase(intakePath, intake, phrase);
}

for (const phrase of [
  'not legal clearance unless',
  'Reviewer role/qualification',
  'Candidate commit reviewed',
  'Privacy Policy version reviewed',
  'Audience Classification',
  'Approved Capability Matrix',
  'Allowed for unknown user',
  'Allowed for restricted child',
  'Separate guardian permission required',
  'Age And Guardian Flow',
  'Approved age/region question text',
  'Parent-managed permission review process',
  'Non-Google recovery route',
  'Data Inventory And Retention',
  'Firebase Authentication',
  'Firestore progress/cloud save',
  'D1 safety reports, blocks and capability claims',
  'Public Policy And Store Disclosures',
  'Google Play Data Safety answers',
  'Apple privacy answers',
  'Accepted Risks And Launch Blocks',
  'Required implementation changes before beta',
  'Required tests before public launch',
  'release candidate record does not cite this filled review response',
]) {
  requirePhrase(responseTemplatePath, responseTemplate, phrase);
}

for (const phrase of [
  'fresh unknown user makes no optional cloud identity',
  'restricted player can complete, save, reopen, export, and import',
  'parent-approved route enables only the capabilities approved',
  'Denial, revocation, account switch, import, refresh, and reconnect',
  'Existing saves, device guests, linked cloud accounts, and Save Transfer files',
  'Store/privacy answers match the exact candidate behavior',
]) {
  requirePhrase(intakePath, intake, phrase);
}

for (const phrase of [
  'Professional review required',
  'Five bounded requirements',
]) {
  requirePhrase(familyPath, family, phrase);
}

for (const phrase of [
  'technical evidence only',
  'professional audience/privacy review',
]) {
  requirePhrase(capabilityEvidencePath, capabilityEvidence, phrase);
}

for (const phrase of [
  'Complete professional family/privacy review.',
  'updated disclosures before launch',
]) {
  requirePhrase(policyPath, policy, phrase);
}

for (const phrase of [
  'Family/privacy review path',
  'ages 8-12, teens and adults',
]) {
  requirePhrase(decisionPath, decision, phrase);
}

for (const item of [
  '[ ] Obtain professional audience/privacy review for the intended ages 8-12,',
  '[ ] Implement the approved age/guardian capability flow before optional data',
  '[ ] Add parent-managed permissions, review, revocation and deletion controls.',
  '[ ] Finalize retention rules and provider responsibilities.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  intakePath,
  responseTemplatePath,
  'node tool/audit_family_privacy_review_intake.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_family_privacy_review_intake.mjs',
  'Verify family privacy review intake',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, intakePath);
requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, responseTemplatePath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Family privacy review intake audit: review questions, evidence packet, acceptance criteria and stop conditions verified.',
);
