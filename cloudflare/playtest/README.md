# Egg Hatchers private web playtest

This directory is the checked-in Cloudflare delivery boundary for the compiled
Flutter web game. It follows the proven Railcade shape while the current Egg
Hatchers name remains an internal migration label.

The playtest publishes only to
`egg-hatchers-playtest.daygullstudios.com`. `workers_dev` and preview URLs stay
disabled, so Cloudflare does not create an unprotected alternate game URL.

The temporary hostname is intentionally beneath the studio domain so the final
product-name decision remains independent. Its self-hosted Cloudflare Access
application is `2ed23c5f-4d30-42e9-83c4-90b4e24c2135` and reuses Railcade's
approved-tester allow policy. The policy itself remains managed in Cloudflare;
tester email addresses and credentials are never checked into the repository.

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

Never place Cloudflare API tokens, Firebase credentials, Access assertions, or
tester email lists in this directory or in the Flutter web bundle.
