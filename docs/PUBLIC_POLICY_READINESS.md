# Public Policy Readiness

Updated: 2026-10-07

This record supports the roadmap item "Publish candidate-accurate Privacy
Policy, Terms and support instructions." It does not close that item because
the final public game candidate, launch countries, family/privacy review, and
store disclosures are still not approved.

## Existing public pages

The public information site source lives in `cloudflare/public-site/src/` and
currently includes:

- `privacy.html`
- `terms.html`
- `support.html`
- `delete-account.html`

Those pages describe the current public information website and private test.
They must be reviewed again before a playable public release, store submission,
or any change to selected launch countries, because updated disclosures before launch
must reflect the final candidate behavior.

## Release gate coverage

`cloudflare/public-site/verify-release.mjs` blocks publication unless these
readiness gates are true in `cloudflare/public-site/release-readiness.json`:

- `audienceDecisionRecorded`
- `policyAndSupportCopyApproved`
- `supportDeliveryAndReplyVerified`
- `hostnameAndHeadersVerified`

The public site test suite also verifies that:

- The output contains only the public information pages and approved static
  assets, not the playable game bundle.
- Local links resolve.
- Mail links use only approved role addresses.
- No scripts, forms, trackers, credentials, playtest links, or Flutter bundles
  are published.
- Support and privacy pages explain current recovery, deletion, and family
  boundaries.
- The public apex route is distinct from the protected playtest game route.

## Remaining release-candidate work

- Confirm launch platforms and launch countries.
- Complete professional family/privacy review.
- Update Privacy Policy, Terms, support, deletion, and store disclosure copy
  from the final candidate behavior.
- Confirm role-address delivery and reply ownership.
- Verify the support/account-deletion links from every selected store.
- Record the exact policy versions in the release candidate record.

