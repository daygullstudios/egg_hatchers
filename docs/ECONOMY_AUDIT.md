# Release economy audit

Audited: 2026-10-01

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
| Ancient | 1,500,000 | Rebirth 1 | 219,300 | 6.8s |
| Royal | 5,000,000 | Rebirth 2 | 404,600 | 12.4s |
| Celestial | 15,000,000 | Rebirth 3 | 719,100 | 20.9s |
| Void | 50,000,000 | Rebirth 5 | 1,096,500 | 45.6s |
| DayGull | 250,000,000 | Rotten Shell | 3,400,000 | 73.5s |

The Boss Egg costs 60 Battle Tokens and has an expected level-1 income of
331,500 coins per second.

## Rarity tables

Every egg has valid animal IDs, complete weights totaling 100, descending
outcome weights and a nondecreasing common-to-rare ordering. The level-1
mutation table is also internally consistent: 70% Normal, 20% Golden, 8%
Rainbow and 2% Shadow.

The tables are structurally sound. The main known value spikes from Boss Eggs,
rebirth eggs, DayGull and early battle rewards have been rebalanced.

## Findings

### Resolved: Boss Egg bypassed the first progression cycle

Boss Egg cost increased from 10 to 60 Battle Tokens, Boss Egg pet income now
sits below the Void Egg peak, and login/quest token rewards were reduced. Boss
Eggs are still a useful battle reward, but no longer skip the first rebirth
cycle by themselves.

### Resolved: Rebirth eggs were dominated by Space Egg

Ancient, Royal, Celestial and Void animals now climb above Space instead of
feeling like regressions after rebirth.

### High: The pre-rebirth curve accelerates too sharply

Expected payback falls from 39 seconds for Basic to three seconds for Space.
That compression matches the measured 2-to-5.5-minute first rebirth and leaves
little time for upgrades, collection decisions or bosses to matter.

### Resolved during the boss-balance step: exponential rebirth scaling

At the start of this audit, income doubled every rebirth while requirements
grew quadratically. Rebirth income now adds one multiplier step per level:
1x with no rebirth, 2x at level 1, 3x at level 2, and so on. Requirements remain
`1,000,000 * (level + 1)^2`, so the multiplier no longer outgrows them
exponentially.

### Resolved: Opening battle rewards overwhelmed egg prices

The first Slime Boss win now grants 500 coins. First Fight and First Victory
now add 1,000 coins total, keeping battles helpful without letting one early
boss session skip most of the opening egg ladder.

## Rebalance order

1. Rerun the seeded new-player cohort after this rebalance.
2. Playtest a real fresh save through first rebirth and first Boss Egg.
3. Tune individual payback times only if the updated path feels too slow or too
   compressed.
4. Keep watching Golden fusion and hosted multiplayer rewards after the broader
   economy changes.
