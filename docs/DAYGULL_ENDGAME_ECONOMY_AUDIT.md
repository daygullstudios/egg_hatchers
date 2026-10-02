# DayGull and endgame economy audit

Audited: 2026-10-01

This review covers the post-Rotten Shell DayGull tier and the surrounding
endgame income curve. The numeric checks are protected by
`test/economy_audit_test.dart`.

## Current DayGull values

Expected income uses the level-1 mutation table from the release economy audit:
70% Normal, 20% Golden, 8% Rainbow and 2% Shadow, for a 1.70x expected mutation
multiplier. Rebirth, mastery, upgrades and levels are excluded here so the
numbers can be compared directly to egg base tables.

| Animal | Weight | Base income/sec | Expected contribution/sec |
| --- | ---: | ---: | ---: |
| Crossword Beast | 60% | 6,500,000 | 6,630,000 |
| Boba Bazooka | 35% | 4,200,000 | 2,499,000 |
| The Ultimate Nest | 5% | 12,000,000 | 1,020,000 |

DayGull expected income is **10,149,000 coins/sec** before rebirth and level
growth. At its 250,000,000 coin price, that is a 24.6 second base payback.

## Comparison to prior endgame

| Tier | Expected income/sec | Ratio vs prior |
| --- | ---: | ---: |
| Void Egg | 480,250 | - |
| DayGull Egg | 10,149,000 | 21.1x Void |

The rarest DayGull animal, The Ultimate Nest, has 12,000,000 base income/sec.
That is 26.7x the previous highest regular hatchable base income, Nebula Hydra
at 450,000 income/sec. With the Shadow mutation alone, The Ultimate Nest reaches
120,000,000 base income/sec before rebirth, mastery, upgrades or levels.

## Findings

### High: DayGull is a very large post-final-boss income jump

DayGull is intentionally a secret reward after The Rotten Shell, but the current
gap is large enough to make the previous endgame obsolete almost immediately.
Once the player can afford one or two DayGull hatches, ordinary Void, rebirth
egg, boss reward and quest income becomes mostly decorative.

### Medium: The egg price does not offset the income jump for long

The 250,000,000 coin price looks high compared with earlier eggs, but the
expected base payback is only 24.6 seconds before rebirth multipliers. At
Rebirth 5, the linear rebirth multiplier makes expected DayGull income about
60,894,000 coins/sec and the same egg pays back in about 4.1 seconds.

### Medium: The Ultimate Nest can dominate future balance

The Ultimate Nest is only a 5% roll, which helps rarity feel special. The issue
is that one good roll can become the single best income source by a very wide
margin. Future bosses, quests, fusions and multiplayer rewards will be hard to
price if they must compete with that one animal.

## Recommendation

Keep DayGull as the exciting post-Rotten Shell secret, but rebalance it as a
controlled endgame extension rather than a complete reset of the economy. A
reasonable next target is:

- DayGull expected income around 3x to 6x Void, not 21x.
- The Ultimate Nest around 5x to 10x the best previous hatchable, not 26.7x.
- DayGull payback around 60 to 120 seconds at the intended unlock point.
- Boss, fusion, quest and multiplayer rewards reviewed after DayGull is set, so
  they do not need inflated rewards to remain relevant.

No values were changed during this audit. This closes the review step while
leaving the actual rebalance for the broader progression-fix step.
