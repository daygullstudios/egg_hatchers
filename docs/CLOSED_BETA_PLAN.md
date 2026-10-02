# Nestarium closed beta plan

Updated: 2026-10-02

This is a preparation document for the closed beta gate. It does not authorize
recruiting testers, routing a public game host, store submission, or collecting
child tester data. The beta starts only after the required release gates in
`docs/RELEASE_ROADMAP.md` are satisfied and the owner decisions in
`docs/RELEASE_DECISION_PACKET.md` are recorded.

## Entry requirements

Before inviting testers:

- Gates 2 through 7 in `docs/RELEASE_ROADMAP.md` must have release evidence or
  an explicitly accepted remaining risk.
- Launch platforms and countries must be chosen.
- A release owner and rollback decision maker must be named.
- Family/privacy review must approve the beta audience, data handling, support
  workflow and any parent/guardian controls required for the selected testers.
- Production monitoring, backup, restore and alert procedures must be approved.
- The final logo, shipped music rights and candidate platform branding must be
  approved.
- Testers must receive ordinary fresh accounts; do not seed developer boosts or
  secret progress unless a specific bug reproduction requires it.

## Tester group

Recruit a small trusted group that covers the selected launch platforms and
networks. The group should include:

- A fresh-player tester who has never played Nestarium.
- A returning-player tester who imports or restores progress.
- A multiplayer/trading pair on different networks.
- At least one narrow-phone layout tester.
- At least one larger-screen or tablet tester if that platform is selected.
- A parent/guardian-supervised tester only if the approved privacy plan allows
  it and the consent/support process is ready.

Avoid open invitations, public Discord links, public custom-art sharing, or any
open text chat. Player communication remains preset-only.

## Test pass

Each beta tester should try to complete:

- Create a fresh player.
- Hatch the first animals and understand income.
- Open Settings, export a Save Transfer file and know where account options are.
- Reach the first boss path and try at least one manual boss fight.
- Use Collection and Fusion.
- Try Bot Arena.
- If online features are enabled for the beta, try one online battle, one direct
  battle invitation, one trade and one preset-message exchange.
- Close and reopen the game after progress changes.
- Refresh or restart during a low-risk moment, then confirm progress is still
  understandable.

Internal acceptance should also include:

- One interrupted-save scenario using a disposable account.
- One account recovery/import scenario.
- One multiplayer disconnect/reconnect scenario.
- One trade cancellation/disconnect scenario.
- One blocked-player/report flow using test accounts only.

## What testers should report

Ask testers to report:

- What they were doing.
- What they expected to happen.
- What actually happened.
- Device/browser/platform.
- Approximate time.
- Whether refreshing or reopening changed anything.
- Screenshot or short screen recording, if comfortable.
- Whether the issue affected progress, animals, accounts, trading or rewards.

Do not ask testers to send passwords, one-time codes, authentication tokens,
government IDs, full browser storage dumps or private save files in a first
message. If a Save Transfer file is needed, the release owner should request it
explicitly and treat it as private.

## Triage categories

Use these categories for beta findings:

- Critical: data loss, account takeover, minted rewards, duplicated trades,
  public exposure of private data, crash loop on startup, or unsafe child/privacy
  behavior.
- High: progression blocker, failed account recovery, broken online battle or
  trade settlement, inaccessible core UI, or confusing save conflict.
- Medium: balance issue, unclear tutorial, layout problem, audio problem,
  non-critical visual bug, or confusing text.
- Low: polish, typo, small animation issue, or nice-to-have improvement.

Critical and high findings block release until fixed or explicitly accepted by
the release owner and rollback decision maker.

## Exit requirements

Closed beta can exit only when:

- All critical and high-priority findings are resolved or explicitly accepted.
- Every fix has a focused retest.
- One complete candidate pass succeeds on the selected platforms.
- Account/save/multiplayer acceptance is repeated after the last risky fix.
- The exact commit, build identifiers, infrastructure versions and backup state
  are recorded.
- Rollback to the previous protected version is tested.

## Tester message template

Use this only after the release owner approves beta recruitment:

```text
You are invited to a private Nestarium test. Please do not share the link,
screenshots, recordings, save files or account details publicly.

Please play with a normal fresh account unless we specifically ask you to test
import or recovery. Try hatching, upgrades, a boss fight, collection, fusion and
the online features we ask you to test.

If something breaks, send:
- what you were doing,
- what you expected,
- what happened instead,
- your device/browser,
- the approximate time,
- and a screenshot or short recording if you are comfortable.

Do not send passwords, one-time codes, authentication tokens or private account
documents. If we need a save file, we will ask for it clearly.
```
