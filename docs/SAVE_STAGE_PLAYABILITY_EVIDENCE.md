# Save-stage playability evidence

Audited: 2026-10-01

This evidence covers the roadmap item for fresh, midgame and late-game saves
without developer boosts. The automated coverage lives in
`test/new_player_progression_baseline_test.dart`.

## What is tested

The test uses three representative saved progress fixtures:

- Fresh: first Basic Egg animal, ordinary starting coins and no rebirth.
- Midgame: Space Egg reached through lifetime income, ordinary animals and a
  normal Slime Boss history.
- Late-game: Rebirth 5, Void/DayGull-era animals, prerequisite boss wins,
  Rotten Shell access and one Rotten Shell win.

For every fixture, the test verifies:

- `fullDeveloperToolsUnlocked` is false.
- the save has real animal income.
- the expected egg tier is unlocked by normal lifetime/rebirth rules.
- the expected boss is unlocked by normal boss gates.
- the rebirth-ready state matches the fixture.

The late-game fixture also verifies the Rotten Shell prerequisite path is
complete and that the save records a normal Rotten Shell win.

## Result

Fresh, midgame and late-game representative saves remain connected without
developer boosts. This does not mean the economy is balanced; the DayGull and
reward audits still recommend a broader progression rebalance.
