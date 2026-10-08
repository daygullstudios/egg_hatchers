import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const checklistPath = 'docs/SUPPORT_DELETION_LINK_VERIFICATION.md';
const publicPolicyPath = 'docs/PUBLIC_POLICY_READINESS.md';
const deletionEvidencePath = 'docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md';
const storeChecklistPath = 'docs/STORE_LISTING_DRAFT_CHECKLIST.md';
const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const publicAuditPath = 'tool/audit_public_policy_links.mjs';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const checklist = readFileSync(resolve(root, checklistPath), 'utf8');
const publicPolicy = readFileSync(resolve(root, publicPolicyPath), 'utf8');
const deletionEvidence = readFileSync(resolve(root, deletionEvidencePath), 'utf8');
const storeChecklist = readFileSync(resolve(root, storeChecklistPath), 'utf8');
const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const publicAudit = readFileSync(resolve(root, publicAuditPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');
const releaseEvidenceAudit = readFileSync(resolve(root, releaseEvidenceAuditPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const heading of [
  '## Verification identity',
  '## Public routes to verify',
  '## Store-entry checks',
  '## In-app checks',
  '## Support inbox checks',
  '## Deletion evidence to attach',
  '## Stop conditions',
]) {
  requirePhrase(checklistPath, checklist, heading);
}

for (const phrase of [
  'does not publish policy copy',
  'approve public launch',
  'approve store submission',
  'Candidate Git commit',
  'Support owner',
  'Launch platforms',
  'Launch countries',
  'Public site version',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const route of [
  'https://playnestarium.com/support',
  'https://playnestarium.com/privacy',
  'https://playnestarium.com/terms',
  'https://playnestarium.com/delete-account',
]) {
  requirePhrase(checklistPath, checklist, route);
}

for (const phrase of [
  'Loads without authentication',
  'approved Nestarium domain',
  'no playtest link',
  'temporary tunnel',
  'Flutter bundle',
  'tracker',
  'credential',
  'private support document',
  'approved role address',
  'exact candidate behavior',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'Store/platform name',
  'Support URL shown in the store',
  'Privacy Policy URL shown in the store',
  'Terms URL shown in the store',
  'Account-deletion URL shown in the store',
  'Google Play Data Safety',
  'Apple privacy answers',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'Settings exposes account/save controls',
  'Delete cloud account',
  'synced cloud progress are deleted',
  'local player remains on the device',
  'Remove local player',
  'local-only',
  'Save Transfer export/import',
  'Provider reauthentication prompts',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'support@playnestarium.com',
  'launch@playnestarium.com',
  'legal@daygullstudios.com',
  'passwords',
  'one-time codes',
  'authentication tokens',
  'Save Transfer files',
  'retention and deletion rules',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'docs/RELEASE_CLOUD_ACCOUNT_DELETION_EVIDENCE.md',
  'docs/PUBLIC_POLICY_READINESS.md',
  'cloudflare/public-site/src/delete-account.html',
  'cloudflare/public-site/src/support.html',
  'test/settings_account_test.dart',
  'test/account_protection_service_test.dart',
  'Public-site release audit result',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'wrong support, privacy, terms, or deletion URL',
  'delete-account` copy disagrees',
  'Support mail does not receive or reply correctly',
  'public page exposes a playtest route',
  'cloud deletion fails to preserve local progress',
  'Local player removal is described as cloud deletion',
  'Provider reauthentication blocks deletion',
]) {
  requirePhrase(checklistPath, checklist, phrase);
}

for (const phrase of [
  'Verify the support/account-deletion links from every selected store.',
  'Support/account-deletion URL',
  'support instructions',
]) {
  requirePhrase(candidatePath, candidate, phrase);
}

for (const phrase of [
  'Verify account-deletion and support links from each selected store.',
  'Complete store names, descriptions, screenshots, ratings and disclosures.',
]) {
  requirePhrase(roadmapPath, roadmap, phrase);
}

for (const phrase of [
  'Verify the support/account-deletion links from every selected store.',
  'Confirm role-address delivery and reply ownership.',
]) {
  requirePhrase(publicPolicyPath, publicPolicy, phrase);
}

for (const phrase of [
  'Support/account-deletion URL verification result',
  'Owner approval for store submission',
]) {
  requirePhrase(storeChecklistPath, storeChecklist, phrase);
}

for (const phrase of [
  'Delete cloud account',
  'The local player stays on this device',
  'Cloud account deleted. This local player remains on this device',
]) {
  requirePhrase(deletionEvidencePath, deletionEvidence, phrase);
}

for (const phrase of [
  'support@playnestarium.com',
  'launch@playnestarium.com',
  'legal@daygullstudios.com',
  'delete-account.html',
]) {
  requirePhrase(publicAuditPath, publicAudit, phrase);
}

for (const phrase of [
  checklistPath,
  'node tool/audit_support_deletion_links.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_support_deletion_links.mjs',
  'Verify support and deletion links',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, checklistPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Support/deletion link audit: public routes, store links, in-app deletion, inbox checks and stop conditions verified.',
);
