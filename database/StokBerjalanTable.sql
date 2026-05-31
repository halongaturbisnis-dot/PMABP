-- Table: stok_berjalan
-- Description: Master data produk dan ringkasan stok berjalan (Running Stock).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS stok_berjalan (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- DATA MASTER PRODUK (Mandatory)
    sku TEXT NOT NULL UNIQUE,           -- Stock Keeping Unit
    category TEXT NOT NULL,             -- Kategori Produk
    sub_category TEXT NOT NULL,         -- Sub-Kategori Produk
    name TEXT NOT NULL,                 -- Nama Produk
    unit TEXT NOT NULL,                 -- Satuan (kg, pcs, box, dll)
    
    -- DATA STOK OPNAME TERAKHIR (Persistent / Snapshot)
    -- Digunakan sebagai titik awal (baseline) perhitungan stok berjalan
    last_so_datetime DATETIME,          -- Waktu SO terakhir dilakukan
    qty_so REAL DEFAULT 0,              -- Hasil qty fisik saat SO terakhir
    
    -- HARGA ACUAN (Persistent)
    base_price REAL NOT NULL DEFAULT 0, -- Harga dasar untuk valuasi awal
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'     -- Standar IANA sesuai TimeRule.md
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_stok_berjalan_sku ON stok_berjalan(sku);
CREATE INDEX IF NOT EXISTS idx_stok_berjalan_category ON stok_berjalan(category);
CREATE INDEX IF NOT EXISTS idx_stok_berjalan_sub_category ON stok_berjalan(sub_category);

-- NOTE TENTANG KOLOM DYNAMIC (Virtual):
-- Kolom 'qty_in_after_so', 'qty_out_after_so', dll disarankan untuk 
-- dihitung secara dinamis melalui logic service atau SQL VIEW yang 
-- mengagregasi data dari tabel transaksi (pembelian, penjualan, dll).

-- TRIGGER UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS stok_berjalan_update_audit
AFTER UPDATE ON stok_berjalan
FOR EACH ROW
BEGIN
  UPDATE stok_berjalan 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
