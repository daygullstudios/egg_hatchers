# Platform audio behavior matrix

Use this matrix only for a frozen release candidate and the selected launch
platforms. It does not approve shipped audio, music rights or public launch by
itself.

## Candidate

- Candidate Git commit:
- Version name/build number:
- Selected launch platforms:
- Selected launch countries:
- Release owner:
- Audio reviewer:
- Review date:

## Platform Rows

Copy one row for each selected platform/browser/device combination.

```text
Platform/browser/device:
Build artifact or URL:
First user tap unlocks audio:
Hatchery music starts and loops:
Normal boss phase 1 starts at 0:00 and loops in range:
Boss-life hit advances to the next phase without restarting at 0:00:
Each boss phase loops inside its approved BandLab red range:
Rotten Shell final boss music starts and stops correctly:
Music slider changes volume without reload:
SFX slider changes volume without reload:
Music mute persists after refresh/restart:
SFX mute persists after refresh/restart:
Pause/resume does not stack duplicate music:
Background/foreground behavior acceptable:
Reduced Battle Effects keeps critical audio feedback:
Default mix comfortable for music, UI, rewards, hits and cinematics:
Result: Pass / Fail / Deferred
Evidence link or notes:
```

## Required Coverage

- Web browser path, if web is selected.
- Android app path, if Android is selected.
- iOS app path, if iOS is selected.
- Narrow phone layout with audio controls.
- At least one manual boss battle that removes every boss life.
- Settings music/SFX slider and mute persistence after refresh or restart.
- Background/foreground or tab visibility behavior for every selected platform.

## Stop Conditions

Keep the release audio roadmap items open if any of these occur:

- Audio needs more than the first user tap to unlock on web.
- A boss phase restarts at `0:00` after a life hit.
- A boss phase loops outside its approved BandLab red range.
- Music or SFX is painfully loud at default volume.
- Slider or mute settings fail to persist.
- Pause/resume stacks duplicate music.
- Background/foreground behavior breaks music playback.
- Reduced Battle Effects hides critical audio feedback.
- A failed or deferred row lacks a fix commit, accepted-risk reference and
  focused retest result.

