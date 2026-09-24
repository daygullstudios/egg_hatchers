# Boss balance audit

Audited: 2026-09-24

This review covers normal, elite and Rotten Shell boss difficulty, lives,
abilities, energy cadence and rewards. Candidate values are protected by
`test/boss_balance_audit_test.dart`.

## Manual battle ladder

| Boss | Lives | Base shot interval | Shot speed | Move speed | Coins | Tokens |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Slime Boss | 1 | 1,200ms | 120 | 45 | 2,500 | 1 |
| Egg Golem | 2 | 950ms | 180 | 70 | 25,000 | 3 |
| Shadow Rooster | 3 | 750ms | 260 | 95 | 250,000 | 8 |
| Slime King | 3 | 700ms | 280 | 88 | 500,000 | 10 |
| Egg Guardian | 4 | 620ms | 310 | 102 | 750,000 | 12 |
| Shadow Phoenix | 5 | 550ms | 340 | 115 | 1,000,000 | 15 |
| The Rotten Shell | 7 | 480ms | 360 | 122 | 2,000,000 | 20 |

Normal bosses require 5, then 6, then 7 dodges to break successive shields.
Hard starts at 8 and Nightmare at 10. Elite bosses start from their configured
9-to-13 dodge thresholds and add two after each successful hit. Normal, Hard
and Nightmare rewards use 1x, 2x and 3x multipliers.

## Abilities and Rotten Shell energy

Every animal resolves to three abilities costing 2, 4 and 7 energy. Missing
named loadouts safely receive the complete fallback set.

The final Rotten Shell duel keeps energy centers within the middle 35%-65% of
both arena axes. Its timer moves or creates an orb every 1.5 seconds, gold
energy has a one-in-eight chance and boss attacks occur every 1.85 seconds.
The first-time tutorial guarantees blue energy, gold energy and one ability.

Final-duel health and attack scale from the selected animal, which avoids
making low-tier animals mathematically unusable. A basic damage ability deals
about one seventh of the boss's scaled health, while each boss attack removes
about 8.5% of player health before shields.

## Findings

### High: collected energy immediately respawns

Normal energy collection calls the spawn method immediately. A quick player
can therefore collect continuously without waiting for the documented
1.5-second timer. The timer currently changes position rather than enforcing a
spawn cooldown. This explains why energy can still feel too frequent.

### High: boss rewards can skip the coin ladder

The first Slime victory plus its first two quest rewards grants 8,500 coins.
Later boss rewards grow to two million coins before difficulty multipliers.
As recorded in the economy audit, the 10-token Boss Egg is an even larger
progression bypass. Boss and egg rewards need to be rebalanced together.

### Medium: manual recommended power is not a difficulty gate

Manual battles remove one life per collision and one boss life per successful
shield-break shot. Recommended power, max HP and projectile-damage values
primarily serve simulated battles, while the manual fighter's power mainly
affects the Rotten Shell final duel. The shared presentation can imply that
recommended power matters more to normal manual fights than it does.

### Medium: elite difficulty jumps sharply

Elite fights apply their difficulty scaling immediately: roughly 1.85x base
projectile speed, a 300ms minimum interval and higher tracking strength. This
is appropriately harder than Nightmare progression, but needs real-device
playtest evidence for touch controls and reduced-effects mode.

## Conclusions

The life ladder, unlock chain, ability availability, center-only energy area
and final-duel scaling are coherent. The two release blockers are the immediate
energy respawn and rewards that overwhelm the main economy. Resolve those with
the broader economy rebalance, then playtest every boss on a narrow touch
device before considering this gate balanced.
