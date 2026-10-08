# Platform build inspection template

Use this template only after Android and/or iOS is selected and a signed or
archived release candidate build exists. It does not create credentials, select
platforms, approve store submission or approve public launch.

## Inspection Identity

- Candidate Git commit:
- Version name/build number:
- Selected launch platforms:
- Selected launch countries:
- Release owner:
- Build operator:
- Credential owner:
- Inspection date:

## Android App Bundle Inspection

Fill this section only if Android is selected.

- App Bundle path:
- App Bundle checksum:
- Package name:
- Version name:
- Version code:
- Signing status:
- Upload key fingerprint reference:
- App label:
- App icon check:
- Supported architectures:
- Permissions review:
- Google Play Data Safety source:
- Support/account-deletion link verification:
- Secrets absent from artifact notes/logs: yes/no
- Result: Pass / Fail / Deferred
- Evidence link or notes:

## iOS Archive Inspection

Fill this section only if iOS is selected.

- Archive/build identifier:
- Bundle identifier:
- Version/build:
- Signing team:
- Provisioning profile reference:
- Entitlements review:
- App label:
- App icon check:
- Privacy-sensitive capabilities:
- Real-device test result:
- Apple privacy answers source:
- Support/account-deletion link verification:
- Secrets absent from artifact notes/logs: yes/no
- Result: Pass / Fail / Deferred
- Evidence link or notes:

## Shared Stop Conditions

Keep the platform/store roadmap items open if any of these occur:

- The build was created from a dirty working tree.
- Package name, bundle identifier, version, icon or app label is wrong.
- Signing status cannot be verified.
- A permission, entitlement or privacy-sensitive capability is unexplained.
- Store privacy answers do not match the inspected candidate.
- Support or account-deletion links fail from the selected store draft.
- Keystore passwords, certificates, provisioning profiles, API tokens, account
  credentials or other secrets appear in Git, chat, screenshots, logs or public
  artifacts.
- A failed or deferred inspection lacks a fix commit, accepted-risk reference
  and focused retest result.

