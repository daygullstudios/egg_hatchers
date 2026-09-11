# Nestarium release roadmap

Updated: 2026-09-10

This is the working checklist for the first public Nestarium release. A checked
item needs evidence from the release candidate, not only an implementation or a
passing test from an older build.

## Version 1.0 scope

Included:

- Core hatching, mutations, income, upgrades, rebirths, quests and collection.
- Fusion and custom animal sprites.
- Classic, Retro Pixel and Realistic visual styles.
- Manual boss fights, boss rewards and the Rotten Shell/DayGull discovery path.
- Local profiles, Save Transfer and protected cloud-save recovery.
- Bot Arena while public multiplayer is being completed.
- Online matchmaking, direct battle invitations and authoritative rewards.
- Online trading, collection viewing and preset-message communication.
- Web release and any native platforms that pass the final platform decision.

Excluded from 1.0:

- Custom eggs. Legacy records remain readable but are not playable.
- Open text chat, voice chat or public custom-art sharing.
- Halloween, Christmas, Easter and Corruption events.
- 3D Corruption battle experiments.
- Interstitial ads, rewarded ads, premium currency and paid randomized rewards.
- Active banner ads or Remove Ads checkout until every monetization gate passes.
- Removal of Bot Arena without explicit owner approval.

## Release gates

### 1. Scope and ownership

- [x] Record the version 1.0 feature boundary.
- [x] Keep future events outside the launch candidate.
- [x] Retire custom eggs without breaking old Save Transfer files.
- [ ] Confirm launch platforms: web, Android and/or iOS.
- [ ] Confirm launch countries.
- [ ] Name one release owner and one rollback decision maker.

Exit: no unresolved feature is being treated as silently required for 1.0.

### 2. Accounts and save recovery

- [x] Preserve local profiles and versioned JSON Save Transfer.
- [x] Protect anonymous guest progress with revisioned cloud sync.
- [x] Stop uncertain or conflicting cloud state from overwriting local progress.
- [x] Start a fresh anonymous cloud session after a protected local guest is
  removed, without deleting or reassigning the old cloud account.
- [x] Verify player-directory writes before publishing profile creation or
  removal in the running app.
- [x] Commit local player removal before deleting its progress, so a failed
  directory write cannot leave a visible player with a missing save.
- [x] Simulate clean-device provider recovery through identity switching,
  conflict review and explicit cloud restore without overwriting either copy.
- [x] Prevent overlapping provider-link requests from opening competing identity
  operations for the same local player.
- [x] Serialize and verify device-guest identity rotation so a stale cloud UID
  cannot attach to a replacement guest during overlapping account operations.
- [ ] Complete an approved account-recovery method that works across devices.
- [ ] Prove guest linking preserves the same player and cloud document.
- [ ] Prove recovery on a clean second device or browser.
- [ ] Implement and test complete cloud-account deletion where required.
- [ ] Run the account-switch, deletion, offline, conflict and corrupt-save matrix.

Exit: a fresh player, returning player and migrating player can recover safely.

### 3. Family safety and privacy

- [x] Keep player communication preset-only.
- [x] Keep hosted capabilities fail-closed when policy claims are missing.
- [x] Add server-enforced blocking and bounded report reasons.
- [ ] Obtain professional audience/privacy review for the intended ages 8-12,
  teen and adult audience.
- [ ] Implement the approved age/guardian capability flow before optional data
  connections.
- [ ] Add parent-managed permissions, review, revocation and deletion controls.
- [ ] Finalize retention rules and provider responsibilities.
- [ ] Verify names, discovery, invitations, messages and trading under every
  account capability level.
- [ ] Publish candidate-accurate Privacy Policy, Terms and support instructions.

Exit: local play remains useful and every online/data capability is authorized
and enforced by the server.

### 4. Multiplayer and trading

- [x] Implement matchmaking, direct invitations, battles and preset messages.
- [x] Implement authoritative battle settlement and replay-safe receipts.
- [x] Implement authoritative roster validation and atomic trades.
- [x] Preserve both rosters when a trade disconnects before confirmation.
- [x] Handle battle reconnect windows without inventing an outcome.
- [ ] Complete trusted authenticated sessions in the production environment.
- [ ] Complete the user-managed blocked-player list.
- [ ] Test duplicate sessions, reconnects, forfeits, timeouts and stale clients.
- [ ] Test matchmaking fairness and reward balance with representative accounts.
- [ ] Run two-device internet play outside the developer network.
- [ ] Run load and capacity tests for the intended launch size.

