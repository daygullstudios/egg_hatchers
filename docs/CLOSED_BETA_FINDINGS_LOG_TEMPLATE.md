# Closed Beta Findings Log Template

Use this template only after the release owner approves closed beta entry. Do
not fill it with real tester details until the approved privacy/support process
is active.

## Candidate

- Candidate name:
- Git commit:
- Build/platform:
- Protected playtest version:
- Multiplayer Worker version:
- Release owner:
- Triage owner:

## Tester Coverage

Record counts only unless the approved support process requires a private
identifier.

- Fresh-player testers:
- Returning/import testers:
- Multiplayer/trading pairs:
- Narrow-phone testers:
- Larger-screen/tablet testers:
- Supported platforms covered:
- Supported networks covered:

## Finding Entry

Copy one entry for each finding.

```text
ID:
Severity: Critical / High / Medium / Low
Status: New / Investigating / Fixed / Retest passed / Accepted risk / Won't fix
Area: Account / Save / Recovery / Hatching / Economy / Boss / Multiplayer / Trading / UI / Audio / Visual / Accessibility / Privacy / Other
Platform/device/browser:
Approximate time:
Fresh, returning, or multiplayer tester:
What the tester was doing:
Expected result:
Actual result:
Progress/account/reward impact:
Reproduction steps:
Screenshot or recording reference:
Private data received: No / Yes, handled by release owner
Fix commit:
Focused retest result:
Release decision:
```

## Release-Blocking Summary

- Critical findings open:
- High findings open:
- Account/save/multiplayer regressions open:
- Privacy/family-safety findings open:
- Candidate pass after last risky fix: yes/no
- Account/save/multiplayer acceptance repeated after last risky fix: yes/no
- Rollback test after candidate: yes/no

Closed beta cannot exit while critical or high findings remain open unless the
release owner and rollback decision maker explicitly accept the risk in the
release candidate record.

