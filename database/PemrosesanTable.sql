-- Table: pemrosesan
-- Description: Skema database untuk modul Pemrosesan.
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS pemrosesan (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Relasi ke Transaksi Induk (Mandatory)
    pembelian_id TEXT NOT NULL,
    pembelian_produk_id TEXT NOT NULL,
    receiving_id TEXT NOT NULL,         -- FK ke penerimaan.id

    -- Valuasi Dinamis (Mandatory sesuai diskusi)
    initial_valuation REAL NOT NULL DEFAULT 0,    -- Valuasi awal dari accepted_valuation penerimaan
    current_valuation REAL NOT NULL DEFAULT 0,    -- Valuasi terkini setelah dihitung penyusutan
    current_unit_price REAL NOT NULL DEFAULT 0,   -- Harga per satuan baru (current_valuation / qty_sesudah)
    
    -- Waktu Kejadian Pemrosesan (Mandatory)
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Deskripsi Pemrosesan
    jenis_pemrosesan TEXT,
    
    -- Data Meteran (Kuantitas)
    qty_sebelum REAL NOT NULL CHECK(qty_sebelum >= 0),
    qty_sesudah REAL NOT NULL CHECK(qty_sesudah >= 0), -- Rumus: qty_sebelum - qty_penyusutan
    qty_penyusutan REAL NOT NULL CHECK(qty_penyusutan >= 0),
    qty_masuk_stok REAL NOT NULL DEFAULT 0 CHECK(qty_masuk_stok >= 0),
    
    -- Spesifikasi Kualitas Pasca Proses (Mandatory)
    kadar_air_post REAL NOT NULL,
    efisiensi REAL,
    
    -- Kelengkapan Data
    keterangan TEXT,
    -- Bukti Berkas Pendukung (Multiple Files di level aplikasi)
    -- Ditulis dalam format JSON string array sesuai StorageRule.md
    proof_fileurl TEXT NOT NULL DEFAULT '[]',
    status TEXT NOT NULL DEFAULT 'completed' CHECK(status IN ('draft', 'processing', 'completed', 'cancelled')),
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    -- Relationships
    FOREIGN KEY (pembelian_id) REFERENCES pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (pembelian_produk_id) REFERENCES pembelian_produk(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (receiving_id) REFERENCES penerimaan(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: pemrosesan_log
-- Description: Mencatat riwayat log dari setiap tahapan proses dalam satu batch pemrosesan.
CREATE TABLE IF NOT EXISTS pemrosesan_log (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    pemrosesan_id TEXT NOT NULL,
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    jenis_log TEXT,                     -- misal: "Proses Pengeringan Tahap 1"
    qty_sebelum REAL NOT NULL,
    qty_sesudah REAL NOT NULL,
    qty_penyusutan REAL NOT NULL,
    kadar_air_post REAL,
    keterangan TEXT,
    proof_fileurl TEXT NOT NULL DEFAULT '[]',
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    FOREIGN KEY (pemrosesan_id) REFERENCES pemrosesan(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_pemrosesan_receiving_id ON pemrosesan(receiving_id);
CREATE INDEX IF NOT EXISTS idx_pemrosesan_log_pemrosesan_id ON pemrosesan_log(pemrosesan_id);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_pemrosesan_pembelian_id ON pemrosesan(pembelian_id);
CREATE INDEX IF NOT EXISTS idx_pemrosesan_pembelian_produk_id ON pemrosesan(pembelian_produk_id);
CREATE INDEX IF NOT EXISTS idx_pemrosesan_datetime ON pemrosesan(datetime);

-- TRIGGERS UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS pemrosesan_update_audit
AFTER UPDATE ON pemrosesan
FOR EACH ROW
BEGIN
  UPDATE pemrosesan 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
