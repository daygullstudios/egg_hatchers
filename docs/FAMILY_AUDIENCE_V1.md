# Nestarium family-audience v1 requirements

Reviewed: 2026-09-07. Source baseline: application `ad7493f`.
Milestone 2 status: requirements identified; product/legal decisions and runtime
controls are still open. This is implementation planning, not legal clearance.
Do not mark the milestone complete or invite an unrestricted child audience based
on this document. The protected test is not proof of parental consent.

## Confirmed direction and launch target

**Owner-confirmed:** ages 8–12 are actively intended players alongside teens and
adults. Keep the approachable animal-collection game and meaningful local play.
Do not relabel it 13+ to avoid this work or assume that advanced child testers
change privacy obligations. The six-milestone finish line remains in force.

**Owner direction, September 7 follow-up:** use Roblox as the age/parent-control
product model. The owner challenged multiplayer deferral; that was an unapproved
recommendation, not an agreed launch decision. Keep multiplayer as a v1 target
and complete its bounded authority/safety work before release. Do not silently
replace it with a solo-only launch. Bot Arena still stays until its removal is
separately approved. Preserve useful local play and the cloud-recovery objective;
local-only child saves would be an explicit scope change, not the default.

Roblox's June 2026 rollout separates age-appropriate game access from communication
permissions, uses stricter defaults for younger players, and provides linked
parent controls. Adopt those principles for Nestarium, including parent control
of relevant child social capabilities, rather than excluding children from all
multiplayer. Roblox uses additional age checks for communication; its account
bands and settings vary by region. Its legal classification, verification provider
and camera/ID collection are not automatically ours. Nestarium remains preset-
message only: do not add open chat, voice or a biometric verification dependency
merely to copy Roblox. Parent-managed means a separate permission/ownership model,
not borrowing an adult's login. Exact consent/age-assurance implementation remains
subject to the review below. [Roblox age-based accounts, June 16, 2026](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available),
[Roblox parent accounts](https://en.help.roblox.com/hc/en-us/articles/30428248050068-Parental-Controls-FAQ)

**Professional review required:** determine whether Nestarium is primarily
child-directed or qualifies for COPPA's mixed-audience subset. Our intended
family audience is evidence, not a legal classification. Mixed audience is not
synonymous with "any game enjoyed by all ages." Age screening can distinguish
users only where that classification and applicable rules allow it. Children
must retain useful play; do not coach them to lie about age. [FTC audience FAQ](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)

## Verified current implementation (source, not a live traffic audit)

- **Automatic identity:** `SaveImportBootstrap._boot` starts cloud connection
  after local import checks. `FirebaseBootstrap.initialize` configures Firebase;
  `FirebaseAnonymousAuthGateway.restoreIdentity` can create an anonymous UID.
  No age/parent-permission gate precedes this path. Firebase documents processing
  of IP addresses and user agents for Authentication; UID-backed play is not
  equivalent to no personal-data processing. Not every field in Firebase's
  generic service inventory is collected by this app. [Firebase privacy](https://firebase.google.com/support/privacy)
- **Automatic core progress sync:** `main.dart::_configureProgressSync` connects
  the selected local player to `FirebaseProgressRepository`. Firestore receives
  the UID, complete core `PlayerState`, revision counters, server time and content
  fingerprint. Current rules enforce UID ownership/revisions, not age, guardian
  authority or consent. The content fingerprint is an integrity tool, not data
  anonymization. Device preferences and custom artwork are separate local data.
- **Automatic lobby attempt:** `main.dart::_syncOnlinePresence` calls
  `OnlineLobbyService.updatePresence`, which connects while disconnected. A
  successful connection sends the serialized local account (ID, display name,
  username, avatar, creation time, guest flag), rating, team and animals.
  `tool/multiplayer_server.dart::_broadcastPresence` shares that payload with
  other connected players. The protected static web deployment does not ship
  this multiplayer server, so this is an attempted connection there, not proof
  that player payloads currently reach a working public lobby.
- **Identity is not child-aware:** `PlayerAccount` has no age band or guardian
  relationship. No parent permission, revocation or age-assessment flow was found
  in the current Flutter app or Firestore rules. Preset-only messages reduce
  risk but do not eliminate risks from free-form names, profiles and discovery.
- **Google linking:** release capability is gated by
  `NESTARIUM_GOOGLE_SIGN_IN_ENABLED` and currently web-only. Native OAuth setup
  remains closed. A provider flag is not an audience/consent gate.
- **Data removal:** current UI explicitly removes local players only. Firestore
  client deletion is denied; there is no implemented parent-managed cloud-erasure
  endpoint. The draft support process is not evidence that end-to-end erasure,
  identity verification, backup expiry or consent revocation has passed.
- **Useful low-collection baseline:** no ad, purchase, Analytics or Crashlytics
  SDK was found in the dependency manifest/lockfile or searched app sources.
  The owned Android manifest declares Internet, not camera/microphone/location/
  advertising-ID permissions. Final merged native manifests, transitive SDK
  behavior and actual network traces remain platform acceptance work, not a
  blanket "collects nothing" claim. The public information-site draft has no
  script, form or tracker; hosting, Access and support still process requests.

## Five bounded requirements to close before the family release

### F1 — Determine eligibility before optional data connections

Define one central privacy capability decision for local play, cloud identity,
save upload, account linking and online presence. Unknown/missing/corrupt status
must not mean adult/consented. Keep local saves playable while optional data
features wait. Gate startup, retries, resume, account switches, deep links and
SDK session restoration, not just the visible Sign in button. Existing UIDs and
local progress must be preserved, never replaced or erased to reset eligibility.
Native SDK auto-initialization and browser asset/CDN/Access requests need their
own review; suppressing a Dart call does not prove zero pre-gate traffic.

If legally appropriate, collect only the minimum age/region information needed
for the decision, neutrally, without an adult default. Avoid retaining full DOB
or collecting ID documents ourselves without an approved necessity/process.
The narrow internal-operations exception for some identifiers is not a blanket
exemption for cloud collections, public profiles or all SDK traffic; counsel must
map any relied-on exception to the specific processing. [FTC FAQ](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)

### F2 — Parent-managed cloud save, with a valid non-Google route

Before enabling child cloud data, choose and verify the notice/consent method,
provider suitability, guardian ownership model and minimum retained evidence.
Provide view/export, revoke and delete controls. Enforce permissions server-side;
an editable local "parent approved" boolean is not authority. A shared device
must not transfer one child's/adult's permission to another profile. Imports and
exports must not import consent or create a new cloud owner.

Do not assume Google Sign-In is available to all intended children or that an
adult login proves guardian consent. Google disallows its account-data APIs in
primarily child-directed apps; mixed-audience apps may offer optional Google
sign-in but must be accessible in their entirety without it. The eventual cloud
recovery route must not make Google the only way to obtain a core feature.
[Google API user-data policy](https://developers.google.com/terms/api-services-user-data-policy)

### F3 — Keep public presence and sharing off until independently ready

Multiplayer remains a v1 target; this is a readiness gate, not a post-release
deferral. Until it passes, do not enable automatic public presence, discoverable
profiles, peer invitations/trades or public art. Preserve the existing multiplayer
code and Bot Arena. Public multiplayer needs authenticated server authority,
child-safe names/discovery, adult social controls, safety notices,
abuse/report/block handling and appropriate consent before disclosure.
Distinguish permission to play a battle from permission to expose a profile,
communicate or trade. Use the bounded multiplayer completion packages in
`PLATFORM_ARCHITECTURE_WORKPLAN.md`, not an unlimited social-platform feature list.
Preset chat alone is insufficient. Google Play's social-feature requirements
cover applicable sharing features, including adult controls and adult action
before children exchange personal information. [Play Families policy](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)

### F4 — Operable notices, retention and deletion

Write disclosures from the final runtime, including hosting/security and support
providers. Record data purpose, recipients, security responsibility, retention
period/trigger and deletion scope for each store (Auth, progress, backups,
consent evidence, support and logs). Do not invent blanket retention promises.
Test verified parent requests/revocation, stopped future uploads, actual cloud
and Auth removal, retry/failure reporting and explained backup/provider retention.
Removing local data alone is not enough.

The FTC's May 2026 guidance requires applicable notice, verifiable parental
consent, parental review/revocation/deletion, written security safeguards and
purpose-limited retention/deletion procedures. Separate permission for qualifying
third-party disclosure must not be bundled without checking the exceptions.
An ordinary checkbox or a parental math gate does not replace these processes.
[FTC compliance plan](https://www.ftc.gov/business-guidance/resources/childrens-online-privacy-protection-rule-six-step-compliance-plan-your-business)

### F5 — Truthful platform and territory acceptance

Owner must select actual launch countries and platforms. Do not treat the US
under-13 boundary as a worldwide rule: the UK Children's Code concerns services
likely accessed by under-18s and high-privacy defaults; other territories and US
state requirements need launch-specific review. [ICO introduction](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/introduction-to-the-childrens-code/)

Prepare Play target-audience, Data safety and content-rating answers from the
candidate, not the desired marketing label. Including children invokes Families
requirements; an age screen is not universally mandatory if the implementation
otherwise avoids prohibited child data collection. [Play Families policy](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)

Apple Kids Category selection and content age rating are separate decisions;
neither waives child-privacy law. Kids Category has additional constraints and
parental gates. Apple explicitly distinguishes a parental gate from legally
valid consent. If accounts are created, include applicable in-app account deletion
requirements in the release review. No category or rating is selected here.
[Apple App Review Guidelines, 1.3 and 5.1](https://developer.apple.com/app-store/review/guidelines/)

## Exact decisions and stopping point

1. **Owner direction recorded:** Roblox-informed age/parent controls and
   multiplayer as a release target. A solo-only release or local-only child save
   boundary would require a separate explicit scope decision; neither is approved.
2. **Owner + qualified child-privacy counsel (or an appropriate reviewed safe
   harbor service):** classify the actual intended/likely audience, select launch
   territories, approve minimum age/region handling, SDK/provider eligibility,
   consent method and operational retention/deletion plan. Signing a support
   account's Cloud terms did not settle these product/legal decisions.
3. **Then implementation:** F1/F2/F4 as one planned family-identity workstream,
   retaining every compatibility identity/save. Complete F3's bounded multiplayer
   work for the release target; keep public exposure off until its gate passes.
   F5 feeds the existing platform/public-readiness milestones.

Acceptance must demonstrate a fresh unknown user makes no optional identity,
sync or lobby calls; a restricted player can complete/save/reopen the local
journey; a valid parent-approved route enables only the permitted cloud data;
denial/revocation/account switch/import cannot bypass the policy; and existing
saves/UIDs survive. Network evidence uses disposable child/test profiles, not real
children's data. Human comprehension belongs to milestone 5. Run focused tests
as code changes, then one normal integration checkpoint for the finished batch.

For this requirements/draft checkpoint: no live settings, cloud data, policies,
providers, domains, store answers or runtime behavior are changed. Draft markers
and existing publication gates remain closed. No full Flutter/release matrix is
needed just to record requirements and correct unpublished copy.
