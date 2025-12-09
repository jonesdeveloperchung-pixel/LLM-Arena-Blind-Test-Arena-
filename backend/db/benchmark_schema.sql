-- SQLite 3.x Compatible
-- Schema for storing LLM benchmark results

CREATE TABLE IF NOT EXISTS benchmark_results (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    model TEXT NOT NULL,
    score REAL NOT NULL,
    breakdown_json TEXT, -- Store breakdown as JSON
    reasoning TEXT,
    run_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_benchmark_category ON benchmark_results(category);
CREATE INDEX IF NOT EXISTS idx_benchmark_model ON benchmark_results(model);
CREATE INDEX IF NOT EXISTS idx_benchmark_timestamp ON benchmark_results(run_timestamp);