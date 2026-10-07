import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public policy readiness documents current public pages and gates', () {
    final evidence = File('docs/PUBLIC_POLICY_READINESS.md').readAsStringSync();
    final readiness = jsonDecode(
      File('cloudflare/public-site/release-readiness.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final verifier = File(
      'cloudflare/public-site/verify-release.mjs',
    ).readAsStringSync();

    for (final page in [
      'privacy.html',
      'terms.html',
      'support.html',
      'delete-account.html',
    ]) {
      expect(evidence, contains(page), reason: page);
      expect(File('cloudflare/public-site/src/$page').existsSync(), isTrue);
    }

    for (final gate in [
      'audienceDecisionRecorded',
      'policyAndSupportCopyApproved',
      'supportDeliveryAndReplyVerified',
      'hostnameAndHeadersVerified',
    ]) {
      expect(evidence, contains(gate), reason: gate);
      expect(readiness[gate], isTrue, reason: gate);
      expect(verifier, contains(gate), reason: gate);
    }
  });

  test('public policy readiness remains tied to final release blockers', () {
    final evidence = File('docs/PUBLIC_POLICY_READINESS.md').readAsStringSync();
    final roadmap = File('docs/RELEASE_ROADMAP.md').readAsStringSync();
    final template = File(
      'docs/RELEASE_CANDIDATE_RECORD_TEMPLATE.md',
    ).readAsStringSync();
    final siteTest = File('cloudflare/public-site/site.test.mjs').readAsStringSync();

    expect(
      roadmap,
      contains('[ ] Publish candidate-accurate Privacy Policy, Terms and support instructions.'),
    );
    expect(template, contains('Candidate Privacy Policy URL/version'));
    expect(template, contains('Candidate Terms URL/version'));
    expect(template, contains('Support/account-deletion URL'));

    for (final phrase in [
      'final public game candidate',
      'launch countries',
      'family/privacy review',
      'store disclosures',
      'support/account-deletion links',
    ]) {
      expect(evidence, contains(phrase), reason: phrase);
    }

    expect(siteTest, contains('no scripts, forms, trackers'));
    expect(siteTest, contains('support and privacy explain current recovery'));
    expect(siteTest, contains('release gate approves only the public apex'));
  });
}

