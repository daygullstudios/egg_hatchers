# Release economy audit

Audited: 2026-09-24

This audit covers every built-in egg price, rarity table, base income curve and
rebirth multiplier in the release candidate. Calculations are protected by
`test/economy_audit_test.dart`.

## Method

Expected income uses each egg's animal weights and the level-1 mutation table.
At level 1, the mutation-weighted income multiplier is 1.70x. Payback is egg
coin cost divided by expected level-1 income and excludes mastery, upgrades,
quests and rebirth multipliers.

| Egg | Cost | Unlock | Expected income/sec | Payback |
| --- | ---: | --- | ---: | ---: |
| Basic | 100 | Start | 2.55 | 39.2s |
| Forest | 400 | 300 lifetime | 17.85 | 22.4s |
| Farm | 800 | 750 lifetime | 34.68 | 23.1s |
| Magic | 1,500 | 2,500 lifetime | 132.60 | 11.3s |
| Jungle | 3,500 | 5,000 lifetime | 178.50 | 19.6s |
| Ocean | 12,000 | 20,000 lifetime | 713.15 | 16.8s |
| Arctic | 40,000 | 75,000 lifetime | 3,740 | 10.7s |
| Dino | 125,000 | 200,000 lifetime | 18,530 | 6.7s |
| Space | 500,000 | 750,000 lifetime | 157,250 | 3.2s |
| Ancient | 1,500,000 | Rebirth 1 | 15,172.50 | 98.9s |
| Royal | 5,000,000 | Rebirth 2 | 48,025 | 104.1s |
| Celestial | 15,000,000 | Rebirth 3 | 151,725 | 98.9s |
| Void | 50,000,000 | Rebirth 5 | 480,250 | 104.1s |
| DayGull | 250,000,000 | Rotten Shell | 10,149,000 | 24.6s |

The Boss Egg costs 10 Battle Tokens and has an expected level-1 income of
1,249,500 coins per second.

## Rarity tables

Every egg has valid animal IDs, complete weights totaling 100, descending
outcome weights and a nondecreasing common-to-rare ordering. The level-1
mutation table is also internally consistent: 70% Normal, 20% Golden, 8%
Rainbow and 2% Shadow.

The tables are structurally sound. The release risks come from the values
around those tables.

## Findings

### Critical: Boss Egg bypasses the first progression cycle

A Boss Egg unlocks after owning any animal. Its expected income in one second
is greater than the entire 1,000,000 lifetime-coin requirement for the first
rebirth. Daily quests can award enough Battle Tokens to buy it before normal
egg progression reaches the threshold.

### High: Rebirth eggs are dominated by Space Egg

Ancient, Royal and Celestial Eggs have lower expected income than the
pre-rebirth Space Egg. Ancient costs three times as much while producing about
one tenth as much. These unlocks feel like regressions instead of rewards.

### High: The pre-rebirth curve accelerates too sharply

Expected payback falls from 39 seconds for Basic to three seconds for Space.
That compression matches the measured 2-to-5.5-minute first rebirth and leaves
little time for upgrades, collection decisions or bosses to matter.

### High: Rebirth scaling shortens later cycles

Income doubles every rebirth while requirements grow quadratically as
`1,000,000 * (level + 1)^2`. Exponential income eventually outpaces the
requirement curve, and stronger rebirth eggs amplify the effect.

### Medium: Opening battle rewards overwhelm egg prices

The first Slime Boss win grants 2,500 coins. Claiming First Fight and First
Victory adds another 6,000 coins. The combined 8,500 coins can skip most of the
opening egg ladder.

## Rebalance order

1. Choose target times for the first and later rebirth cycles.
2. Bring Boss Egg animals into a safe early/midgame range or gate them later.
3. Restore a consistent payback range across the coin egg ladder.
4. Make every rebirth egg a meaningful improvement over the previous tier.
5. Align boss and quest rewards with the stage where players can earn them.
6. Reconcile exponential rebirth income with the requirement curve.
7. Rerun the seeded new-player cohort and test existing mid/late saves.

No values were changed during this audit. That keeps the baseline honest and
lets the rebalance land as one reviewed system instead of isolated patches.
