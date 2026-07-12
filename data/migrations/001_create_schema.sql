-- M4 Knowledge Layer Schema Migration
-- Creates tables for normalized items, synthesized briefs, and deduplication state

-- Table: normalized_items
-- Raw items from all sources, normalized to common format
CREATE TABLE IF NOT EXISTS normalized_items (
  id BIGSERIAL PRIMARY KEY,
  source VARCHAR(50) NOT NULL,
  source_id VARCHAR(255) UNIQUE NOT NULL,
  title TEXT NOT NULL,
  url TEXT,
  content TEXT,
  priority VARCHAR(20),
  tags JSONB DEFAULT '[]',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  workflow_run_id UUID
);

CREATE INDEX IF NOT EXISTS idx_normalized_items_source ON normalized_items(source);
CREATE INDEX IF NOT EXISTS idx_normalized_items_source_id ON normalized_items(source_id);
CREATE INDEX IF NOT EXISTS idx_normalized_items_created_at ON normalized_items(created_at);

-- Table: synthesized_briefs
-- Claude-synthesized daily insights
CREATE TABLE IF NOT EXISTS synthesized_briefs (
  id BIGSERIAL PRIMARY KEY,
  date DATE UNIQUE NOT NULL,
  markdown_content TEXT NOT NULL,
  insights JSONB DEFAULT '[]',
  source_items_count INT,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_synthesized_briefs_date ON synthesized_briefs(date);

-- Table: dedup_state
-- 7-day deduplication tracking
CREATE TABLE IF NOT EXISTS dedup_state (
  source_id VARCHAR(255) PRIMARY KEY,
  last_seen TIMESTAMP NOT NULL,
  workflow_run_id UUID
);

CREATE INDEX IF NOT EXISTS idx_dedup_state_last_seen ON dedup_state(last_seen);

-- Permissions
DO $$ BEGIN
  CREATE ROLE readonly_user;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
