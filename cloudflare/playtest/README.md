# Nestarium private web playtest

This directory is the checked-in Cloudflare delivery boundary for the compiled
Nestarium Flutter web game. `deployment_identity.json` records its product
identity, active compatibility origin, staged hostname, and release gates.

The playtest publishes only to
`egg-hatchers-playtest.daygullstudios.com`. `workers_dev` and preview URLs stay
disabled, so Cloudflare does not create an unprotected alternate game URL.

The selected public domain is `playnestarium.com`. The new private hostname
`playtest.playnestarium.com` is staged in Access and Firebase authorized domains
but has no web DNS/Worker route yet. The apex has mail-only MX/TXT records for
the staged support identity; those do not publish the game. Keep it unrouted until the gates in
`deployment_identity.json` are accepted. Do not add an apex, wildcard, preview,
or workers.dev route as a shortcut.

The Worker resource name stays `egg-hatchers-playtest` to retain deployment
history and rollback continuity. The current browser origin remains available
without a redirect because browser saves and anonymous credentials are
origin-scoped. Its self-hosted Cloudflare Access application is
`2ed23c5f-4d30-42e9-83c4-90b4e24c2135`, displayed as **Nestarium private
playtest**, and reuses the established approved-tester allow policy. The policy
itself remains managed in Cloudflare;
tester email addresses and credentials are never checked into the repository.

Keep this application's **Eager redirect cookie** setting off while any staged
hostname is unrouted. Access issues authorization cookies when each hostname is
visited; it must not redirect current players through an unresolved hostname.
The tester policy and 24-hour session duration remain unchanged.

The first routed release is Worker version
`b95eec09-b6a8-4071-b20b-4bf4d97c9b00`. Direct unauthenticated requests to both
`/` and `/main.dart.js` return Cloudflare Access redirects, confirming that the
HTML shell and compiled game bundle are protected. Recursive DNS may take a few
minutes to replace an earlier negative lookup after the custom domain is first
attached.

## Release boundary

- Flutter produces the shared web client in `build/web`.
- Cloudflare Workers Static Assets serves that directory as a single-page app.
- `web/_headers` keeps the private build out of search results and applies the
  browser hardening that does not conflict with Flutter.
- Firebase will own protected identity and durable progress. Cloudflare does
  not become a second save database.
- A later multiplayer Worker or Durable Object must be a separate service from
  this static-delivery project.

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
