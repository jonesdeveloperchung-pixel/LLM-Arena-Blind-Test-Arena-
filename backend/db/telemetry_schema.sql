-- SQLite 3.x Compatible
-- Schema for storing Telemetry Logs

CREATE TABLE IF NOT EXISTS telemetry_logs (
    id TEXT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    program TEXT NOT NULL,
    version TEXT,
    command TEXT,
    module TEXT,
    action TEXT,
    args TEXT, -- Stored as JSON string
    user TEXT,
    host TEXT,
    os TEXT,
    runtime TEXT,
    execution_duration_ms INTEGER,
    execution_exit_code INTEGER,
    execution_error TEXT,
    context_cwd TEXT,
    context_details TEXT,
    tags TEXT -- Stored as JSON string
);

CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp ON telemetry_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_telemetry_program ON telemetry_logs(program);
CREATE INDEX IF NOT EXISTS idx_telemetry_module_action ON telemetry_logs(module, action);