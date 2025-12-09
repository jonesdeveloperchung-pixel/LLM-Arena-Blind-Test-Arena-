-- Ollama Pipeline Database Schema
-- SQLite 3.x Compatible

-- 主要處理項目表 (Main Pipeline Items)
CREATE TABLE IF NOT EXISTS pipeline_items (
    id TEXT PRIMARY KEY,
    filename TEXT NOT NULL,
    filepath TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending', 'processing', 'approved', 'rejected', 'failed')),
    source TEXT CHECK(source IN ('Ollama', 'Gemini', 'Manual')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_time_ms INTEGER,
    confidence_score REAL,
    description TEXT,
    metadata_json TEXT,
    detection_raw_json TEXT,
    error_message TEXT
);

-- 審核歷史表 (Approval History)
CREATE TABLE IF NOT EXISTS approval_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id TEXT NOT NULL,
    action TEXT NOT NULL CHECK(action IN ('approve', 'reject', 'requeue')),
    reviewer TEXT,
    notes TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES pipeline_items(id)
);

-- 系統日誌表 (System Logs)
CREATE TABLE IF NOT EXISTS system_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level TEXT NOT NULL CHECK(level IN ('DEBUG', 'INFO', 'WARNING', 'ERROR')),
    message TEXT NOT NULL,
    module TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 配置快照表 (Config Snapshots)
CREATE TABLE IF NOT EXISTS config_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    config_json TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引優化 (Indexes)
CREATE INDEX IF NOT EXISTS idx_items_status ON pipeline_items(status);
CREATE INDEX IF NOT EXISTS idx_items_created ON pipeline_items(created_at);
CREATE INDEX IF NOT EXISTS idx_history_item ON approval_history(item_id);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON system_logs(timestamp);

-- 觸發器：自動更新 updated_at (Trigger: Auto-update timestamp)
CREATE TRIGGER IF NOT EXISTS update_timestamp 
AFTER UPDATE ON pipeline_items
BEGIN
    UPDATE pipeline_items SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- 告警表 (Alerts)
CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT NOT NULL CHECK(severity IN ('info', 'warning', 'error', 'critical')),
    details TEXT, -- Stored as JSON string
    status TEXT NOT NULL CHECK(status IN ('active', 'dismissed', 'resolved')),
    dismissed_at TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_timestamp ON alerts(timestamp);

