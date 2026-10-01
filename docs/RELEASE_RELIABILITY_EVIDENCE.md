# Nestarium reliability release evidence

Updated: 2026-10-01

This records the current automated evidence for the release-roadmap reliability
gate covering slow startup, offline play, interrupted saves and service
outages. It is not approval to launch; it is evidence that this slice of the
candidate has repeatable regression coverage.

## Slow and offline startup

- `test/offline_startup_test.dart`
  - Slow storage checks explain the wait without a bypass or overlapping retry.
  - Slow local-player loading shows scrollable guidance and does not start
    identity work early.
  - Slow cloud initialization is single-flight, accepts late success and
    suppresses notifications after dispose.
  - Valid local players can open and save with hanging or failed Firebase
    startup.
  - Hanging identity does not block local play, and late success binds the same
    player.

## Interrupted and uncertain saves

- `test/unsaved_progress_test.dart`
  - Failed live saves freeze mutation, cloud acknowledgement, import and player
    switching until retry.
  - Slow writes are single-flight and keep the latest coalesced in-memory
    progress.
  - Failed write positions are retriable without losing the previous primary or
    backup copy.
  - Stale retries and stale loaded players cannot overwrite newer primary saves.
  - Queued writes serialize backup rotation and revision increments.

## Damaged progress and recovery

- `test/progress_recovery_test.dart`
  - Autosave preserves the fresh primary as backup instead of using stale cache.
  - Storage outages surface `storageUnavailable` instead of inventing an empty
    save.
  - Unsupported envelopes and malformed containers cannot become legacy saves.
  - Interrupted backup restore can resume or cancel without losing originals.
  - Stale previews and changed copies fail closed.
  - Runtime corruption blocks autosave and cloud replacement.

- `test/progress_recovery_ui_test.dart`
  - Damaged primary progress pauses the app, keeps the original data and allows
    retry.
  - Backup review and confirmation fit narrow and enlarged-text screens.
  - Runtime damage replaces gameplay with the recovery screen instead of saving
    over damage.

## Settings and import safety

- `test/settings_persistence_test.dart`
  - Read outages do not mutate storage or manufacture saved defaults.
  - Slow settings writes show guidance without retry overlap.
  - Import is refused before writers are paused.

## Verification checkpoint

On 2026-10-01, the full Flutter suite passed with 840 tests after adding the
legacy Save Transfer candidate evidence. This reliability evidence remains tied
to the release candidate by `test/release_reliability_evidence_test.dart`.
