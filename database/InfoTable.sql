-- Table: info
-- Description: Menyimpan data informasi perusahaan (alamat, no_telepon) secara terpusat.
-- Standard: Mengikut aturan DatabaseRule.md

CREATE TABLE IF NOT EXISTS info (
    id TEXT PRIMARY KEY DEFAULT '1',
    alamat TEXT NOT NULL,
    no_telepon TEXT NOT NULL,
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'
);

-- Inisialisasi baris pertama jika belum ada
INSERT OR IGNORE INTO info (id, alamat, no_telepon) 
VALUES ('1', 'Alamat Perusahaan Belum Disetel', '-');

-- Trigger untuk pembaruan updated_at otomatis
CREATE TRIGGER IF NOT EXISTS info_update_audit
AFTER UPDATE ON info
FOR EACH ROW
BEGIN
  UPDATE info 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
