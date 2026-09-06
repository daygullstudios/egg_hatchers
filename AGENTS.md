# Nestarium Working Rules

These instructions are part of the project and apply on every development computer.

The public product is **Nestarium**, with selected domain `playnestarium.com`.
Read `docs/NESTARIUM_MIGRATION.md` before changing product identifiers or
hostnames. Preserve the compatibility identities in
`docs/LEGACY_BRAND_REFERENCES.json`; `node tool/audit_brand.mjs` verifies the
inventory. The staged Nestarium hostname must not be routed before its
documented protection, identity, and recovery gates pass.

## Git workflow

- Work on `main` unless the user requests another branch.
- After each completed patch or update, run the relevant checks, commit it, and push it to `origin` automatically.
- Never discard unrelated user changes. Include only the intended work in each commit.
- The canonical repository is `https://github.com/daygullstudios/egg_hatchers.git`.

## Playtest deployment

- Every completed, verified user-facing implementation must also be deployed to the protected Cloudflare playtest at `egg-hatchers-playtest.daygullstudios.com` unless the user explicitly says not to deploy it.
- Build the current release with `flutter build web --release`, then from `cloudflare/playtest` run `npm test`, `npm run deploy:dry-run`, and `npm run deploy`.
- Confirm Wrangler reports the protected custom-domain route and a new current version ID. Do not treat a local build or local server refresh as a playtest deployment.
- Documentation-only and test-only changes do not require a playtest deployment unless they accompany a user-facing implementation.

## Animal art

- Every new animal must ship with three distinct versions: Classic, Retro Pixel, and Realistic.
- Classic art should be clearly cartoony and should not look like a lightly edited realistic asset.
- Retro Pixel art should use deliberate pixel construction and the shared retro palette.
- Realistic art should use the established high-detail transparent sprite treatment.
- DayGull animals use animated light-blue, dark-blue, and purple side-slice glitch effects where established.

## Product direction

- Keep Bot Arena while multiplayer battles are still being developed. Remove it only after multiplayer is complete and the user approves removal.
- Player communication remains preset-message only; do not add open text chat.
- New accounts start with no progress and must not overwrite older local accounts.
- Preserve the first-time Rotten Shell and DayGull Egg unlock flow.
- Keep controls usable at the narrow phone-width layout used throughout the game.

## Future events

Do not implement these until the user asks. Planned order is Halloween, Christmas, Easter, then Corruption. See `PROJECT_HANDOFF.md` for the saved concepts.

## Verification

- Run `flutter analyze` and `flutter test` after behavioral changes.
- Run `flutter build web --release` when changing platform code, assets, routing, hosting, or before handing a preview to the user.
- The local combined web and multiplayer server normally uses port `53218`.
