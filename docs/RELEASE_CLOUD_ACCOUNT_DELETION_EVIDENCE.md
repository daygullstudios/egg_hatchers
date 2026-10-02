# Nestarium cloud-account deletion release evidence

Updated: 2026-10-01

This records the current automated release evidence for complete cloud-account
deletion where the active provider permits deletion from the signed-in client.
The flow is intentionally separate from local player removal.

## Player-facing controls

- `lib/screens/settings_screen.dart`
  - Protected players see `Delete cloud account`.
  - The confirmation dialog explains that the Nestarium cloud account and synced
    cloud progress are deleted: `The local player stays on this device`.
  - The existing `Remove local player` action remains local-only.

- `test/settings_account_test.dart`
  - `protected player can delete cloud account from settings`.
  - Verifies the confirmation dialog, deletion call and return to local-only
    protection state.

## Cloud identity and progress erasure

- `lib/services/account_protection_service.dart`
  - `deleteCloudAccount` is single-flight with other identity operations.
  - Deletion requires the selected local player, bound Firebase UID and active
    protected identity to match.
  - On success it clears sync ancestry and the device UID binding while leaving
    local gameplay progress intact.
  - Success reports `Cloud account deleted. This local player remains on this device`.
  - On failure it preserves the protected identity binding and reports that
    `Cloud account deletion failed. Nothing local was removed.`

- `lib/services/firebase_anonymous_auth_gateway.dart`
  - Implements `deleteProtectedAccount`.
  - Deletes the Nestarium Firestore progress document at
    `users/{uid}/products/egg_hatchers`.
  - The implementation targets `doc('egg_hatchers')` before calling
    `user.delete()`.
  - Deletes the active Firebase Authentication user only when its UID matches
    the expected protected player id.

- `test/account_protection_service_test.dart`
  - `cloud account deletion clears identity binding and sync ancestry`.
  - `failed cloud deletion keeps protected identity binding`.

## Remaining release dependencies

- The final public support and store text still needs to be checked against the
  selected launch platforms.
- Provider reauthentication prompts must be verified on the final web/Android
  and/or iOS candidates.
