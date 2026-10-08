import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const monitoringPath = 'docs/RELEASE_MONITORING_EVIDENCE.md';
const operationsPath = 'docs/RELEASE_OPERATIONS_EVIDENCE.md';
const alertRunbookPath = 'docs/MONITORING_ALERT_RUNBOOK_TEMPLATE.md';
const decisionPacketPath = 'docs/RELEASE_DECISION_PACKET.md';
const pubspecPath = 'pubspec.yaml';
const playtestWranglerPath = 'cloudflare/playtest/wrangler.jsonc';
const multiplayerWranglerPath = 'cloudflare/multiplayer/wrangler.jsonc';
const multiplayerCanaryWranglerPath = 'cloudflare/multiplayer/wrangler.canary.jsonc';

const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const monitoring = readFileSync(resolve(root, monitoringPath), 'utf8');
const operations = readFileSync(resolve(root, operationsPath), 'utf8');
const alertRunbook = readFileSync(resolve(root, alertRunbookPath), 'utf8');
const decisionPacket = readFileSync(resolve(root, decisionPacketPath), 'utf8');
const pubspec = readFileSync(resolve(root, pubspecPath), 'utf8').toLowerCase();

const failures = [];

function readJsonConfig(relativePath) {
  return JSON.parse(readFileSync(resolve(root, relativePath), 'utf8'));
}

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

function requireObservability(path, config, options = {}) {
  if (config.observability?.enabled !== true) {
    failures.push(`${path}: Worker Observability must be enabled`);
  }
  if (config.workers_dev !== false) {
    failures.push(`${path}: workers_dev must stay disabled for release surfaces`);
  }
  if (config.preview_urls !== false) {
    failures.push(`${path}: preview_urls must stay disabled for release surfaces`);
  }
  if (options.requireInvocationLogs) {
    if (config.observability?.logs?.enabled !== true) {
      failures.push(`${path}: observability logs must be enabled`);
    }
    if (config.observability?.logs?.invocation_logs !== true) {
      failures.push(`${path}: invocation logs must be enabled`);
    }
    if (config.observability?.logs?.head_sampling_rate !== 1) {
      failures.push(`${path}: head_sampling_rate must remain 1 for protected test evidence`);
    }
  }
}

requireObservability(playtestWranglerPath, readJsonConfig(playtestWranglerPath));
requireObservability(multiplayerWranglerPath, readJsonConfig(multiplayerWranglerPath), {
  requireInvocationLogs: true,
});
requireObservability(multiplayerCanaryWranglerPath, readJsonConfig(multiplayerCanaryWranglerPath), {
  requireInvocationLogs: true,
});

for (const dependency of [
  'firebase_crashlytics',
  'firebase_analytics',
  'sentry_flutter',
  'appcenter',
  'mixpanel',
  'amplitude_flutter',
]) {
  if (pubspec.includes(dependency)) {
    failures.push(`${pubspecPath}: disallowed client telemetry dependency "${dependency}"`);
  }
}

for (const phrase of [
  'Flutter client has no production crash',
  'Monitoring must support operations without turning into player tracking',
  'Do not',
  'intentionally log player profile payloads',
  'A test proving public production errors are visible without exposing player',
]) {
  requirePhrase(monitoringPath, monitoring, phrase);
}

for (const phrase of [
  'Cloudflare Worker Observability',
  'Alert destinations',
  'backup cadence',
  'restore rehearsal',
  'Retention and support-access rules',
  'Do not mark the roadmap operations item complete',
]) {
  requirePhrase(operationsPath, operations, phrase);
}

for (const phrase of [
  'Allowed operational fields',
  'Do not intentionally log player profile payloads',
  'Alert Triggers',
  'privacy-safe error visibility test',
  'Monitoring owner',
  'Rollback decision maker',
]) {
  requirePhrase(alertRunbookPath, alertRunbook, phrase);
}

for (const phrase of [
  'Monitoring, backups and alerts',
  'Allowed operational fields',
  'Alert destinations',
  'Backup cadence',
  'Restore rehearsal owner and schedule',
]) {
  requirePhrase(decisionPacketPath, decisionPacket, phrase);
}

for (const item of [
  '[ ] Add production error monitoring that matches the approved privacy model.',
  '[ ] Confirm backups, restore procedures, rate limits and operational alerts.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Monitoring operations audit: Worker observability, telemetry boundary and open owner gates verified.',
);
