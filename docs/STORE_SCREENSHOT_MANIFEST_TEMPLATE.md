# Store screenshot manifest template

Use this template only after launch platforms and countries are chosen and a
release candidate is frozen. It does not approve store submission or public
launch. This screenshot manifest does not approve store submission or public launch.

## Candidate

- Candidate Git commit:
- Version name/build number:
- Selected launch platforms:
- Selected launch countries:
- Screenshot capture date:
- Screenshot capture owner:
- Release owner:

## Capture Rules

- Capture only the exact release candidate build.
- Hide developer-only controls before capture.
- Do not use Cloudflare temporary tunnel URLs in screenshots.
- Do not show private tester names, emails, account identifiers, support
  messages, save JSON, authentication tokens or private Save Transfer files.
- Do not show unapproved future-event art, unreleased monetization, public
  custom-art sharing, open chat or Bot Arena removal promises.
- Use ordinary fresh accounts unless a returning/import screenshot is explicitly
  needed.
- Recheck narrow-phone layout before using any phone screenshot.

## Required Screenshot Rows

Copy one row for each screenshot.

```text
Screenshot ID:
Store/platform target:
Device/browser/OS:
Viewport or device size:
Screen or flow:
Candidate commit:
Build artifact:
Player/account fixture:
Private data check passed: yes/no
Developer tools hidden: yes/no
Future-event/monetization claims absent: yes/no
Accessibility/text-scale check:
Approved for store draft: yes/no
Evidence file or storage location:
Notes:
```

## Required Coverage

- Hatchery first-player flow.
- Egg Shop.
- Collection and fusion.
- Manual boss fight.
- Online Arena or hosted playtest state, if online play is selected.
- Trading and preset-message communication, if online play is selected.
- Settings account/save controls.
- Narrow phone layout.
- Tablet layout, if selected.
- Desktop/web layout, if selected.

## Exit Rule

Store screenshots are not release-ready until every selected store has a
complete screenshot set, every row passes the private-data check, and the
release candidate record cites this manifest.

