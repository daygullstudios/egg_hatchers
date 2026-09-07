import type { SessionCapabilities } from "./auth";

export const familyCapabilityPolicyVersion = 1;
export const moderationReportRetentionMs = 180 * 24 * 60 * 60 * 1000;
const maximumCapabilityLifetimeMs = 366 * 24 * 60 * 60 * 1000;

const deniedCapabilities: SessionCapabilities = {
  onlineBattle: false,
  profileDiscovery: false,
  presetMessages: false,
  trading: false,
};

export type ModerationReportInput = {
  reportId: string;
  sourceGeneration: string;
  sourcePool: string;
  reporterUid: string;
  reportedUid: string;
  reason: string;
  contextType: "battle" | "trade";
  contextId: string;
  reportDay: string;
  createdAt: number;
};

export type CapabilityDecisionInput = {
  decisionId: string;
  policyVersion: number;
  decision: "allow" | "deny";
  onlineBattle: boolean;
  trading: boolean;
  presetMessages: boolean;
  profileDiscovery: boolean;
  reviewReference: string;
  expiresAt: number;
};

export type CapabilityDecisionStatus = {
  subjectHash: string;
  status: "missing" | "allowed" | "denied" | "expired" | "revoked";
  decisionId?: string;
  policyVersion?: number;
  expiresAt?: number;
  revokedAt?: number;
  revision?: number;
  capabilities: SessionCapabilities;
};

type CapabilityDecisionRow = {
  subject_hash: string;
  decision_id: string;
  policy_version: number;
  decision: "allow" | "deny";
  online_battle: number;
  trading: number;
  preset_messages: number;
  profile_discovery: number;
  review_reference: string;
  issued_at: number;
  expires_at: number;
  revoked_at: number | null;
  revision: number;
};

export async function safetySubjectHash(value: string): Promise<string> {
  if (value.length < 1 || value.length > 200) {
    throw new Error("invalid safety subject");
  }
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`nestarium-safety-v1:${value}`),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function moderationReportId(
  reporterUid: string,
  reportedUid: string,
  reason: string,
  reportDay: string,
): Promise<string> {
  return safetySubjectHash(
    `report:${reporterUid}:${reportedUid}:${reason}:${reportDay}`,
  );
}

export async function recordModerationReport(
  database: D1Database,
  input: ModerationReportInput,
): Promise<boolean> {
  assertIdentifier(input.reportId, "report id", 80);
  assertIdentifier(input.sourceGeneration, "source generation", 80);
  assertIdentifier(input.sourcePool, "source pool", 100);
  assertIdentifier(input.contextId, "context id", 100);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(input.reportDay)) {
    throw new Error("invalid report day");
  }
  if (
    input.reason !== "disruptive_conduct" &&
    input.reason !== "suspected_cheating" &&
    input.reason !== "trade_concern" &&
    input.reason !== "other_safety_concern"
  ) {
    throw new Error("invalid report reason");
  }
  if (!Number.isSafeInteger(input.createdAt) || input.createdAt < 1) {
    throw new Error("invalid report timestamp");
  }
  const [reporterHash, reportedHash] = await Promise.all([
    safetySubjectHash(input.reporterUid),
    safetySubjectHash(input.reportedUid),
  ]);
  const result = await database
    .prepare(
      `INSERT OR IGNORE INTO moderation_reports (
        report_id, source_generation, source_pool,
        reporter_subject_hash, reported_subject_hash,
        reason, context_type, context_id, report_day,
        status, created_at, expires_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)`,
    )
    .bind(
      input.reportId,
      input.sourceGeneration,
      input.sourcePool,
      reporterHash,
      reportedHash,
      input.reason,
      input.contextType,
      input.contextId,
      input.reportDay,
      input.createdAt,
      input.createdAt + moderationReportRetentionMs,
    )
    .run();
  return (result.meta.changes ?? 0) > 0;
}

