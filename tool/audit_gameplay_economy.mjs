import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const roadmapPath = 'docs/RELEASE_ROADMAP.md';
const evidenceIndexPath = 'docs/RELEASE_EVIDENCE_INDEX.md';
const newPlayerPath = 'docs/NEW_PLAYER_PATH_BASELINE.md';
const economyPath = 'docs/ECONOMY_AUDIT.md';
const bossPath = 'docs/BOSS_BALANCE_AUDIT.md';
const daygullPath = 'docs/DAYGULL_ENDGAME_ECONOMY_AUDIT.md';
const rewardsPath = 'docs/REWARD_SYSTEMS_ECONOMY_AUDIT.md';
const saveStagePath = 'docs/SAVE_STAGE_PLAYABILITY_EVIDENCE.md';
const economyTestPath = 'test/economy_audit_test.dart';
const bossTestPath = 'test/boss_balance_audit_test.dart';
const newPlayerTestPath = 'test/new_player_progression_baseline_test.dart';
const multiplayerBalanceTestPath = 'cloudflare/multiplayer/test/matchmaking_balance.test.ts';
const workerTestPath = 'cloudflare/multiplayer/test/worker.test.ts';

const roadmap = readFileSync(resolve(root, roadmapPath), 'utf8');
const evidenceIndex = readFileSync(resolve(root, evidenceIndexPath), 'utf8');
const newPlayer = readFileSync(resolve(root, newPlayerPath), 'utf8');
const economy = readFileSync(resolve(root, economyPath), 'utf8');
const boss = readFileSync(resolve(root, bossPath), 'utf8');
const daygull = readFileSync(resolve(root, daygullPath), 'utf8');
const rewards = readFileSync(resolve(root, rewardsPath), 'utf8');
const saveStage = readFileSync(resolve(root, saveStagePath), 'utf8');
const economyTest = readFileSync(resolve(root, economyTestPath), 'utf8');
const bossTest = readFileSync(resolve(root, bossTestPath), 'utf8');
const newPlayerTest = readFileSync(resolve(root, newPlayerTestPath), 'utf8');
const multiplayerBalanceTest = readFileSync(resolve(root, multiplayerBalanceTestPath), 'utf8');
const workerTest = readFileSync(resolve(root, workerTestPath), 'utf8');

const failures = [];

function requirePhrase(path, text, phrase) {
  if (!text.includes(phrase)) {
    failures.push(`${path}: missing phrase "${phrase}"`);
  }
}

for (const phrase of [
  'First hatch',
  'First boss',
  'First rebirth',
  'Economy only',
  'First boss at 1 minute',
  'All 100 seeds reached the first rebirth without a progression dead zone.',
  'test/new_player_progression_baseline_test.dart',
]) {
  requirePhrase(newPlayerPath, newPlayer, phrase);
}

for (const phrase of [
  'release baseline keeps the opening milestones connected',
  '100 seeded fresh players reach first rebirth without a dead zone',
  'economyTimes.first, 120',
  'economyTimes[49], 217',
  'economyTimes.last, 330',
  'activeTimes.first, 116',
  'activeTimes[49], 158',
  'activeTimes.last, 203',
]) {
  requirePhrase(newPlayerTestPath, newPlayerTest, phrase);
}

for (const phrase of [
  'At level 1, the mutation-weighted income multiplier is 1.70x.',
  'Basic',
  'Void',
  'DayGull',
  'Boss Egg',
  'Rebirth income now adds one multiplier step per level',
  'Opening battle rewards overwhelmed egg prices',
]) {
  requirePhrase(economyPath, economy, phrase);
}

for (const phrase of [
  'egg tables are complete weighted rarity ladders',
  'release economy audit remains tied to candidate values',
  'expectedIncome(GameData.eggById',
  'DayGull endgame income remains strong without skipping the endgame',
  'secondary reward systems remain tied to reviewed values',
  'goldenFusionExpectedOutput',
]) {
  requirePhrase(economyTestPath, economyTest, phrase);
}

