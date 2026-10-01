# Nestarium account recovery release evidence

Updated: 2026-10-01

This records the current release evidence for cross-device account recovery.
The approved in-app recovery path is Google protection for guest progress,
backed by the versioned Save Transfer file for manual migration and emergency
backup. This does not replace the remaining production environment, privacy,
family capability or account-deletion release gates.

## Recovery behavior

- Guest play starts with a device guest identity and local-first progress.
- The player can connect Google without changing progress when Google returns
  the same player identity.
- If Google opens an existing protected identity, the app clears stale local
  sync ancestry and requires explicit save comparison before applying cloud
  progress.
- A clean second device or browser can restore the Google identity, compare the
  local starter save to cloud progress and apply the cloud copy only after an
  explicit player choice.
- Save Transfer remains readable for versioned JSON migration, including old
  files containing dormant custom eggs, but it does not import foreign identity
  or cloud ancestry.

## Regression evidence

- `test/account_protection_service_test.dart`
  - Linking Google preserves the anonymous UID and sync ancestry when the
    provider returns the same player.
  - Opening an existing Google account clears old sync ancestry.
  - Google protection is single-flight while the provider is open.
  - A replacement guest receives a fresh identity after local removal.

- `test/cross_device_recovery_test.dart`
  - Existing identity recovery on a clean device requires a choice and preserves
    cloud progress until the player chooses the cloud copy.
  - Guest Google linking preserves the same player and cloud document, including
    the protected cloud document id used by progress sync.

- `test/save_transfer_service_test.dart`
  - Save Transfer review and staging never replace existing players or the
    active session.
  - Supported settings are restored without importing foreign identity or cloud
    ancestry.
  - Legacy files with dormant custom eggs remain importable while custom eggs
    stay unplayable.

## Remaining release gates

The recovery path is implemented and regression-tested, but the wider release
still needs:

- Complete cloud-account deletion where required.
- The full account-switch, deletion, offline, conflict and corrupt-save matrix.
- Production trusted authentication sessions.
- Family/privacy review and approved capability controls.
- Two-device internet play outside the developer network.
