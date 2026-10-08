# Nestarium release decision packet

Updated: 2026-10-08

This packet turns the remaining roadmap blockers into concrete owner decisions.
It does not change runtime behavior, publish a store listing, route a public
game host or approve launch. Keep the unchecked roadmap items open until the
answers are recorded and verified against the candidate build.

## Decisions needed before the next release gates can close

### 1. Launch platforms

Choose the first public release target:

- Web only.
- Web plus Android.
- Web plus iOS.
- Web plus Android and iOS.

Current evidence:

- Web is the most mature path. `playnestarium.com` is the public non-playable
  information site, and `playtest.playnestarium.com` is the protected game
  origin.
- Android source exists and has a release-signing hook in
  `android/app/build.gradle.kts`, but release signing is not configured until
  a private `android/key.properties` and upload keystore exist.
- iOS source exists, but signing, App Store Connect work and real-device testing
  still need the Mac/App Store path.

Roadmap items this unlocks:

- Confirm launch platforms.
- Android release signing and signed App Bundle, if Android is selected.
- iOS signing and real-device testing, if iOS is selected.
- Cross-platform account/save/multiplayer acceptance matrix.

### 2. Launch countries

Choose the initial countries or regions where the public release will be
available. Do not assume the US-only privacy rules cover every selected region.

Current evidence:

- `docs/FAMILY_AUDIENCE_V1.md` records the intended family audience, including
  ages 8-12, and says professional review is still required.
- Store data-safety/privacy answers must come from the final countries,
  platforms and runtime behavior.

Roadmap items this unlocks:

- Confirm launch countries.
- Professional audience/privacy review.
- Candidate-accurate Privacy Policy, Terms and support instructions.
- Store ratings, disclosures and Data Safety/Privacy answers.

### 3. Release owner and rollback decision maker

Name:

- One release owner who can say whether the candidate is ready.
- One rollback decision maker who can decide to revert routing, store rollout or
  infrastructure changes.

Current evidence:

- `docs/RELEASE_OPERATIONS_EVIDENCE.md` records that backups, alerts and restore
  procedures are not complete until a named owner approves them.
- `docs/RELEASE_MONITORING_EVIDENCE.md` records that alert destinations remain
  open.

Roadmap items this unlocks:

- Name one release owner and one rollback decision maker.
- Confirm backups, restore procedures, rate limits and operational alerts.
- Record the exact commit, build numbers, infrastructure versions and backup.
- Test rollback to the previous protected version.

### 4. Final logo and platform branding approval

Approved: yes. The owner approved the three-style Nestarium logo source in the
2026-10-08 project thread and requested that it be implemented as the new logo.
Commit `99bd909` replaced the approved source image and regenerated the platform
branding assets.

Current evidence:

- `docs/ASSET_RIGHTS_RELEASE_AUDIT.md` tracks shipped asset roots and calls out
  asset-rights items that still need owner confirmation.
- `docs/PLATFORM_BRANDING_READINESS.md` records the approved source, generator
  targets and verification commands.
- `docs/VISUAL_AUDIO_ACCESSIBILITY_AUDIT.md` records logo approval and generated
  platform branding as completed evidence.

Roadmap items this unlocks:

- Approve the final Nestarium logo and regenerate platform branding assets.
- Complete store screenshots/branding materials.

### 5. Music and shipped-asset rights

Confirm the source and commercial-use rights for every shipped music file,
especially:

- `assets/sounds/music/hatchery_chill_loop.mp3`
- `assets/sounds/music/boss_music.wav`
- `assets/sounds/music/final_boss_music.mp3`

Current evidence:

- `docs/ASSET_RIGHTS_RELEASE_AUDIT.md` records those music files as needing
  owner confirmation.
- The app has audio transition work, but final listening/normalization and
  platform audio behavior remain open.

Roadmap items this unlocks:

- Confirm commercial rights and source records for every shipped asset.
- Finalize boss phase music loops and all other music transitions.
- Normalize music and sound-effect volume.
- Verify audio unlock, pause/resume and background/foreground behavior on each
  release platform.

### 6. Monitoring, backups and alerts

Approve the production privacy-safe monitoring and operations model:

- Allowed operational fields.
- Log retention and support-access rules.
- Alert destinations.
- Backup cadence.
- Restore rehearsal owner and schedule.

Current evidence:

- Cloudflare Worker Observability is already enabled for the protected playtest
  and multiplayer Workers.
- Client analytics/crash SDKs are deliberately absent until family privacy
  review approves them.
- `docs/RELEASE_OPERATIONS_EVIDENCE.md` records existing restore, rate-limit and
  receipt evidence, but keeps production operations open.

Roadmap items this unlocks:

- Add production error monitoring that matches the approved privacy model.
- Confirm backups, restore procedures, rate limits and operational alerts.

### 7. Family/privacy review path

Choose how the professional family-audience/privacy review will happen and who
will approve the resulting controls.

Current evidence:

- The game intentionally includes ages 8-12, teens and adults.
- Hosted capabilities fail closed when policy claims are missing.
- Player communication is preset-only.
- Parent-managed controls, retention rules and store/public disclosures remain
  unfinished.

Roadmap items this unlocks:

- Obtain professional audience/privacy review.
- Implement the approved age/guardian capability flow.
- Add parent-managed permissions, review, revocation and deletion controls.
- Finalize retention rules and provider responsibilities.
- Complete trusted authenticated sessions in the production environment.

## Recommended next answer set

When ready, answer these in one message:

1. First release platforms:
2. First launch countries:
3. Release owner:
4. Rollback decision maker:
5. Final logo approved: yes
6. Music rights confirmed for the three listed files: yes/no
7. Production monitoring/alerts owner:
8. Family/privacy review owner or plan:

For a more complete fillable record, copy
`docs/RELEASE_OWNER_DECISION_FORM.md` to a dated release decision record and
fill every selected-platform, rights, privacy, monitoring, multiplayer, beta and
store owner field.

Until those are answered, continue polishing only non-publishing work that does
not require store credentials, public routing, legal/privacy approval or launch
ownership.
