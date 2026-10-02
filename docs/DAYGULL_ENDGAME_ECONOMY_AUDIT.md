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
| Crossword Beast | 60% | 2,000,000 | 2,040,000 |
| Boba Bazooka | 35% | 1,500,000 | 892,500 |
| The Ultimate Nest | 5% | 5,500,000 | 467,500 |

DayGull expected income is **3,400,000 coins/sec** before rebirth and level
growth. At its 250,000,000 coin price, that is a 73.5 second base payback.

## Comparison to prior endgame

| Tier | Expected income/sec | Ratio vs prior |
| --- | ---: | ---: |
| Void Egg | 1,096,500 | - |
| DayGull Egg | 3,400,000 | 3.1x Void |

The rarest DayGull animal, The Ultimate Nest, has 5,500,000 base income/sec.
That is 5.5x the previous highest regular hatchable base income, Nebula Hydra
at 1,000,000 income/sec. With the Shadow mutation alone, The Ultimate Nest
reaches 55,000,000 base income/sec before rebirth, mastery, upgrades or levels.

## Findings

### Resolved: DayGull was a very large post-final-boss income jump

DayGull remains a secret reward after The Rotten Shell, but it now extends the
endgame instead of making ordinary Void, rebirth egg, boss reward and quest
income mostly decorative.

### Resolved: The egg price did not offset the income jump for long

The expected base payback is now 73.5 seconds before rebirth multipliers,
which is inside the target range for a post-final-boss secret tier.

### Reduced risk: The Ultimate Nest can dominate future balance

The Ultimate Nest is only a 5% roll, which helps rarity feel special. The issue
is that one good roll can still become the single best income source. Future
bosses, quests, fusions and multiplayer rewards should not be priced directly
against the rarest DayGull result.

## Recommendation

Keep DayGull as the exciting post-Rotten Shell secret and tune from playtest
feel rather than increasing the tier again. The current target is:

- DayGull expected income around 3x to 6x Void.
- The Ultimate Nest around 5x to 10x the best previous hatchable.
- DayGull payback around 60 to 120 seconds at the intended unlock point.
- Boss, fusion, quest and multiplayer rewards reviewed after DayGull is set, so
  they do not need inflated rewards to remain relevant.
