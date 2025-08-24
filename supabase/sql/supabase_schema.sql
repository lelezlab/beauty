CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS clinical_rules(
  id TEXT PRIMARY KEY,
  metric TEXT NOT NULL,
  unit TEXT,
  hard_min DOUBLE PRECISION,
  hard_max DOUBLE PRECISION,
  soft_min DOUBLE PRECISION,
  soft_max DOUBLE PRECISION,
  locale TEXT DEFAULT 'en-US',
  notes TEXT,
  contraindications TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS clinical_rules_metric_locale_idx
  ON clinical_rules(metric, locale);

CREATE TABLE IF NOT EXISTS effect_manifest(
  id BIGSERIAL PRIMARY KEY,
  version INT NOT NULL,
  json JSONB NOT NULL,
  signature TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS kb_docs(
  id BIGSERIAL PRIMARY KEY,
  source VARCHAR(64) NOT NULL,
  title TEXT NOT NULL,
  snippet TEXT,
  tags TEXT[],
  jurisdiction TEXT,
  evidence_level TEXT,
  published_at TIMESTAMPTZ,
  source_url TEXT NOT NULL,
  raw JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS kb_docs_unique ON kb_docs(source_url);

CREATE TABLE IF NOT EXISTS kb_chunks(
  id BIGSERIAL PRIMARY KEY,
  doc_id BIGINT REFERENCES kb_docs(id) ON DELETE CASCADE,
  locale TEXT DEFAULT 'en-US',
  chunk TEXT NOT NULL,
  embedding VECTOR(1536),
  source_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS telemetry_events(
  id BIGSERIAL PRIMARY KEY,
  user_id UUID,
  event TEXT NOT NULL,
  props JSONB,
  ab_bucket TEXT,
  ts TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS telemetry_events_event_ts_idx ON telemetry_events(event, ts);

CREATE TABLE IF NOT EXISTS ab_metrics_def(
  metric_key TEXT PRIMARY KEY,
  display_name TEXT,
  event TEXT,
  aggregation TEXT,
  window TEXT,
  goal_direction TEXT CHECK (goal_direction IN ('higher','lower')),
  target_value DOUBLE PRECISION,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS 建议（客户端只读，遥测仅插入；如需更严策略可再收紧）
ALTER TABLE clinical_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY cr_ro ON clinical_rules FOR SELECT USING (true);

ALTER TABLE ab_metrics_def ENABLE ROW LEVEL SECURITY;
CREATE POLICY ab_ro ON ab_metrics_def FOR SELECT USING (true);

ALTER TABLE kb_chunks ENABLE ROW LEVEL SECURITY;
CREATE POLICY kb_ro ON kb_chunks FOR SELECT USING (true);

ALTER TABLE telemetry_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY tel_ins ON telemetry_events FOR INSERT WITH CHECK (true);
