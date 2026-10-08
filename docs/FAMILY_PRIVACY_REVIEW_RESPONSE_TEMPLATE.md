# Family privacy review response template

Use this template only after a qualified reviewer or approved review service has
completed the family/privacy review for the selected launch countries,
platforms, candidate behavior and policy copy. It is not legal clearance unless
the reviewer and release owner explicitly say so in the filled response.

## Review Identity

- Reviewer or review service:
- Reviewer role/qualification:
- Review owner:
- Release owner:
- Rollback decision maker:
- Candidate commit reviewed:
- Launch platforms reviewed:
- Launch countries reviewed:
- Privacy Policy version reviewed:
- Terms version reviewed:
- Support/account-deletion instructions reviewed:
- Review date:

## Audience Classification

Record the reviewer-approved classification for each selected country/platform:

```text
Country/region:
Platform:
Audience classification:
Age bands allowed for local play:
Age bands allowed for optional online/data features:
Mixed-audience handling approved: yes/no/not applicable
Kids/family store category impact:
Notes:
```

## Approved Capability Matrix

Record the approved rule for each capability and age/permission state.

```text
Capability:
Allowed for unknown user:
Allowed for restricted child:
Allowed after parent/guardian approval:
Allowed for teen:
Allowed for adult:
Server-side claim required:
Separate guardian permission required:
Revocation behavior:
Evidence/test required:
```

Required capabilities to cover:

- Local play.
- Cloud save and cloud restore.
- Account linking and non-Google recovery.
- Online presence and profile discovery.
- Direct battle invitations and online battles.
- Trading and collection viewing.
- Preset messages.
- Reports and blocked-player controls.
- Support and account deletion.

## Age And Guardian Flow

- Approved age/region question text:
- Whether the answer may be stored:
- Minimum data retained for consent or eligibility evidence:
- Parent/guardian verification process:
- Parent-managed permission review process:
- Revocation process:
- Deletion request process:
- Support verification boundary:
- Non-Google recovery route:

## Data Inventory And Retention

For each store, record purpose, recipients, retention and deletion:

```text
Data store:
Data categories:
Purpose:
Recipients/processors:
Retention window:
Deletion trigger:
Backup handling:
Support access:
Parent review/export path:
```

Required stores to cover:

- Local save and settings.
- Firebase Authentication.
- Firestore progress/cloud save.
- Multiplayer Worker presence and session data.
- D1 safety reports, blocks and capability claims.
- Worker observability logs.
- Support inbox and account-deletion records.
- Release backups and restore artifacts.

## Public Policy And Store Disclosures

- Privacy Policy changes required:
- Terms changes required:
- Support instructions changes required:
- Google Play Data Safety answers:
- Apple privacy answers:
- Store rating/category impact:
- Screenshot/listing restrictions:
- Monitoring/logging disclosure:
- Monetization disclosure:

## Accepted Risks And Launch Blocks

- Accepted risks:
- Required implementation changes before beta:
- Required implementation changes before public launch:
- Required tests before beta:
- Required tests before public launch:
- Store/platform actions blocked until changes are complete:
- Reviewer approval date:
- Release owner sign-off:

## Stop Conditions

Do not close family/privacy roadmap items if:

- Audience classification is incomplete for any selected country or platform.
- Any optional online/data capability lacks an approved age/guardian rule.
- Parent review, revocation, deletion or support verification is undefined.
- Retention windows or backup deletion behavior are undefined.
- Public policy or store answers do not match the approved runtime behavior.
- Existing saves, linked accounts or Save Transfer files have no migration plan.
- The release candidate record does not cite this filled review response.