Exit: clients cannot mint rewards, duplicate trades, impersonate players or
leave one player with a one-sided result.

### 5. Gameplay and economy

- [x] Restrict purchases and hatches to canonical built-in eggs.
- [ ] Measure the new-player path through first hatch, first boss and first
  rebirth.
- [ ] Review every egg price, rarity table, income curve and rebirth multiplier.
- [ ] Review boss difficulty, lives, abilities, energy frequency and rewards.
- [ ] Review DayGull progression and endgame income for economy-breaking jumps.
- [ ] Review fusion, daily rewards, quests, multiplayer rewards and roster drops.
- [ ] Test fresh, midgame and late-game saves without developer boosts.
- [ ] Fix every progression blocker and practical farming exploit.

Exit: progression is understandable, rewarding and resistant to obvious abuse.

### 6. Visuals, audio and accessibility

- [ ] Audit every animal in Classic, Retro Pixel and Realistic styles.
- [ ] Replace unfinished or inconsistent Retro Pixel assets.
- [ ] Audit egg art, boss art, backgrounds, projectiles, trails and cinematics.
- [ ] Approve the final Nestarium logo and regenerate platform branding assets.
- [ ] Finalize boss phase music loops and all other music transitions.
- [ ] Normalize music and sound-effect volume.
- [ ] Verify audio unlock, pause/resume and background/foreground behavior on
  each release platform.
- [ ] Test narrow phones, tablets and desktop layouts at supported text scales.
- [ ] Check contrast, reduced-motion behavior, labels and touch-target sizes.
- [ ] Confirm commercial rights and source records for every shipped asset.

Exit: there are no placeholder assets, broken layouts, inaccessible controls or
unlicensed release assets.

### 7. Reliability and security

- [x] Run static analysis, automated Flutter tests and release web builds in CI.
- [x] Scan the compiled web release for developer-only controls in CI.
- [x] Protect the private playtest and disable public preview aliases.
- [ ] Run a release-focused code review for crashes, data loss and security bugs.
- [ ] Test slow/offline startup, refreshes, interrupted saves and service outages.
- [ ] Test older supported Save Transfer files against the candidate.
- [ ] Add production error monitoring that matches the approved privacy model.
- [ ] Confirm backups, restore procedures, rate limits and operational alerts.
- [ ] Perform a security review of authentication, multiplayer and trading.

Exit: critical failures are observable, recoverable and documented.

### 8. Platform and store readiness

- [ ] Configure Android release signing and protect the signing credentials.
- [ ] Build and inspect a signed Android App Bundle if Android is selected.
- [ ] Configure iOS signing and run real-device testing if iOS is selected.
- [ ] Complete store names, descriptions, screenshots, ratings and disclosures.
- [ ] Complete Google Play Data Safety and Apple privacy answers from the actual
  candidate behavior.
- [ ] Verify account-deletion and support links from each selected store.
- [ ] Keep monetization dormant unless its separate operations plan is complete.

Exit: each selected platform has a signed, policy-complete candidate.

### 9. Closed beta

- [ ] Recruit a small trusted group across supported devices and networks.
- [ ] Give testers ordinary fresh accounts and written reporting instructions.
- [ ] Track crashes, save failures, progression confusion and multiplayer abuse.
- [ ] Resolve all critical and high-priority findings.
- [ ] Repeat focused tests for every fix and one complete candidate pass.

Exit: the candidate survives realistic play without a critical unresolved issue.

### 10. Release candidate and launch

- [ ] Freeze features and remove or hide development-only controls.
- [ ] Run analysis, all tests, compatibility audit and every release build.
- [ ] Complete the cross-platform account/save/multiplayer acceptance matrix.
- [ ] Record the exact commit, build numbers, infrastructure versions and backup.
- [ ] Test rollback to the previous protected version.
- [ ] Obtain explicit owner approval for public routing and store submission.
- [ ] Release gradually and monitor saves, identity, crashes and multiplayer.

Exit: the approved build is public, monitored and reversible.

## Immediate work order

1. Continue the release-focused code review across save integrity and
   authentication boundaries.
2. Close the cross-device account recovery path.
3. Finish the family capability and deletion requirements.
4. Run the authoritative multiplayer two-device and failure-recovery matrix.
5. Balance the economy and complete visual/audio asset audits.
6. Enter closed beta only after gates 2 through 7 have release evidence.
