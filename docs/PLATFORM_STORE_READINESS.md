# Platform Store Readiness

Updated: 2026-10-07

This record supports the roadmap section "Platform and store readiness." It
does not select a launch platform or close any signing/store item. It records
what is already prepared and what must happen after the owner chooses web,
Android and/or iOS.

## Current platform status

- Web is the most mature target. The public information site and protected
  playtest have separate Cloudflare routes.
- Android source is present and has a release-signing hook in
  `android/app/build.gradle.kts`.
- iOS source is present, but signing, App Store Connect setup, and real-device
  testing still need the Mac/App Store path.
- Signed/archived candidate inspection should be recorded with
  `docs/PLATFORM_BUILD_INSPECTION_TEMPLATE.md` after platform selection.

## Android readiness

The Android Gradle file reads a private `android/key.properties` file when it
exists and otherwise falls back to debug signing for local release builds.

Prepared files:

- `android/app/build.gradle.kts`
- `android/key.properties.example`
- `android/.gitignore`

Credential protection:

- `android/key.properties` is ignored.
- `**/*.keystore` is ignored.
- `**/*.jks` is ignored.

Android remains blocked until an owner-selected Android release creates a real
upload keystore, stores credentials outside Git, and inspects a signed App
Bundle.

## iOS readiness

The iOS project exists at `ios/Runner.xcodeproj/project.pbxproj` with automatic
signing source settings and bundle identifiers. It is not a release-ready iOS
candidate until a Mac/App Store path supplies:

- Apple Developer Team selection.
- App Store Connect app record.
- Real-device testing.
- Privacy Nutrition answers from the final candidate behavior.
- Archive/export evidence for the release candidate record.

## Store disclosure blockers

Store metadata and disclosure work must wait for selected launch platforms and
launch countries. The release candidate record must cite the final source for:

- Store name, description, screenshots, ratings and disclosures.
- Store screenshot manifest from `docs/STORE_SCREENSHOT_MANIFEST_TEMPLATE.md`.
- Google Play Data Safety, if Android is selected.
- Apple privacy answers, if iOS is selected.
- Support and account-deletion links from every selected store.