for (const phrase of [
  'Manual battle ladder',
  'Slime Boss',
  'The Rotten Shell',
  'Every animal resolves to three abilities costing 2, 4 and 7 energy.',
  'energy centers within the middle 35%-65%',
  'collected energy immediately respawns',
  'recommended power is not a difficulty gate',
]) {
  requirePhrase(bossPath, boss, phrase);
}

for (const phrase of [
  'boss ladder remains tied to the reviewed candidate values',
  'manual difficulty tiers and shields increase predictably',
  'every animal has a complete affordable ability ladder',
  'Rotten Shell final battle timing and energy area are bounded',
  'energyCenterMin, 0.35',
  'energyCenterSpan, 0.30',
]) {
  requirePhrase(bossTestPath, bossTest, phrase);
}

for (const phrase of [
  'Crossword Beast',
  'Boba Bazooka',
  'The Ultimate Nest',
  'DayGull expected income is **3,400,000 coins/sec**',
  '3.1x Void',
  '5.5x the previous highest regular hatchable',
  'bosses, quests, fusions and multiplayer rewards should not be priced',
]) {
  requirePhrase(daygullPath, daygull, phrase);
}

for (const phrase of [
  'Daily login rewards',
  'Quest rewards',
  'Hosted online battle win',
  'Hosted online battle loss',
  'Online roster drop',
  'Fusion',
  'Golden fusion is slightly positive expected value',
  'Hosted multiplayer rewards are conservative',
]) {
  requirePhrase(rewardsPath, rewards, phrase);
}

for (const phrase of [
  'DailySystemLogic.rewardForDaySlot',
  '19000',
  '25',
  '2800400',
  '180',
  'closeTo(1.1, 0.001)',
]) {
  requirePhrase(economyTestPath, economyTest, phrase);
}

for (const phrase of [
  'Fresh',
  'Midgame',
  'Late-game',
  '`fullDeveloperToolsUnlocked` is false',
  'Rotten Shell prerequisite path is',
  'Fresh, midgame and late-game representative saves remain connected',
]) {
  requirePhrase(saveStagePath, saveStage, phrase);
}

for (const phrase of [
  'fresh midgame and late-game saves work without developer boosts',
  'state.fullDeveloperToolsUnlocked',
  '_freshFixture',
  '_midgameFixture',
  '_lateGameFixture',
  'EggShardLogic.isRottenShellUnlocked',
]) {
  requirePhrase(newPlayerTestPath, newPlayerTest, phrase);
}

for (const phrase of [
  'matchmaking fairness',
  'rating',
]) {
  requirePhrase(multiplayerBalanceTestPath, multiplayerBalanceTest, phrase);
}

for (const phrase of [
  'settles a hosted result once',
  'rosterReward',
  'ackSettlement',
]) {
  requirePhrase(workerTestPath, workerTest, phrase);
}

for (const item of [
  '[x] Restrict purchases and hatches to canonical built-in eggs.',
  '[x] Measure the new-player path through first hatch, first boss and first',
  '[x] Review every egg price, rarity table, income curve and rebirth multiplier.',
  '[x] Review boss difficulty, lives, abilities, energy frequency and rewards.',
  '[x] Review DayGull progression and endgame income for economy-breaking jumps.',
  '[x] Review fusion, daily rewards, quests, multiplayer rewards and roster drops.',
  '[x] Test fresh, midgame and late-game saves without developer boosts.',
  '[x] Fix every progression blocker and practical farming exploit.',
]) {
  requirePhrase(roadmapPath, roadmap, item);
}

for (const phrase of [
  'docs/NEW_PLAYER_PATH_BASELINE.md',
  'docs/ECONOMY_AUDIT.md',
  'docs/BOSS_BALANCE_AUDIT.md',
  'docs/DAYGULL_ENDGAME_ECONOMY_AUDIT.md',
  'docs/REWARD_SYSTEMS_ECONOMY_AUDIT.md',
  'docs/SAVE_STAGE_PLAYABILITY_EVIDENCE.md',
]) {
  requirePhrase(evidenceIndexPath, evidenceIndex, phrase);
}

if (failures.length > 0) {
  throw new Error(failures.join('\n'));
}

console.log(
  'Gameplay economy audit: new-player path, economy tables, boss balance, DayGull, rewards and save stages verified.',
);
