SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS packages (
  package_id TEXT PRIMARY KEY,
  package_path TEXT NOT NULL,
  package_name TEXT NOT NULL,
  domain TEXT,
  mode TEXT,
  source_count INTEGER DEFAULT 0,
  chunk_count INTEGER DEFAULT 0,
  quality_score INTEGER,
  quality_level TEXT,
  agent_type TEXT,
  imported_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sources (
  package_id TEXT NOT NULL,
  source_id TEXT NOT NULL,
  source_path TEXT,
  relative_path TEXT,
  source_name TEXT,
  extension TEXT,
  content_hash TEXT,
  PRIMARY KEY (package_id, source_id)
);

CREATE TABLE IF NOT EXISTS chunks_index (
  package_id TEXT NOT NULL,
  chunk_id TEXT NOT NULL,
  text TEXT,
  source_path TEXT,
  domain TEXT,
  mode TEXT,
  PRIMARY KEY (package_id, chunk_id)
);

CREATE TABLE IF NOT EXISTS quality_records (
  package_id TEXT PRIMARY KEY,
  quality_score INTEGER,
  quality_level TEXT,
  warning_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS risk_records (
  package_id TEXT NOT NULL,
  risk_id TEXT NOT NULL,
  label TEXT,
  severity TEXT,
  source_path TEXT,
  PRIMARY KEY (package_id, risk_id)
);

CREATE TABLE IF NOT EXISTS runs (
  package_id TEXT NOT NULL,
  run_id TEXT NOT NULL,
  status TEXT,
  started_at TEXT,
  PRIMARY KEY (package_id, run_id)
);

CREATE TABLE IF NOT EXISTS publish_records (
  package_id TEXT PRIMARY KEY,
  profile TEXT,
  publish_manifest TEXT
);

CREATE TABLE IF NOT EXISTS agent_targets (
  package_id TEXT PRIMARY KEY,
  agent_type TEXT,
  agent_name TEXT,
  agent_profile_path TEXT
);
"""
