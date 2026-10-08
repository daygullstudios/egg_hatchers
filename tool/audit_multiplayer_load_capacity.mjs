import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const rehearsalPath = 'docs/MULTIPLAYER_LOAD_CAPACITY_REHEARSAL.md';
const productionPath = 'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md';
const twoDevicePath = 'docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md';
const migrationPath = 'docs/MULTIPLAYER_SHARD_MIGRATION.md';
const monitoringPath = 'docs/RELEASE_MONITORING_EVIDENCE.md';
const alertRunbookPath = 'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const runbookPath = 'docs/RELEASE_VERIFICATION_RUNBOOK.md';
const workflowPath = '.github/workflows/verify.yml';
const releaseEvidenceAuditPath = 'tool/audit_release_evidence.mjs';

const rehearsal = readFileSync(resolve(root, rehearsalPath), 'utf8');
const production = readFileSync(resolve(root, productionPath), 'utf8');
const twoDevice = readFileSync(resolve(root, twoDevicePath), 'utf8');
const migration = readFileSync(resolve(root, migrationPath), 'utf8');
const monitoring = readFileSync(resolve(root, monitoringPath), 'utf8');
const alertRunbook = readFileSync(resolve(root, alertRunbookPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
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
  '## Rehearsal identity',
  '## Existing protected evidence',
  '## Required preconditions',
  '## Load plan',
  '## Measurements',
  '## Pass criteria',
  '## Stop conditions',
  '## Evidence to attach',
]) {
  requirePhrase(rehearsalPath, rehearsal, heading);
}

for (const phrase of [
  'does not authorize public multiplayer',
  'selected candidate environment',
  'Selected launch size',
  'Intended concurrent session target',
  'Rollback decision maker',
  '32-session per-shard guardrail',
  '503',
  'Retry-After',
  'does not prove public traffic',
]) {
  requirePhrase(rehearsalPath, rehearsal, phrase);
}

for (const phrase of [
  'Launch platforms and launch countries are chosen',
  'Family/privacy capability model is approved',
  'Monitoring and rollback owners are available',
  'docs/MULTIPLAYER_TWO_DEVICE_PLAYTEST_SCRIPT.md',
  'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md',
  'No real child data',
]) {
  requirePhrase(rehearsalPath, rehearsal, phrase);
}

for (const phrase of [
  'Number of accounts/sessions to open',
  'Session ramp-up rate',
  'Battle invite ratio',
  'Random matchmaking ratio',
  'Trade invite/cancel/complete ratio',
  'Reconnect/refresh ratio',
  'Report/block spot-check count',
  'Cost/latency budget',
]) {
  requirePhrase(rehearsalPath, rehearsal, phrase);
}

for (const phrase of [
  'Sessions attempted',
  'Sessions accepted',
  'Sessions rejected',
  'Battle settlement count',
  'Duplicate settlement count',
  'One-sided trade count',
  'Receipt redelivery count',
  'p50/p95/max connection latency',
  'Worker error count',
  'D1/safety database error count',
  'Estimated cost',
]) {
  requirePhrase(rehearsalPath, rehearsal, phrase);
}

for (const phrase of [
  'Battle rewards are delivered once',
  'No duplicate reward is minted',
  'No one-sided trade occurs',
  'Completed trades move both roster items exactly once',
  'Canceled and disconnected trades preserve both rosters',
  'Reconnects stay limited to the verified same Firebase identity',
  'Preset messages remain preset-only',
  'privacy',
]) {
  requirePhrase(rehearsalPath, rehearsal, phrase);
}

for (const phrase of [
  'accepts more sessions than the approved guardrail',
  'Capacity errors lack `Retry-After`',
  'duplicate battle settlement pays twice',
  'trade completes on only one side',
  'duplicate UID keeps two active playable sessions',
  'Denied, expired, revoked, or stale capabilities',
  'Logs expose profile payloads',
  'Latency or error rates exceed',
]) {
  requirePhrase(rehearsalPath, rehearsal, phrase);
}

for (const phrase of [
  'Capacity and Load',
  'Intended concurrent session target',
  'Expected 503/Retry-After behavior at guardrail',
  'selected launch size',
]) {
  requirePhrase(productionPath, production, phrase);
}

for (const phrase of [
  'Capacity spot check',
  'protected 32-session guardrail',
  '503',
  'Retry-After',
]) {
  requirePhrase(twoDevicePath, twoDevice, phrase);
}

for (const phrase of [
  '32-session per-shard saturation',
  'p50/p95/max',
  'cost/latency',
  'representative human/device/network acceptance',
]) {
  requirePhrase(migrationPath, migration, phrase);
}

for (const phrase of [
  'Cloudflare Worker Observability',
  'privacy model',
]) {
  requirePhrase(monitoringPath, monitoring, phrase);
}

for (const phrase of [
  'Alert Triggers',
  'Rollback trigger thresholds',
]) {
  requirePhrase(alertRunbookPath, alertRunbook, phrase);
}

for (const item of [
  '[ ] Run two-device internet play outside the developer network.',
  '[ ] Run load and capacity tests for the intended launch size.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  rehearsalPath,
  'node tool/audit_multiplayer_load_capacity.mjs',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
  requirePhrase(runbookPath, runbook, phrase);
}

for (const phrase of [
  'node tool/audit_multiplayer_load_capacity.mjs',
  'Verify multiplayer load capacity rehearsal',
]) {
  requirePhrase(workflowPath, workflow, phrase);
}

requirePhrase(releaseEvidenceAuditPath, releaseEvidenceAudit, rehearsalPath);

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Multiplayer load/capacity audit: launch-size plan, measurements, pass criteria and stop conditions verified.',
);
