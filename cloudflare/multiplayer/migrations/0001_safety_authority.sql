CREATE TABLE IF NOT EXISTS moderation_reports (
  report_id TEXT PRIMARY KEY,
  source_generation TEXT NOT NULL,
  source_pool TEXT NOT NULL,
  reporter_subject_hash TEXT NOT NULL,
  reported_subject_hash TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (
    reason IN (
      'disruptive_conduct',
      'suspected_cheating',
      'trade_concern',
      'other_safety_concern'
    )
  ),
  context_type TEXT NOT NULL CHECK (context_type IN ('battle', 'trade')),
  context_id TEXT NOT NULL,
  report_day TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'reviewed', 'actioned', 'dismissed')
  ),
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS moderation_reports_review_queue
  ON moderation_reports(status, created_at, report_id);
CREATE INDEX IF NOT EXISTS moderation_reports_expiry
  ON moderation_reports(expires_at);
CREATE INDEX IF NOT EXISTS moderation_reports_subject
  ON moderation_reports(reported_subject_hash, created_at);

CREATE TABLE IF NOT EXISTS capability_decisions (
  subject_hash TEXT PRIMARY KEY,
  decision_id TEXT NOT NULL UNIQUE,
  policy_version INTEGER NOT NULL,
  decision TEXT NOT NULL CHECK (decision IN ('allow', 'deny')),
  online_battle INTEGER NOT NULL CHECK (online_battle IN (0, 1)),
  trading INTEGER NOT NULL CHECK (trading IN (0, 1)),
  preset_messages INTEGER NOT NULL CHECK (preset_messages IN (0, 1)),
  profile_discovery INTEGER NOT NULL CHECK (profile_discovery IN (0, 1)),
  review_reference TEXT NOT NULL,
  issued_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  revoked_at INTEGER,
  revision INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS capability_decisions_expiry
  ON capability_decisions(expires_at);

CREATE TABLE IF NOT EXISTS capability_events (
  event_id TEXT PRIMARY KEY,
  subject_hash TEXT NOT NULL,
  decision_id TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('issued', 'revoked')),
  policy_version INTEGER NOT NULL,
  review_reference TEXT NOT NULL,
  occurred_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS capability_events_subject
  ON capability_events(subject_hash, occurred_at);
