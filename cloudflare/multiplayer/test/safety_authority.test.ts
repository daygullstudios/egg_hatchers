import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

import {
  capabilityDecisionForUid,
  familyCapabilityPolicyVersion,
  issueCapabilityDecision,
  moderationReportId,
  moderationReportRetentionMs,
  pruneExpiredModerationReports,
  recordModerationReport,
  revokeCapabilityDecision,
  safetyAuthoritySummary,
} from "../src/safety_authority";

describe("central safety authority", () => {
  it("stores idempotent pseudonymous reports and prunes them after retention", async () => {
    const reporterUid = `reporter-${crypto.randomUUID()}`;
    const reportedUid = `reported-${crypto.randomUUID()}`;
    const createdAt = Date.now() - moderationReportRetentionMs - 1;
    const reportDay = new Date(createdAt).toISOString().slice(0, 10);
    const reportId = await moderationReportId(
      reporterUid,
      reportedUid,
      "trade_concern",
      reportDay,
    );
    const input = {
      reportId,
      sourceGeneration: "test-v1",
      sourcePool: "test-v1-shard-00",
      reporterUid,
      reportedUid,
      reason: "trade_concern",
      contextType: "trade" as const,
      contextId: "trade-test",
      reportDay,
      createdAt,
    };
    await expect(recordModerationReport(env.SAFETY_AUTHORITY, input)).resolves.toBe(true);
    await expect(recordModerationReport(env.SAFETY_AUTHORITY, input)).resolves.toBe(false);
    const serialized = JSON.stringify(
      await env.SAFETY_AUTHORITY.prepare(
        "SELECT * FROM moderation_reports WHERE report_id = ?",
      )
        .bind(reportId)
        .first(),
    );
    expect(serialized).not.toContain(reporterUid);
    expect(serialized).not.toContain(reportedUid);
    await expect(pruneExpiredModerationReports(env.SAFETY_AUTHORITY)).resolves.toBeGreaterThanOrEqual(1);
  });

  it("issues, expires, and revokes bounded capability decisions", async () => {
    const uid = `capability-${crypto.randomUUID()}`;
    const now = Date.now();
    const input = {
      decisionId: `decision-${crypto.randomUUID()}`,
      policyVersion: familyCapabilityPolicyVersion,
      decision: "allow" as const,
      onlineBattle: true,
      trading: true,
      presetMessages: true,
      profileDiscovery: false,
      reviewReference: "test-review-1",
      expiresAt: now + 60_000,
    };
    await expect(
      issueCapabilityDecision(env.SAFETY_AUTHORITY, uid, input, now),
    ).resolves.toMatchObject({
      status: "allowed",
      capabilities: { onlineBattle: true, trading: true },
      revision: 1,
    });
    await expect(
      capabilityDecisionForUid(env.SAFETY_AUTHORITY, uid, now + 60_000),
    ).resolves.toMatchObject({ status: "expired", capabilities: { trading: false } });
    await expect(
      revokeCapabilityDecision(
        env.SAFETY_AUTHORITY,
        uid,
        "test-revoke-1",
        now + 1,
      ),
    ).resolves.toMatchObject({ status: "revoked", revision: 2 });
    const serialized = JSON.stringify(
      await env.SAFETY_AUTHORITY.prepare(
        "SELECT * FROM capability_decisions WHERE decision_id = ?",
      )
        .bind(input.decisionId)
        .first(),
    );
    expect(serialized).not.toContain(uid);
    await expect(safetyAuthoritySummary(env.SAFETY_AUTHORITY, now)).resolves.toMatchObject({
      revokedCapabilityDecisions: expect.any(Number),
    });
  });
});
