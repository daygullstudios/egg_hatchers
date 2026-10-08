# Store Listing Draft Checklist

Updated: 2026-10-08

Use this checklist after launch platforms and countries are chosen. It prepares
store metadata and disclosures, but it does not select Android or iOS, create a
signed build, approve public launch, or close any platform/store roadmap item.

## Required Owner Decisions

- First release platforms: web, Android and/or iOS.
- First launch countries.
- Release owner.
- Rollback decision maker.
- Family/privacy review path and final audience position.
- Monetization stays dormant unless its separate operations plan is complete.

## Listing Copy

Prepare candidate-accurate copy from the exact release build:

- App name: Nestarium.
- Short description.
- Full description.
- Feature list that matches the release scope.
- Support URL.
- Privacy Policy URL.
- Terms URL.
- Account deletion/support URL.
- Copyright/developer name.
- Contact email.

Do not promise public multiplayer removal of Bot Arena, future events,
Corruption 3D battles, premium currency, ads, paid randomized rewards, or launch
dates unless those features are in the approved release candidate.

## Screenshot And Media Set

Capture only the approved release candidate with developer tools hidden:

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

Record the screenshot set in `docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md` with
the candidate commit, build artifact, device/browser/OS, private-data check,
developer-tools check and evidence file or storage location for every image.

Screenshots must not show private tester names, emails, account identifiers,
debug URLs, Cloudflare temporary tunnels, real support messages, save JSON,
developer-only controls or unapproved future-event art.

## Ratings And Content Disclosures

Record evidence for each selected platform:

- Intended audience and family/privacy review reference.
- Preset-message-only communication.
- User-generated custom animal sprites are local to the device and are not
  public sharing.
- Online battles and trading are server-authorized.
- Ads and paid randomized rewards are dormant for this release unless a
  separate approved monetization plan activates them.
- Support and account-deletion paths are reachable from the selected store.

## Platform Privacy Answers

Google Play Data Safety and Apple privacy answers must come from the exact
candidate behavior, not from old plans. Use these source records:

- `docs/PUBLIC_POLICY_READINESS.md`
- `docs/FAMILY_AUDIENCE_V1.md`
- `docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md`
- `docs/RELEASE_MONITORING_EVIDENCE.md`
- `docs/RELEASE_OPERATIONS_EVIDENCE.md`
- `docs/MONETIZATION_AND_AD_OPERATIONS.md`

Do not add client analytics, Crashlytics, Sentry, open chat, public custom-art
sharing, or extra data collection just to fill store forms.

## Pre-Submission Verification

Before store submission, record in the release candidate record:

- Selected platform rows from
  `docs/CROSS_PLATFORM_ACCEPTANCE_MATRIX_TEMPLATE.md`.
- Android signed App Bundle path/checksum, if Android is selected.
- iOS archive/build identifier and real-device test result, if iOS is selected.
- Store copy source version.
- Screenshot capture commit and device list.
- Store Data Safety or Privacy Nutrition answer source.
- Support/account-deletion URL verification result.
- Owner approval for store submission.

Keep the roadmap platform/store items open until this checklist is filled for
the exact candidate and the selected stores accept the required metadata.