export async function capabilityDecisionForUid(
  database: D1Database,
  uid: string,
  now = Date.now(),
): Promise<CapabilityDecisionStatus> {
  const subjectHash = await safetySubjectHash(uid);
  const row = await database
    .prepare(
      `SELECT subject_hash, decision_id, policy_version, decision,
        online_battle, trading, preset_messages, profile_discovery,
        review_reference, issued_at, expires_at, revoked_at, revision
       FROM capability_decisions WHERE subject_hash = ?`,
    )
    .bind(subjectHash)
    .first<CapabilityDecisionRow>();
  if (!row) {
    return { subjectHash, status: "missing", capabilities: deniedCapabilities };
  }
  const shared = {
    subjectHash,
    decisionId: row.decision_id,
    policyVersion: row.policy_version,
    expiresAt: row.expires_at,
    ...(row.revoked_at === null ? {} : { revokedAt: row.revoked_at }),
    revision: row.revision,
  };
  if (row.revoked_at !== null) {
    return { ...shared, status: "revoked", capabilities: deniedCapabilities };
  }
  if (row.expires_at <= now) {
    return { ...shared, status: "expired", capabilities: deniedCapabilities };
  }
  if (
    row.policy_version !== familyCapabilityPolicyVersion ||
    row.decision !== "allow"
  ) {
    return { ...shared, status: "denied", capabilities: deniedCapabilities };
  }
  return {
    ...shared,
    status: "allowed",
    capabilities: {
      onlineBattle: row.online_battle === 1,
      trading: row.trading === 1,
      presetMessages: row.preset_messages === 1,
      profileDiscovery: row.profile_discovery === 1,
    },
  };
}

export async function issueCapabilityDecision(
  database: D1Database,
  uid: string,
  input: CapabilityDecisionInput,
  now = Date.now(),
): Promise<CapabilityDecisionStatus> {
  validateCapabilityDecision(input, now);
  const subjectHash = await safetySubjectHash(uid);
  await database.batch([
    database
      .prepare(
        `INSERT INTO capability_decisions (
          subject_hash, decision_id, policy_version, decision,
          online_battle, trading, preset_messages, profile_discovery,
          review_reference, issued_at, expires_at, revoked_at, revision
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?)
        ON CONFLICT(subject_hash) DO UPDATE SET
          decision_id = excluded.decision_id,
          policy_version = excluded.policy_version,
          decision = excluded.decision,
          online_battle = excluded.online_battle,
          trading = excluded.trading,
          preset_messages = excluded.preset_messages,
          profile_discovery = excluded.profile_discovery,
          review_reference = excluded.review_reference,
          issued_at = excluded.issued_at,
          expires_at = excluded.expires_at,
          revoked_at = NULL,
          revision = capability_decisions.revision + 1`,
      )
      .bind(
        subjectHash,
        input.decisionId,
        input.policyVersion,
        input.decision,
        input.onlineBattle ? 1 : 0,
        input.trading ? 1 : 0,
        input.presetMessages ? 1 : 0,
        input.profileDiscovery ? 1 : 0,
        input.reviewReference,
        now,
        input.expiresAt,
        1,
      ),
    database
      .prepare(
        `INSERT INTO capability_events (
          event_id, subject_hash, decision_id, action,
          policy_version, review_reference, occurred_at
        ) VALUES (?, ?, ?, 'issued', ?, ?, ?)`,
      )
      .bind(
        crypto.randomUUID(),
        subjectHash,
        input.decisionId,
        input.policyVersion,
        input.reviewReference,
        now,
      ),
  ]);
  return capabilityDecisionForUid(database, uid, now);
}

export async function revokeCapabilityDecision(
  database: D1Database,
  uid: string,
  reviewReference: string,
  now = Date.now(),
): Promise<CapabilityDecisionStatus> {
  assertReviewReference(reviewReference);
  const subjectHash = await safetySubjectHash(uid);
  const row = await database
    .prepare(
      "SELECT decision_id, policy_version FROM capability_decisions WHERE subject_hash = ?",
    )
    .bind(subjectHash)
    .first<{ decision_id: string; policy_version: number }>();
  if (!row) throw new Error("capability decision does not exist");
  await database.batch([
    database
      .prepare(
        `UPDATE capability_decisions
         SET revoked_at = ?, review_reference = ?, revision = revision + 1
         WHERE subject_hash = ?`,
      )
      .bind(now, reviewReference, subjectHash),
    database
      .prepare(
        `INSERT INTO capability_events (
          event_id, subject_hash, decision_id, action,
          policy_version, review_reference, occurred_at
        ) VALUES (?, ?, ?, 'revoked', ?, ?, ?)`,
      )
      .bind(
        crypto.randomUUID(),
        subjectHash,
        row.decision_id,
        row.policy_version,
        reviewReference,
        now,
      ),
  ]);
  return capabilityDecisionForUid(database, uid, now);
}

