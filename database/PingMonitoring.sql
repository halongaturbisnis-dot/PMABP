-- SQL Schema for PingMonitoring
-- Standardized following /GUIDANCE/DatabaseRule.md dan /GUIDANCE/ActiveDatabaseRule.md
-- Tabel ini didesain sebagai Singleton (Hanya menyimpan 1 baris record)

CREATE TABLE IF NOT EXISTS PingMonitoring (
    id TEXT PRIMARY KEY DEFAULT 'singleton-ping-monitor',
    ping_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL, -- 'SUCCESS', 'FAILED'
    message TEXT,
    triggered_by TEXT DEFAULT 'CRON', -- 'CRON', 'SYSTEM', 'MANUAL'
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT DEFAULT 'SYSTEM',
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT
);

-- Trigger for updated_at on PingMonitoring
CREATE TRIGGER IF NOT EXISTS PingMonitoring_update_audit
AFTER UPDATE ON PingMonitoring
FOR EACH ROW
BEGIN
  UPDATE PingMonitoring 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- Index for performance on date lookups
CREATE INDEX IF NOT EXISTS idx_ping_at ON PingMonitoring(ping_at);
