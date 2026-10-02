# Secondary reward systems economy audit

Audited: 2026-10-01

This review covers fusion, daily rewards, quests, hosted multiplayer rewards and
online roster drops. The candidate constants are protected by
`test/economy_audit_test.dart`, plus the hosted multiplayer tests in
`cloudflare/multiplayer/test/matchmaking_balance.test.ts` and
`cloudflare/multiplayer/test/worker.test.ts`.

## Current values

| System | Current reward behavior |
| --- | --- |
| Daily login rewards | 19,000 coins and 25 Battle Tokens across a complete 7-day cycle |
| Quest rewards | 2,800,400 coins and 180 Battle Tokens across all built-in quests |
| Hosted online battle win | 250 coins, 1-3 Battle Tokens, rating change and at most one daily roster animal |
| Hosted online battle loss | Rating loss only; no coins or Battle Tokens |
| Online roster drop | One server-owned animal per day, drawn by rating from Basic through Space-era animals only |
| Fusion | Two matching animals are consumed; success chance is 80%; lucky +2 mutation jump chance is 10% on success |

## Findings

### Resolved: Battle Tokens entered the economy too early

Daily rewards now grant 25 Battle Tokens per weekly cycle, while Boss Eggs cost
60 tokens. Daily battle-token quests were also reduced. Tokens still matter,
but the login track no longer buys a pile of Boss Eggs by itself.

### Resolved: One quest category could overwhelm early progression

Early battle quest coin rewards were reduced alongside the first boss reward.
The full built-in quest coin total is still meaningful, but the earliest battle
quests no longer skip most of Basic through Magic.

### Medium: Golden fusion is slightly positive expected value

Fusion is mostly conservative because failures consume inputs and secret,
elite, boss-mutated and protected animals cannot be fused. The exception is
Golden-to-Rainbow fusion: because the lucky jump can create Shadow, the expected
output is about 1.1x the two Golden inputs. That is not an immediate exploit
because it requires matching duplicate Golden animals, but it should be watched
when hatch rates or duplicated late-game animals are adjusted.

### Low: Hosted multiplayer rewards are conservative

Hosted online battle settlement is server-owned, replay-safe and does not depend
on client-supplied fighter power. A win grants only 250 coins, 1-3 Battle Tokens
and a bounded rating change. The daily online roster reward excludes boss,
DayGull and other secret animals, so online battle rewards are not currently an
obvious income or roster shortcut.

## Recommendation

Rebalance in this order:

1. Keep hosted online wins conservative until launch capacity and abuse testing
   are complete.
2. Leave fusion rules unchanged unless Golden duplicate farming becomes common
   after the main egg and Boss Egg rebalance.
3. Rerun fresh-save and two-device playtests to make sure tokens still feel
   rewarding after the reduction.

This closes the first reward-tuning pass. Further changes should come from
playtest evidence rather than isolated number tweaks.
