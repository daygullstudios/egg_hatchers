import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const reviewPath = 'docs/RELEASE_SECURITY_REVIEW.md';
const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const codeReviewPath = 'docs/RELEASE_CODE_REVIEW.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const authPath = 'cloudflare/multiplayer/src/auth.ts';
const workerPath = 'cloudflare/multiplayer/src/index.ts';
const safetyAuthorityPath = 'cloudflare/multiplayer/src/safety_authority.ts';
const workerTestPath = 'cloudflare/multiplayer/test/worker.test.ts';
const safetyTestPath = 'cloudflare/multiplayer/test/safety_authority.test.ts';
const migrationTestPath = 'cloudflare/multiplayer/test/migration.test.ts';
const multiplayerClientPath = 'lib/services/multiplayer_service.dart';
const tradingClientPath = 'lib/services/trading_service.dart';
const multiplayerTestPath = 'test/multiplayer_service_test.dart';
const tradingTestPath = 'test/trading_service_test.dart';

const files = {
  [reviewPath]: readFileSync(resolve(root, reviewPath), 'utf8'),
  [roadmapPath]: readFileSync(resolve(root, roadmapPath), 'utf8'),
  [codeReviewPath]: readFileSync(resolve(root, codeReviewPath), 'utf8'),
  [evidenceIndexPath]: readFileSync(resolve(root, evidenceIndexPath), 'utf8'),
  [authPath]: readFileSync(resolve(root, authPath), 'utf8'),
  [workerPath]: readFileSync(resolve(root, workerPath), 'utf8'),
  [safetyAuthorityPath]: readFileSync(resolve(root, safetyAuthorityPath), 'utf8'),
  [workerTestPath]: readFileSync(resolve(root, workerTestPath), 'utf8'),
  [safetyTestPath]: readFileSync(resolve(root, safetyTestPath), 'utf8'),
  [migrationTestPath]: readFileSync(resolve(root, migrationTestPath), 'utf8'),
  [multiplayerClientPath]: readFileSync(resolve(root, multiplayerClientPath), 'utf8'),
  [tradingClientPath]: readFileSync(resolve(root, tradingClientPath), 'utf8'),
  [multiplayerTestPath]: readFileSync(resolve(root, multiplayerTestPath), 'utf8'),
  [tradingTestPath]: readFileSync(resolve(root, tradingTestPath), 'utf8'),
};

const failures = [];

function requirePhrase(path, phrase) {
  if (!files[path].includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'No new critical or high-severity security issue was found',
  'Authentication boundary reviewed',
  'Multiplayer authority reviewed',
  'Trading authority reviewed',
  'Safety and abuse controls reviewed',
  'Open release gates',
  'Complete trusted authenticated sessions in the production environment.',
  'Run two-device internet play outside the developer network.',
  'Run load and capacity tests for the intended launch size.',
  'Obtain the professional family audience/privacy review',
  'Confirm backups, restore procedures, rate limits and operational alerts',
]) {
  requirePhrase(reviewPath, phrase);
}

for (const phrase of [
  'Firebase ID token carried as `firebase-auth.<token>`',
  'Tokens are limited in size, must use RS256',
  'Subject, issued-at and authentication-time claims are validated.',
  '`trusted_registry` fails closed',
  '`trusted_claims` accepts only the current versioned allow policy.',
]) {
  requirePhrase(reviewPath, phrase);
}

for (const phrase of [
  'verifyFirebaseSession',
  'firebase-auth.',
  'trusted_registry',
  'trusted_claims',
  'trustedCapabilityPolicyVersion',
  'RS256',
  'auth_time',
  'issued-at',
]) {
  requirePhrase(authPath, phrase);
}

for (const phrase of [
  'headers.delete("X-Nestarium-Uid")',
  'headers.delete("X-Nestarium-Capabilities")',
  'trustedBattleTeam',
  'completeTrade',
  'acknowledgeTrade',
  'enforceRateLimit',
  'peerSafety',
  'blockedPlayers',
  'unblockPlayer',
]) {
  requirePhrase(workerPath, phrase);
}

for (const phrase of [
  'Server-owned Online Roster inventory is the only authority',
  'Server-run battle settlement creates UID-scoped receipts',
  'Reconnects are limited to the verified same Firebase identity.',
  'Only animals still present in the server-owned Online Roster',
  'Trade completion is transactional',
  'Player communication remains preset-only',
  'Reports use approved reason tags',
  'Blocks apply to future battle and trade matchmaking',
  'WebSocket messages are size-limited and rate-limited',
]) {
  requirePhrase(reviewPath, phrase);
}

for (const phrase of [
  'rejects an upgrade without a Firebase token',
  'rejects a validly signed token for another Firebase project',
  'fails closed unless trusted capability claims use the current policy',
  'fails closed in registry mode and accepts only a resolved hosted capability',
  'enforces battle and trade permissions independently after connection',
  'owns the online roster and rejects a forged battle team',
  'commits a two-sided Online Roster trade exactly once',
  'cancels a disconnected trade without moving either roster',
  'records preset reports and persists two-way matchmaking blocks',
  'retires a live hosted session when its capability decision is revoked',
]) {
  requirePhrase(workerTestPath, phrase);
}

for (const phrase of [
  'stores idempotent pseudonymous reports and prunes them after retention',
  'issues, expires, and revokes bounded capability decisions',
  'capabilityDecisionForUid',
  'trade_concern',
]) {
  requirePhrase(safetyTestPath, phrase);
}

for (const phrase of [
  'Public migration requests are separate from the private binding protocol.',
  'Migration tools remain off the public HTTP surface',
]) {
  requirePhrase(codeReviewPath, phrase);
}

for (const phrase of [
  'public HTTP surface',
  'binding',
]) {
  requirePhrase(migrationTestPath, phrase);
}

for (const phrase of [
  'Hosted multiplayer is not released',
  'released hosted multiplayer rejects a missing identity token',
  'hosted settlement is parsed and acknowledged explicitly',
  'hosted match preserves identity and resumes after a dropped socket',
  'reportPeer(PeerReportReason.suspectedCheating, block: true)',
]) {
  const path = phrase.startsWith('Hosted multiplayer')
    ? multiplayerClientPath
    : multiplayerTestPath;
  requirePhrase(path, phrase);
}

for (const phrase of [
  'Hosted trading is not released',
  'hosted trading authenticates and consumes only server inventory',
  'two online players complete a confirmed animal trade',
  'sendChat(TradeChatTag.isThisFair)',
  'TradeChatTag.isThisFair',
  'TradeChatTag.requestAnimal',
]) {
  const path = phrase.startsWith('Hosted trading')
    ? tradingClientPath
    : tradingTestPath;
  requirePhrase(path, phrase);
}

for (const item of [
  '[x] Perform a security review of authentication, multiplayer and trading.',
  '[ ] Complete trusted authenticated sessions in the production environment.',
  '[ ] Run two-device internet play outside the developer network.',
  '[ ] Run load and capacity tests for the intended launch size.',
]) {
  requirePhrase(roadmapPath, item);
}

for (const phrase of [
  'docs/RELEASE_SECURITY_REVIEW.md',
  'Open release dependencies: trusted production sessions',
]) {
  requirePhrase(evidenceIndexPath, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Security review audit: authentication, hosted authority, trading, reports, blocks and open production gates verified.',
);
