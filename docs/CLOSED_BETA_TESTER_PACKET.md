# Nestarium closed beta tester packet

Updated: 2026-10-08

This packet is the tester-facing companion to `docs/CLOSED_BETA_PLAN.md`. It is
not an invitation by itself. Send it only after the release owner approves closed beta entry,
the family/privacy plan is approved, and the selected candidate is
recorded in `docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md`.

## Privacy boundary

- The beta link is private. Do not post it publicly or share it outside the
  invited tester group.
- Do not send passwords, one-time codes, authentication tokens, government IDs,
  full browser storage dumps, or private Save Transfer files in a first report.
- A Save Transfer file is private account data. Send it only if the release
  owner asks for it directly and says where to send it.
- Do not test with a child account or child tester unless the approved
  family/privacy process says that tester is allowed.
- Player communication remains preset-only. Do not ask for or expect open chat.

## Account setup

Use an ordinary fresh account unless the tester assignment specifically says to
test import, recovery, account switching, multiplayer pairing, or trading.
Do not use seeded developer boosts. Do not use secret progress or edited saves
unless the release owner asks for a specific bug reproduction.

Before testing, write down:

- Device type.
- Browser or app version.
- Network type, such as home Wi-Fi, mobile hotspot, or school/work network.
- Tester assignment, such as fresh player, returning/import, multiplayer pair,
  narrow phone, or larger screen.

The release team records assignment coverage in
`docs/CLOSED_BETA_COVERAGE_MATRIX.md`. Do not send extra personal information
unless the release owner asks for it through the approved support process.

## Core test path

Try these in order:

1. Create a fresh player.
2. Hatch first animals and confirm income is understandable.
3. Open Settings and find account options.
4. Export a Save Transfer file, but keep it private unless requested.
5. Visit Egg Shop, Collection, Fusion, Battles, and Custom Animals.
6. Complete at least one manual boss fight.
7. Try Bot Arena.
8. Close and reopen the game after progress changes.
9. Refresh during a low-risk moment and confirm progress still makes sense.

## Online feature path

Only do this if online features are enabled for the beta and the tester was
assigned to a multiplayer/trading pair:

1. Confirm both players can appear online.
2. Send and accept one direct battle invitation.
3. Send and decline one direct battle invitation.
4. Send and accept one trade invitation.
5. Cancel or decline one trade invitation.
6. View another player's animals.
7. Send at least one preset message.
8. Disconnect or refresh one player during a low-risk online moment, then report
   whether both players recover cleanly.

## What to report

For every issue, send:

- What you were doing.
- What you expected to happen.
- What happened instead.
- Device, browser, and network type.
- Approximate time.
- Whether refreshing or reopening changed anything.
- Screenshot or short recording, if comfortable.
- Whether the issue affected progress, animals, accounts, trading, battles, or
  rewards.

Use the categories in `docs/CLOSED_BETA_FINDINGS_LOG_TEMPLATE.md` when the
release team records the issue. Critical and high-priority issues block release
unless the release owner and rollback decision maker explicitly accept the risk.

## Tester message

```text
You are invited to a private Nestarium test. Please do not share the link,
screenshots, recordings, save files or account details publicly.

Please use a normal fresh account unless we specifically ask you to test import,
recovery, multiplayer, trading or account switching.

Try hatching, upgrades, settings, account options, a boss fight, collection,
fusion and the online features we ask you to test.

If something breaks, send what you were doing, what you expected, what happened
instead, your device/browser/network, the approximate time, and a screenshot or
short recording if you are comfortable.

Do not send passwords, one-time codes, authentication tokens, full browser
storage dumps or private Save Transfer files unless we clearly ask for them.
```
