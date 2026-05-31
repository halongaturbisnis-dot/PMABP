-- Table: customer
-- Description: Menyimpan data pembeli/pelanggan untuk modul Customer.
-- Standard: Mengikuti aturan DatabaseRule.md

CREATE TABLE IF NOT EXISTS customer (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Data Customer
    name TEXT NOT NULL,
    company TEXT,
    telepon TEXT NOT NULL,
    email TEXT,
    latlong TEXT NOT NULL, -- Format: "latitude,longitude"
    alamat TEXT NOT NULL,
    bidang_usaha TEXT,
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'
);

-- Index untuk mempermudah pencarian nama
CREATE INDEX IF NOT EXISTS idx_customer_name ON customer(name);

-- Trigger untuk pembaruan updated_at otomatis
CREATE TRIGGER IF NOT EXISTS customer_update_audit
AFTER UPDATE ON customer
FOR EACH ROW
BEGIN
  UPDATE customer 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
