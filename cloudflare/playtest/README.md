# Nestarium private web playtest

This directory is the checked-in Cloudflare delivery boundary for the compiled
Nestarium Flutter web game. `deployment_identity.json` records its product
identity, active hostname, retired origin, and release gates.

The playtest publishes only to the protected Nestarium hostname
`playtest.playnestarium.com`. The former
`egg-hatchers-playtest.daygullstudios.com` compatibility origin was explicitly
retired on 2026-09-08 after the owner accepted its origin-scoped save/session
migration risk.
`workers_dev` and preview URLs stay disabled, so Cloudflare does not create an
unprotected alternate game URL.

The selected public domain is `playnestarium.com`. The new private hostname
`playtest.playnestarium.com` is covered by the existing Nestarium Access
application and Firebase authorized domains. The apex is a separate public
information site and never serves the Flutter build. Do not add an apex,
wildcard, preview, or workers.dev game route as a shortcut.

The Worker resource name stays `egg-hatchers-playtest` to retain deployment
history, rollback continuity and compatibility identifiers. Its self-hosted
Cloudflare Access application is
`2ed23c5f-4d30-42e9-83c4-90b4e24c2135`, displayed as **Nestarium private
playtest**, and reuses the established approved-tester allow policy. The policy
itself remains managed in Cloudflare;
tester email addresses and credentials are never checked into the repository.

Keep this application's **Eager redirect cookie** setting off. The tester policy
and 24-hour session duration remain unchanged.

The legacy hostname retirement release is static Worker version
`addf225a-6d3f-4d19-9201-11d9d8a7db9c` and multiplayer Worker version
`7e5a1674-7389-40d8-aefb-0bdce354fdec`. Both now route only through
`playtest.playnestarium.com`; the old hostname resolves NXDOMAIN.

## Release boundary

- Flutter produces the shared web client in `build/web`.
- Cloudflare Workers Static Assets serves that directory as a single-page app.
- `web/_headers` keeps the private build out of search results and applies the
  browser hardening that does not conflict with Flutter.
- Firebase will own protected identity and durable progress. Cloudflare does
  not become a second save database.
- `../multiplayer` is the separate authenticated Worker/Durable Object for the
  `/ws*` route. Keep its identity, tests and deployment separate from assets.
- The protected build command enables hosted test battles and hosted Online
  Roster trading. Public/default builds keep both release switches off. Hosted
  results, ratings and rewards are server-set; hosted teams and trades use only
  the separate server-owned Online Roster and never mutate the Hatchery
  Collection. The first completed hosted match per UTC day adds one server-owned
  roster animal for each participant; its settlement receipt is replay-safe.
- Hosted battle and trade interactions include preset-only report and block
  controls. Peer identity is resolved server-side, blocks apply to both future
  battle and trade matching, and blocking an active trade cancels before either
  Online Roster can change.

## Local verification

From this directory:

```powershell
npm test
npm run build:web
npm run deploy:dry-run
```

The dry run does not create or update a Cloudflare Worker. `npm run deploy`
uploads a new version and updates only the protected custom-domain route.

## First-deployment verification

1. Keep `workers_dev` and preview URLs disabled.
2. Run the configuration test, web release build, and Wrangler dry run.
3. Deploy and verify that an unauthenticated browser is redirected to Access
   while an approved identity reaches the game.

See `../../docs/NESTARIUM_MIGRATION.md` for continuity decisions and the
remaining hostname/provider acceptance steps. The Google-linking client is
staged behind `NESTARIUM_GOOGLE_SIGN_IN_ENABLED` (false by default); enable it
only in an explicitly qualified provider release.

Never place Cloudflare API tokens, Firebase credentials, Access assertions, or
tester email lists in this directory or in the Flutter web bundle.
