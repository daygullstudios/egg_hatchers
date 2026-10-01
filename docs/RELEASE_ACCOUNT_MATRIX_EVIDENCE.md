# Nestarium account matrix release evidence

Updated: 2026-10-01

This records the current automated release evidence for the account-switch,
local deletion, offline, conflict and corrupt-save matrix. This matrix covers
the implemented local-player and protected-save behavior. It does not claim
cloud-account erasure is complete; that remains a separate release gate.

## Account switching

- `test/account_service_test.dart`
  - Multiple local profiles can be selected independently.
  - Account save slots preserve progress independently.
  - Deleting one profile leaves other profiles available.

- `test/account_onboarding_screen_test.dart`
  - Account picker selects between saved profiles.
  - Picker cancellation and removal preserve another player and settings.
  - Account onboarding creates the first player profile without replacing an
    existing save.

- `test/settings_account_test.dart`
  - Settings shows and switches the active account.

## Local deletion

- `test/account_service_test.dart`
  - Deleting the only guest immediately creates a fresh guest slot.
  - Failed profile removal keeps the existing player directory.
  - Profile removal deletes progress only after directory commit.

- `test/settings_account_test.dart`
  - Local removal cancels safely and preserves other players.
  - The UI says `Cloud data and sign-in accounts are not deleted.`

- `test/account_scoped_storage_test.dart`
  - Deleting an account removes account-scoped custom content.

- `test/save_service_test.dart`
  - Deleting an account removes its primary and backup saves.

## Offline startup and cloud uncertainty

- `test/offline_startup_test.dart`
  - Valid local players can open and save with hanging or failed Firebase
    startup.
  - Hanging identity does not block local play.
  - Late identity cannot bind after generation.

- `test/progress_sync_service_test.dart`
  - Unknown cloud never authorizes an upload.
  - Local save failure invalidates review but preserves the unresolved cloud
    choice.
  - Import pause drains a late cloud read without upload or restore.

## Conflict review

- `test/progress_conflict_dialog_test.dart`
  - Comparison and confirmation remain usable across narrow, enlarged-text and
    desktop layouts.
  - Only final device or cloud confirmation replaces progress.
  - Changed cloud shows Retry without overwriting either save.
  - Loading can be cancelled without applying the late result.

- `test/progress_sync_service_test.dart`
  - Changed cloud blocks reviewed device or cloud replacement.
  - A cloud revision race keeps the choice without automatic retries.
  - Player switch during a reviewed choice is isolated.

## Corrupt-save recovery

- `test/progress_recovery_test.dart`
  - Storage outages surface `storageUnavailable`.
  - Unsupported envelopes and malformed containers cannot become legacy saves.
  - Interrupted backup restore can resume or cancel without losing originals.
  - Runtime corruption blocks autosave and cloud replacement.

- `test/progress_recovery_ui_test.dart`
  - Damaged primary progress pauses the app and keeps the original data.
  - Runtime damage replaces gameplay with the recovery screen.

- `test/unsaved_progress_test.dart`
  - Failed live saves freeze mutation, cloud acknowledgement, import and player
    switching until retry.

## Remaining release gates

- Complete cloud-account deletion where required.
- Finish family/privacy review and parent-managed review, revocation and
  deletion controls.
- Prove the selected production account provider and support flow can satisfy
  the store account-deletion requirements.
