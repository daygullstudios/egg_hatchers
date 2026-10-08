# Closed beta coverage matrix

Use this matrix only after the release owner approves closed beta entry. It is a
planning and evidence document, not an invitation list. Record counts and
assignments only unless the approved privacy/support process explicitly permits
private tester identifiers.

## Entry Rules

- Closed beta entry must be approved by the release owner.
- The family/privacy plan must approve the tester audience and support process.
- Launch platforms and countries must be selected.
- The candidate commit, build identifiers and protected Worker versions must be
  recorded.
- Testers must receive ordinary fresh accounts unless their assignment is
  import, recovery, account switching, multiplayer pairing or trading.
- Do not use seeded developer boosts, edited saves or secret progress unless a
  specific bug reproduction requires it.
- Do not recruit child testers unless the approved guardian process is active.

## Required Coverage

Fill this table before sending the tester packet.

| Coverage area | Minimum before beta | Evidence to record |
| --- | --- | --- |
| Fresh-player path | At least 1 tester | First hatch, first boss, first rebirth or blocker |
| Returning/import path | At least 1 tester | Save Transfer or cloud recovery result |
| Multiplayer/trading pair | At least 1 pair on different networks | Battle, trade, preset-message and reconnect result |
| Narrow phone layout | At least 1 tester | Supported narrow-width device/browser result |
| Larger screen/tablet | At least 1 tester if selected platform supports it | Layout and touch-target result |
| Selected web browser | Every selected browser family | Browser/version result |
| Android device | Required only if Android is selected | Signed build or approved test build result |
| iOS device | Required only if iOS is selected | Real-device result |
| School/work or restricted network | At least 1 if launch audience includes it | Connectivity or fail-closed result |
| Parent/guardian-supervised tester | Only if approved by family/privacy review | Consent/support process result |

## Assignment Records

For each tester assignment, record:

- Assignment ID.
- Coverage area.
- Platform/device/browser.
- Network type.
- Fresh, returning/import, multiplayer/trading, or accessibility focus.
- Whether online features are enabled.
- Whether parent/guardian supervision is approved and required.
- Tester packet sent: yes/no.
- Findings log ID references.
- Retest needed: yes/no.

Do not record passwords, one-time codes, authentication tokens, government IDs,
full browser storage dumps, private Save Transfer files, private support
documents, child/guardian details, or unnecessary personal contact information
in this matrix.

## Exit Checks

Closed beta coverage is incomplete until:

- Every selected launch platform and browser family has at least one candidate
  result.
- Fresh-player, returning/import and multiplayer/trading assignments are
  covered.
- Narrow-phone layout is covered, and larger-screen/tablet coverage is recorded
  if selected.
- Restricted-network or cross-network play is covered where relevant.
- Every critical or high finding from the covered assignments is fixed, retested
  or explicitly accepted by the release owner and rollback decision maker.
- The findings log and release candidate record cite this matrix.

