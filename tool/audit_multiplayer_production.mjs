import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const checklistPath = 'docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const securityPath = 'docs/RELEASE_SECURITY_REVIEW.md';
const migrationPath = 'docs/MULTIPLAYER_SHARD_MIGRATION.md';
const readmePath = 'cloudflare/multiplayer/README.md';
const packagePath = 'cloudflare/multiplayer/package.json';
const authPath = 'cloudflare/multiplayer/src/auth.ts';
const workerPath = 'cloudflare/multiplayer/src/index.ts';
const workerTestPath = 'cloudflare/multiplayer/test/worker.test.ts';
const safetyTestPath = 'cloudflare/multiplayer/test/safety_authority.test.ts';
const migrationTestPath = 'cloudflare/multiplayer/test/migration.test.ts';

const checklist = readFileSync(resolve(root, checklistPath), 'utf8');
const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const security = readFileSync(resolve(root, securityPath), 'utf8');
const migration = readFileSync(resolve(root, migrationPath), 'utf8');
const readme = readFileSync(resolve(root, readmePath), 'utf8');
const packageJson = JSON.parse(readFileSync(resolve(root, packagePath), 'utf8'));
const auth = readFileSync(resolve(root, authPath), 'utf8');
const worker = readFileSync(resolve(root, workerPath), 'utf8');
const workerTest = readFileSync(resolve(root, workerTestPath), 'utf8');
const safetyTest = readFileSync(resolve(root, safetyTestPath), 'utf8');
const migrationTest = readFileSync(resolve(root, migrationTestPath), 'utf8');

const failures = [];

for (const phrase of [
  'release owner chooses the launch size',
  'family/privacy capability model is approved',
  'does not authorize public',
  'multiplayer by itself',
  'Selected launch size',
  'Two-Device Internet Play',
  'Capacity and Load',
  'selected launch environment',
]) {
  if (!checklist.includes(phrase)) {
    failures.push(`${checklistPath}: missing acceptance boundary "${phrase}"`);
  }
}

for (const phrase of [
  'nestarium-v1',
  'firebase-auth.<token>',
  'trusted-registry decisions fail',
  'Client-supplied identity headers are stripped',
  'Duplicate sessions for the same UID retire the older session',
  'Battle, trading and preset-message capabilities are enforced separately',
]) {
  if (!checklist.includes(phrase)) {
    failures.push(`${checklistPath}: missing trusted-session checklist item "${phrase}"`);
  }
}

for (const phrase of [
  'Direct battle invitation succeeds',
  'Random matchmaking succeeds or times out gracefully',
  'Battle reconnect window works',
  'Battle reward receipt is delivered once',
  'Direct trade invitation succeeds',
  'Trade cancel/disconnect preserves both rosters',
  'Completed trade moves both roster items exactly once',
  'Preset trade messages work; open text is unavailable',
  'Expected 503/Retry-After behavior at guardrail',
]) {
  if (!checklist.includes(phrase)) {
    failures.push(`${checklistPath}: missing two-device/load item "${phrase}"`);
  }
}

for (const item of [
  '[ ] Complete trusted authenticated sessions in the production environment.',
  '[ ] Run two-device internet play outside the developer network.',
  '[ ] Run load and capacity tests for the intended launch size.',
]) {
  if (!roadmap.includes(item)) {
    failures.push(`${roadmapPath}: multiplayer production gate is not open: ${item}`);
  }
}

for (const phrase of [
  'Firebase ID token carried as `firebase-auth.<token>`',
  'trusted_registry` fails closed',
  'X-Nestarium-Capabilities',
  'Player communication remains preset-only',
  'Complete trusted authenticated sessions in the production environment',
]) {
  if (!security.includes(phrase)) {
    failures.push(`${securityPath}: missing security review phrase "${phrase}"`);
  }
}

for (const phrase of [
  '32-session guardrail',
  '503',
  'Retry-After',
  'MATCHMAKING_SHARD_COUNT=1',
  'protected-v1',
  'approved sharding and data-',
  'migration plan',
]) {
  if (!readme.includes(phrase)) {
    failures.push(`${readmePath}: missing protected multiplayer boundary "${phrase}"`);
  }
}

for (const phrase of [
  '32-session per-shard saturation',
  'rollback',
  'receipt',
  'blocks',
]) {
  if (!migration.includes(phrase)) {
    failures.push(`${migrationPath}: missing sharding/migration phrase "${phrase}"`);
  }
}

for (const [script, command] of [
  ['typecheck', 'tsc --noEmit'],
  ['test', 'vitest run && node --test tool/operator_node_tests.mjs'],
  ['deploy:dry-run', 'wrangler deploy --dry-run'],
]) {
  if (packageJson.scripts?.[script] !== command) {
    failures.push(`${packagePath}: expected script "${script}" to be "${command}"`);
  }
}

for (const phrase of [
  'readFirebaseProtocol',
  'verifyFirebaseSession',
  'nestarium-v1',
  'firebase-auth.',
  'trusted_registry',
  'deniedCapabilities()',
  'profileDiscovery: false',
  'presetMessages: capabilities.presetMessages === true',
]) {
  if (!auth.includes(phrase)) {
    failures.push(`${authPath}: missing auth guard "${phrase}"`);
  }
}

for (const phrase of [
  'headers.delete("X-Nestarium-Uid")',
  'headers.delete("X-Nestarium-Capabilities")',
  'protectedPoolSessionLimit = 32',
  'Retry-After',
  'tradeComplete',
  'tradeCancelled',
  'ackTrade',
  'ackSettlement',
]) {
  if (!worker.includes(phrase)) {
    failures.push(`${workerPath}: missing Worker guard "${phrase}"`);
  }
}

for (const phrase of [
  'fails closed unless trusted capability claims use the current policy',
  'fails closed in registry mode',
  'enforces battle and trade permissions independently',
  'owns the online roster and rejects a forged battle team',
  'commits a two-sided Online Roster trade exactly once',
  'cancels a disconnected trade without moving either roster',
  'records preset reports and persists two-way matchmaking blocks',
  'retires a duplicate identity session',
  'pauses and resumes a server-run battle after a verified reconnect',
  'accepts and isolates 32 protected sessions',
]) {
  if (!workerTest.includes(phrase)) {
    failures.push(`${workerTestPath}: missing Worker test "${phrase}"`);
  }
}

for (const phrase of [
  'issues, expires, and revokes bounded capability decisions',
  'trade_concern',
  'capabilityDecisionForUid',
]) {
  if (!safetyTest.includes(phrase)) {
    failures.push(`${safetyTestPath}: missing safety authority test "${phrase}"`);
  }
}

for (const phrase of [
  'Retry-After',
  '503',
  'receipt_id',
  'roster_reward_json',
]) {
  if (!migrationTest.includes(phrase)) {
    failures.push(`${migrationTestPath}: missing migration test phrase "${phrase}"`);
  }
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log('Multiplayer production audit: trusted sessions, roster/trade authority, and capacity gates verified.');
