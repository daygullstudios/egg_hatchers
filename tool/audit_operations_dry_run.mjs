import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const checklistPath = 'docs/OPERATIONS_DRY_RUN_CHECKLIST.md';
const backupRestoreDrillPath = 'docs/BACKUP_RESTORE_DRILL.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const monitoringPath = 'docs/RELEASE_MONITORING_EVIDENCE.md';
const operationsPath = 'docs/RELEASE_OPERATIONS_EVIDENCE.md';
const rollbackPath = 'docs/ROLLBACK_REHEARSAL_TEMPLATE.md';
const alertRunbookPath = 'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const workflowPath = '.github/workflows/verify.yml';

const files = {
  [checklistPath]: readFileSync(resolve(root, checklistPath), 'utf8'),
  [backupRestoreDrillPath]: readFileSync(resolve(root, backupRestoreDrillPath), 'utf8'),
  [runbookPath]: readFileSync(resolve(root, runbookPath), 'utf8'),
  [monitoringPath]: readFileSync(resolve(root, monitoringPath), 'utf8'),
  [operationsPath]: readFileSync(resolve(root, operationsPath), 'utf8'),
  [rollbackPath]: readFileSync(resolve(root, rollbackPath), 'utf8'),
  [alertRunbookPath]: readFileSync(resolve(root, alertRunbookPath), 'utf8'),
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [workflowPath]: readFileSync(resolve(root, workflowPath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'rehearsal aid only',
  'test data only',
  'docs/RELEASE_DECISION_PACKET.md',
  'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
  'docs/ROLLBACK_REHEARSAL_TEMPLATE.md',
  'docs/BACKUP_RESTORE_DRILL.md',
  'flutter analyze',
  'node tool/audit_monitoring_operations.mjs',
  'node tool/audit_rollback_rehearsal.mjs',
  'node tool/audit_release_candidate_record.mjs',
  'node tool/audit_release_surface.mjs',
  'flutter test',
  'flutter build web --release --no-pub',
  'npm run deploy:dry-run',
  'previous protected playtest Worker version ID',
  'D1 safety database backup/export reference',
  'Backup restore drill results',
  'Multiplayer capacity saturation',
  'privacy-safe synthetic events',
  'Do not mark the release roadmap operations or rollback items complete',
]) {
  requirePhrase(checklistPath, phrase);
}

for (const phrase of [
  'Firebase/Firestore backup reference',
  'D1 safety database backup/export reference',
  'Multiplayer Durable Object migration/export reference',
  'Release build artifact backup location',
  'Local progress restore',
  'Save Transfer restore',
  'Cloud account restore',
  'Safety database restore',
  'Multiplayer migration restore',
  'Release artifact restore',
  'A backup cannot be found, read or tied to the candidate build',
  'disposable or explicitly approved rehearsal data',
]) {
  requirePhrase(backupRestoreDrillPath, phrase);
}

for (const forbidden of [
  'player profile payloads',
  'progress payloads',
  'preset-message contents',
  'custom art',
  'animal rosters',
  'Save Transfer files',
  'identity tokens',
  'child/guardian information',
]) {
  requirePhrase(checklistPath, forbidden);
  requirePhrase(alertRunbookPath, forbidden);
}

for (const phrase of [
  'Cloudflare Worker Observability',
  'Flutter client has no production crash',
  'Monitoring must support operations without turning into player tracking',
]) {
  requirePhrase(monitoringPath, phrase);
}

for (const phrase of [
  'backup cadence',
  'restore rehearsal',
  'docs/BACKUP_RESTORE_DRILL.md',
  'Alert destinations',
  'Do not mark the roadmap operations item complete',
]) {
  requirePhrase(operationsPath, phrase);
}

for (const phrase of [
  'Rollback Path',
  'Backup restore drill result',
  'Smoke Check Results',
  'Do not mark the release roadmap rollback item complete',
]) {
  requirePhrase(rollbackPath, phrase);
}

for (const item of [
  '[ ] Confirm backups, restore procedures, rate limits and operational alerts.',
  '[ ] Test rollback to the previous protected version.',
]) {
  requirePhrase(roadmapPath, item);
}

requirePhrase(runbookPath, 'node tool/audit_operations_dry_run.mjs');
requirePhrase(runbookPath, 'Operations dry-run audit');
requirePhrase(runbookPath, 'docs/BACKUP_RESTORE_DRILL.md');
requirePhrase(workflowPath, 'node tool/audit_operations_dry_run.mjs');
requirePhrase(workflowPath, 'Verify operations dry-run checklist');

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Operations dry-run audit: rehearsal checklist, privacy boundary, backup restore drill and open release gates verified.',
);