export async function pruneExpiredModerationReports(
  database: D1Database,
  now = Date.now(),
): Promise<number> {
  const result = await database
    .prepare("DELETE FROM moderation_reports WHERE expires_at <= ?")
    .bind(now)
    .run();
  return result.meta.changes ?? 0;
}

export async function safetyAuthoritySummary(
  database: D1Database,
  now = Date.now(),
): Promise<Record<string, number>> {
  const result = await database.batch([
    database.prepare(
      "SELECT COUNT(*) AS count FROM moderation_reports WHERE expires_at > ?",
    ).bind(now),
    database.prepare(
      "SELECT COUNT(*) AS count FROM moderation_reports WHERE status = 'pending' AND expires_at > ?",
    ).bind(now),
    database.prepare(
      "SELECT COUNT(*) AS count FROM capability_decisions WHERE revoked_at IS NULL AND expires_at > ?",
    ).bind(now),
    database.prepare(
      "SELECT COUNT(*) AS count FROM capability_decisions WHERE revoked_at IS NOT NULL",
    ),
  ]);
  const count = (index: number) =>
    Number((result[index]?.results[0] as { count?: number } | undefined)?.count ?? 0);
  return {
    retainedReports: count(0),
    pendingReports: count(1),
    activeCapabilityDecisions: count(2),
    revokedCapabilityDecisions: count(3),
  };
}

export async function listModerationReports(
  database: D1Database,
  afterCreatedAt = 0,
  afterReportId = "",
  requestedLimit = 100,
): Promise<{
  reports: Array<Record<string, string | number>>;
  nextCursor: { createdAt: number; reportId: string } | null;
}> {
  if (!Number.isSafeInteger(afterCreatedAt) || afterCreatedAt < 0) {
    throw new Error("invalid report cursor timestamp");
  }
  if (afterReportId) assertIdentifier(afterReportId, "report cursor", 80);
  if (!Number.isInteger(requestedLimit) || requestedLimit < 1 || requestedLimit > 500) {
    throw new Error("invalid report page size");
  }
  const result = await database
    .prepare(
      `SELECT report_id, source_generation, source_pool,
        reporter_subject_hash, reported_subject_hash, reason,
        context_type, context_id, report_day, status, created_at, expires_at
       FROM moderation_reports
       WHERE (created_at > ? OR (created_at = ? AND report_id > ?))
       ORDER BY created_at, report_id LIMIT ?`,
    )
    .bind(afterCreatedAt, afterCreatedAt, afterReportId, requestedLimit + 1)
    .all<Record<string, string | number>>();
  const rows = result.results;
  const hasMore = rows.length > requestedLimit;
  const reports = rows.slice(0, requestedLimit);
  const last = reports.at(-1);
  return {
    reports,
    nextCursor: hasMore && last
      ? { createdAt: Number(last.created_at), reportId: String(last.report_id) }
      : null,
  };
}

function validateCapabilityDecision(
  input: CapabilityDecisionInput,
  now: number,
): void {
  assertIdentifier(input.decisionId, "decision id", 100);
  assertReviewReference(input.reviewReference);
  if (input.policyVersion !== familyCapabilityPolicyVersion) {
    throw new Error("unsupported family capability policy version");
  }
  if (!Number.isSafeInteger(input.expiresAt)) {
    throw new Error("invalid capability expiry");
  }
  if (
    input.expiresAt <= now ||
    input.expiresAt > now + maximumCapabilityLifetimeMs
  ) {
    throw new Error("capability expiry must be within the next 366 days");
  }
  if (input.profileDiscovery) {
    throw new Error("profile discovery is not approved in family policy v1");
  }
  if (input.presetMessages && !input.trading) {
    throw new Error("preset messages require trading permission");
  }
  if (
    input.decision === "allow" &&
    !input.onlineBattle &&
    !input.trading
  ) {
    throw new Error("an allow decision must grant a hosted activity");
  }
  if (
    input.decision === "deny" &&
    (input.onlineBattle ||
      input.trading ||
      input.presetMessages ||
      input.profileDiscovery)
  ) {
    throw new Error("a deny decision cannot grant capabilities");
  }
}

function assertReviewReference(value: string): void {
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,99}$/.test(value)) {
    throw new Error("invalid review reference");
  }
}

function assertIdentifier(value: string, label: string, maximum: number): void {
  if (
    value.length < 1 ||
    value.length > maximum ||
    !/^[A-Za-z0-9][A-Za-z0-9._:-]*$/.test(value)
  ) {
    throw new Error(`invalid ${label}`);
  }
}
