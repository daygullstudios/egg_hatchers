# New-player path baseline

Measured: 2026-09-24

This report measures the release-candidate path from a fresh local player to
the first hatch, first normal boss and first rebirth. The repeatable cohort is
implemented in `test/new_player_progression_baseline_test.dart`.

## Candidate milestones

| Milestone | Current result |
| --- | --- |
| First hatch | Available immediately. A Basic Egg costs 100 of the starting 250 coins. |
| First boss | Available immediately after the first hatch. Slime Boss has one life in a normal manual battle. |
| First rebirth | Requires 1,000,000 lifetime coins earned from animal income. |

The existing phone-width journey test separately proves that a fresh player
can complete the tutorial, buy and reveal the first egg, earn idle income,
upgrade the animal, save and reopen at 320x568 and 390x844.

## Cohort method

The economy cohort runs 100 fixed random seeds against the candidate's actual
egg prices, animal weights, mutation weights, income values, lifetime unlocks
and hatch-quest rewards. Each simulated player:

1. buys a Basic Egg immediately;
2. claims completed hatch-count quest rewards;
3. buys the highest unlocked pre-rebirth egg whenever affordable; and
4. stops on reaching the first rebirth requirement.

The economy-only cohort excludes daily rewards, upgrades, luck purchases,
selling, fusion, offline income and boss rewards. The active-play cohort adds
one successful Slime Boss battle at 60 seconds and immediately claims First
Fight and First Victory. The one-minute completion is a measurement assumption,
not a guarantee of player skill.

## Results

| Cohort | Fastest | Median | Slowest |
| --- | ---: | ---: | ---: |
| Economy only | 2m 00s | 3m 37s | 5m 30s |
| First boss at 1 minute | 1m 39s | 2m 32s | 3m 07s |

All 100 seeds reached the first rebirth without a progression dead zone.

## Release finding

The path is connected and understandable, but the first rebirth is extremely
fast for an idle progression game. The Slime Boss's 2,500-coin reward plus
6,000 coins from its first two battle quests overwhelms the opening egg prices
and shortens an already brief first cycle.

Do not tune a single reward in isolation. Resolve this finding during the full
egg-price, rarity, income and rebirth review, then regenerate this baseline.
