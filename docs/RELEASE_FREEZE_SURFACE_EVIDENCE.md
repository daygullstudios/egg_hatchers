# Release Freeze Surface Evidence

Updated: 2026-10-07

This record supports the roadmap item "Freeze features and remove or hide
development-only controls." The item remains open until a final release
candidate is frozen and audited, but the current code has a documented boundary
for developer-only tools.

## Current boundary

- Developer Tools remain in source for local development only.
- `pushDevToolsRoute` in `lib/navigation/app_page_route.dart` returns without
  opening anything when `kDebugMode` is false.
- The Secret Hatchery's `Developer Tools (Debug)` button is wrapped in
  `if (kDebugMode)` in `lib/screens/secret_tools_screen.dart`.
- Legacy save field `fullDeveloperToolsUnlocked` is still readable and
  round-trippable for old Save Transfer files, but it is not a release access
  switch for Developer Tools.
- The release surface audit scans `build/web/main.dart.js` after
  `flutter build web --release` and fails if known developer-only control labels
  are present.

## Release audit command

Run this after creating the release web bundle:

```powershell
node tool/audit_release_surface.mjs
```

The audit currently blocks these markers from compiled release output:

- `Developer Tools (Debug)`
- `Force Next Single Hatch`
- `Unlock Rotten Shell reqs`
- `Preview DayGull Unlock`
- `Collect All Animals`

## Remaining release-candidate work

- Freeze features for a named candidate commit.
- Build the frozen candidate with `flutter build web --release`.
- Run `node tool/audit_release_surface.mjs` against that exact bundle.
- Run the full release test/build matrix from
  `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.
- Record owner approval before public routing or store submission.

