-- Table: pengiriman
-- Description: Skema database untuk modul Pengiriman (Logistik).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS pengiriman (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- ID Pembelian (Mandatory, FK ke pembelian)
    purchase_id TEXT NOT NULL,
    
    -- Tanggal & Waktu Pengiriman (Waktu aktual kejadian transaksi sesuai TimeRule.md)
    datetime DATETIME NOT NULL,
    
    -- Jenis Pengiriman (Mandatory)
    shipping_type TEXT NOT NULL,
    
    -- Keterangan Pengiriman (Optional)
    description TEXT,
    
    -- Informasi Kendaraan (Optional)
    vehicle_number TEXT,
    vehicle_type TEXT,
    
    -- Informasi Driver (Optional)
    driver_name TEXT,
    driver_phone TEXT,
    
    -- Status Pengiriman
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'shipped', 'delivered', 'cancelled')),
    
    -- Bukti Pengiriman (Multiple Files di level aplikasi)
    -- Ditulis dalam format JSON string array of objects: '[{"url": "...", "key": "..."}]' sesuai StorageRule.md
    proof_fileurl TEXT NOT NULL,
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    -- Relationships
    FOREIGN KEY (purchase_id) REFERENCES pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_pengiriman_datetime ON pengiriman(datetime);
CREATE INDEX IF NOT EXISTS idx_pengiriman_purchase_id ON pengiriman(purchase_id);
CREATE INDEX IF NOT EXISTS idx_pengiriman_status ON pengiriman(status);

-- TRIGGER UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS pengiriman_update_audit
AFTER UPDATE ON pengiriman
FOR EACH ROW
BEGIN
  UPDATE pengiriman 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
