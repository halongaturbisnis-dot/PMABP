-- Module: Penyerahan
-- Description: Database schema for Penyerahan module (handover of sold goods).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, StorageRule.md

CREATE TABLE IF NOT EXISTS penyerahan (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    penjualan_id TEXT NOT NULL,
    
    -- DATA PENYERAHAN
    penyerahan_type TEXT NOT NULL CHECK(penyerahan_type IN ('Loco', 'Franco')),
    surat_jalan_number TEXT, -- Dapat bernilai kosong untuk tipe Loco yang tidak butuh surat formal
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    handover_datetime DATETIME, -- Waktu aktual barang diterima/diserahkan ke tangan konsumen
    recipient_name TEXT,
    description TEXT,
    
    -- DATA FRANCO (Kurir/Pengiriman/Ekspedisi)
    shipping_method TEXT,
    vehicle_number TEXT,
    driver_name TEXT,
    driver_phone TEXT,
    driver_user_id TEXT,
    resi_number TEXT,
    
    -- DATA GEOTAGGING HANDOVER (Khusus Franco)
    handover_lat REAL,
    handover_lng REAL,
    handover_distance REAL, -- Jarak dari titik customer dalam Meter
    handover_address TEXT,
    
    -- LAMPIRAN BUKTI & STATUS
    proof_fileurls TEXT DEFAULT '[]', -- JSON string array [{url, key, name}]
    status TEXT DEFAULT 'Pending' CHECK(status IN ('Pending', 'Ready', 'On Delivery', 'Completed', 'Cancelled')),
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (penjualan_id) REFERENCES penjualan(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_penyerahan_penjualan_id ON penyerahan(penjualan_id);
CREATE INDEX IF NOT EXISTS idx_penyerahan_status ON penyerahan(status);

CREATE TRIGGER IF NOT EXISTS penyerahan_update_audit
AFTER UPDATE ON penyerahan
FOR EACH ROW
BEGIN
  UPDATE penyerahan 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
