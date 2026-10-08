import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const candidatePath = 'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const decisionPacketPath = 'docs/RELEASE_DECISION_PACKET.md';
const rollbackPath = 'docs/ROLLBACK_REHEARSAL_TEMPLATE.md';
const monitoringRunbookPath = 'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md';
const crossPlatformPath = 'docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md';

const candidate = readFileSync(resolve(root, candidatePath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const runbook = readFileSync(resolve(root, runbookPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const decisionPacket = readFileSync(resolve(root, decisionPacketPath), 'utf8');
const rollback = readFileSync(resolve(root, rollbackPath), 'utf8');
const monitoringRunbook = readFileSync(resolve(root, monitoringRunbookPath), 'utf8');
const crossPlatform = readFileSync(resolve(root, crossPlatformPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const heading of [
  '## Candidate identity',
  '## Build artifacts',
  '## Verification summary',
  '## Data, backups and rollback',
  '## Privacy, family and support',
  '## Open risks',
  '## Approval',
  '## Post-release monitoring',
]) {
  requirePhrase(candidatePath, candidate, heading);
}

for (const field of [
  'Candidate name',
  'Candidate date',
  'Release owner',
  'Rollback decision maker',
  'Git commit',
  'Git tag, if any',
  'Version name/build number',
  'Selected launch platforms',
  'Selected launch countries',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const field of [
  'Web build command',
  'Web build artifact location or checksum',
  'Android App Bundle path/checksum, if Android is selected',
  'iOS archive/build identifier, if iOS is selected',
  'Public information site version, if updated',
  'Protected playtest Worker version ID',
  'Multiplayer Worker version ID',
  'Canary Worker version ID, if used',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const field of [
  '`flutter analyze`',
  '`flutter test`',
  '`flutter build web --release`',
  'Cloudflare playtest build/test/dry-run/deploy',
  'Multiplayer Worker tests/dry-run/deploy',
  'Public-site tests/dry-run/deploy, if updated',
  'Brand audit',
  'Asset rights audit',
  'Accessibility/layout/audio acceptance',
  'Two-device internet play',
  'Load/capacity test',
  'Account/save/multiplayer acceptance matrix',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const field of [
  'Firebase/Firestore backup reference',
  'D1 safety database backup/export reference',
  'Multiplayer Durable Object migration/export reference, if relevant',
  'Release build artifact backup location',
  'Previous protected version ID',
  'Rollback test result',
  'Restore rehearsal result',
  'Known data-retention constraints',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const field of [
  'Professional family/privacy review reference',
  'Approved age/guardian capability flow reference',
  'Candidate Privacy Policy URL/version',
  'Candidate Terms URL/version',
  'Support/account-deletion URL',
  'Store Data Safety/Privacy answers source reference',
  'Monitoring/alert owner and destinations',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const field of [
  'Critical risks',
  'High risks',
  'Medium risks',
  'Low risks',
  'Release owner approval',
  'Rollback decision maker approval',
  'Public routing approval',
  'Store submission approval, if selected',
  'First-hour checks',
  'First-day checks',
  'Save/account checks',
  'Multiplayer/trading checks',
  'Support inbox checks',
  'Rollback trigger thresholds',
]) {
  requirePhrase(candidatePath, candidate, field);
}

for (const phrase of [
  'Do not fill it',
  'do not treat this file as launch approval',
  'Critical and high risks should be empty unless',
]) {
  requirePhrase(candidatePath, candidate, phrase);
}

for (const phrase of [
  '[ ] Record the exact commit, build numbers, infrastructure versions and backup.',
  '[ ] Obtain explicit owner approval for public routing and store submission.',
  '[ ] Release gradually and monitor saves, identity, crashes and multiplayer.',
]) {
  requirePhrase(roadmapPath, roadmap, phrase);
}

for (const phrase of [
  'The release candidate record should cite the CI run URL and artifact reference.',
  'Candidate Deployment Evidence',
  'in `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`',
]) {
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
  'Fill a dated copy',
  'frozen candidate',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

for (const phrase of [
  'Release owner and rollback decision maker',
  'First release platforms:',
  'First launch countries:',
]) {
  requirePhrase(decisionPacketPath, decisionPacket, phrase);
}

for (const phrase of [
  '`docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md` entry updated',
  'Rollback rehearsal passed',
]) {
  requirePhrase(rollbackPath, rollback, phrase);
}

for (const phrase of [
  'The release candidate record cites this runbook',
  'Rollback trigger thresholds',
]) {
  requirePhrase(monitoringRunbookPath, monitoringRunbook, phrase);
}

for (const phrase of [
  'release candidate\nrecord',
  'release-owner-approved Pass',
]) {
  requirePhrase(crossPlatformPath, crossPlatform, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Release candidate record audit: identity, artifacts, verification, rollback, privacy, risks and approvals verified.',
);
