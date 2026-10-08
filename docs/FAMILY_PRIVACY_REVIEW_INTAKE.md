# Nestarium family/privacy review intake

Updated: 2026-10-08

This intake packet prepares the professional family/privacy review required by
`docs/RELEASE_ROADMAP.md`. It is not legal clearance, launch approval, store submission approval,
or approval to collect child data. Keep all related roadmap items open until the
reviewer-approved decisions are implemented, tested, and recorded against a
frozen release candidate.

## Review identity

- Reviewer or review service: TBD
- Review owner: TBD
- Release owner: TBD
- Rollback decision maker: TBD
- Candidate commit reviewed: TBD
- Launch platforms reviewed: TBD
- Launch countries reviewed: TBD
- Policy version reviewed: TBD

## Product audience to review

The owner intends Nestarium for ages 8-12, teens, and adults. The review must
decide how that intended family audience should be classified for the selected
launch countries and platforms. Do not relabel the game as 13+ without an
explicit owner scope change.

Current product facts:

- Core local play includes hatching, collection, upgrades, rebirths, quests,
  fusion, manual boss fights, Bot Arena, visual styles, and Save Transfer.
- Online capabilities include cloud save recovery, online presence, direct
  battle invitations, online battles, trading, collection viewing, blocking,
  reporting, and preset-message communication.
- Player communication remains preset-only; open text chat, voice chat, and
  public custom-art sharing are excluded from 1.0.
- Custom animal sprites are local to the device.
- Custom eggs are retired and legacy records remain readable but not playable.
- Monetization remains dormant unless the separate monetization operations plan
  is completed.

## Data and capability questions

The reviewer must answer:

- Which age bands are allowed to use local play, cloud save, profile discovery,
  online battles, trading, collection viewing, preset messages, reports, and
  account deletion?
- What age/region question may be asked, how it should be worded, and whether
  the answer may be stored?
- What guardian consent or parent-managed permission process is required before
  cloud save, online presence, battle invitations, trading, preset messages, or
  account linking?
- Which capabilities require separate guardian permissions rather than one
  bundled approval?
- What data may be retained for consent evidence, support, moderation reports,
  backups, Worker logs, and account deletion?
- What retention windows and deletion triggers apply to each data store?
- What support process may verify a parent/guardian request without collecting
  unnecessary identity documents?
- What disclosures are required in Privacy Policy, Terms, support pages, store
  listings, Google Play Data Safety, and Apple privacy answers?
- Whether Google Sign-In may be offered to the intended audience and what
  non-Google recovery route is required.
- Whether any client telemetry or crash SDK may be added. The current candidate
  deliberately has no `firebase_crashlytics`, `firebase_analytics`,
  `sentry_flutter`, App Center, Mixpanel, or Amplitude dependency.

## Current technical evidence

Give the reviewer these files:

- `docs/FAMILY_AUDIENCE_V1.md`
- `docs/RELEASE_FAMILY_CAPABILITY_EVIDENCE.md`
- `docs/PUBLIC_POLICY_READINESS.md`
- `docs/RELEASE_DECISION_PACKET.md`
- `docs/MULTIPLAYER_PRODUCTION_ACCEPTANCE.md`
- `docs/RELEASE_SECURITY_REVIEW.md`
- `docs/RELEASE_MONITORING_EVIDENCE.md`
- `docs/RELEASE_OPERATIONS_EVIDENCE.md`
- `docs/MONETIZATION_AND_AD_OPERATIONS.md`
- `docs/CLOSED_BETA_TESTER_PACKET.md`

Current safeguards to verify:

- Hosted capabilities fail closed when policy claims are missing, stale,
  expired, revoked, or denied.
- Battle, trading, preset-message, and profile-discovery capabilities are
  separate server-side decisions.
- Profile discovery is not approved in family policy v1.
- Preset messages require the approved capability and remain preset-only.
- Reports use bounded preset reasons and pseudonymous retention.
- Blocks prevent battle and trade matching until removed by the owner.
- The public information site is separated from the protected playtest game.
- Client analytics and crash telemetry SDKs are absent until review approves a
  privacy-safe model.

## Required reviewer output

The review must produce:

- Audience classification for each selected launch country/platform.
- Approved age/region handling text and storage rules.
- Approved guardian consent or parent-managed permission flow.
- Capability matrix for local play, cloud save, online presence, battle,
  trading, collection viewing, preset messages, reports, and deletion.
- Data inventory with purpose, recipients, retention window, deletion trigger,
  support access, and backup handling.
- Public policy and store disclosure requirements.
- Support/account-deletion verification process.
- Monitoring/logging boundary.
- Accepted risks, if any.
- Reviewer approval date and owner sign-off.

Record the reviewer answers in
`docs/FAMILY_PRIVACY_REVIEW_RESPONSE_TEMPLATE.md` or a dated copy of that
template. The filled response must be cited by the release candidate record
before family/privacy roadmap items can close.

## Acceptance evidence after implementation

Do not close the roadmap family/privacy items until tests or release evidence
prove:

- A fresh unknown user makes no optional cloud identity, sync, lobby, trading,
  messaging, or profile-discovery call before the approved eligibility decision.
- A restricted player can complete, save, reopen, export, and import the local
  journey.
- A parent-approved route enables only the capabilities approved for that player.
- Denial, revocation, account switch, import, refresh, and reconnect cannot
  bypass the policy.
- Existing saves, device guests, linked cloud accounts, and Save Transfer files
  survive migration to the approved model.
- Parent review, revocation, deletion, support, and backup-retention behavior
  match the approved public policy.
- Store/privacy answers match the exact candidate behavior.

## Stop conditions

Do not invite an unrestricted family audience, route a public playable host, or
submit to stores if any of these remain unresolved:

- Launch countries or platforms are not chosen.
- Audience classification is not approved.
- Guardian or parent-managed control flow is not approved.
- Retention and deletion rules are not approved.
- Candidate Privacy Policy, Terms, support, and store disclosure copy are not
  approved.
- Public multiplayer or trading can expose a player without approved capability
  claims.
- Monitoring or support processes require private data beyond the approved
  boundary.
