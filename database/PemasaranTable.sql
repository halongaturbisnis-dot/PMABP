-- Table: pemasaran
-- Description: Menyimpan data kunjungan aktivitas pemasaran (client relation, selling, offering).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS pemasaran (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Data Kunjungan Pemasaran
    visit_date DATETIME NOT NULL,                     -- Waktu aktual kejadian kunjungan (TimeRule.md)
    sales_username TEXT NOT NULL,                     -- Username sales yang melakukan kunjungan (Mandatory)
    activity_type TEXT NOT NULL CHECK(activity_type IN ('client relation', 'selling', 'offering')), -- Tipe Kegiatan (Mandatory)
    customer_id TEXT NOT NULL,                        -- Referensi ID Customer (Mandatory)
    description TEXT,                                 -- Deskripsi/Catatan kunjungan (Optional)
    latlong_visiting TEXT NOT NULL,                   -- Koordinat GPS lokasi kunjungan, format: "lat,long" (Mandatory)
    alamat TEXT NOT NULL,                             -- Alamat lengkap lokasi kunjungan (Mandatory)
    proof_url TEXT NOT NULL,                          -- URL bukti foto/file dokumen kunjungan (Mandatory, StorageRule.md)
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                  -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,                                  -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- Referential Integrity
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Index untuk optimasi pencarian
CREATE INDEX IF NOT EXISTS idx_pemasaran_date ON pemasaran(visit_date);
CREATE INDEX IF NOT EXISTS idx_pemasaran_sales ON pemasaran(sales_username);
CREATE INDEX IF NOT EXISTS idx_pemasaran_customer ON pemasaran(customer_id);

-- Trigger untuk pembaruan updated_at otomatis
CREATE TRIGGER IF NOT EXISTS pemasaran_update_audit
AFTER UPDATE ON pemasaran
FOR EACH ROW
BEGIN
  UPDATE pemasaran 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
