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
| Daily login rewards | 19,000 coins and 80 Battle Tokens across a complete 7-day cycle |
| Quest rewards | 3,048,400 coins and 240 Battle Tokens across all built-in quests |
| Hosted online battle win | 250 coins, 1-3 Battle Tokens, rating change and at most one daily roster animal |
| Hosted online battle loss | Rating loss only; no coins or Battle Tokens |
| Online roster drop | One server-owned animal per day, drawn by rating from Basic through Space-era animals only |
| Fusion | Two matching animals are consumed; success chance is 80%; lucky +2 mutation jump chance is 10% on success |

## Findings

### High: Battle Tokens enter the economy too early

Daily rewards alone grant 80 Battle Tokens per weekly cycle. Because a Boss Egg
costs 10 Battle Tokens, the weekly login track can buy eight Boss Eggs. Daily
quests can also grant Battle Tokens before the normal coin ladder reaches its
first rebirth. This reinforces the existing Boss Egg finding from
`docs/ECONOMY_AUDIT.md`: Boss Egg income is far above the first progression
cycle, so early Battle Token rewards can become an economy shortcut.

### Medium: One quest category can overwhelm early progression

All built-in quests currently sum to 3,048,400 coins. That total is not a
problem by itself because late quests should matter, but some early battle and
sprite rewards are large relative to Basic through Magic egg prices. This
matches the new-player baseline finding that first battle rewards can skip much
of the early egg ladder.

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

1. Set Boss Egg and Battle Token targets together. Do not tune daily rewards
   until Boss Egg income is in the intended range.
2. Keep hosted online wins conservative until launch capacity and abuse testing
   are complete.
3. Reduce early coin quest spikes only after the first-session target time is
   chosen.
4. Leave fusion rules unchanged unless Golden duplicate farming becomes common
   after the main egg and Boss Egg rebalance.

No values were changed during this audit. This closes the review step while
leaving actual reward tuning for the progression-fix step.
