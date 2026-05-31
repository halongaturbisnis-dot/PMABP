-- Table: stok_retur
-- Description: Mencatat setiap transaksi stok retur (pengembalian barang) dari customer atau ke suplier.
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS stok_retur (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- DATA ATRIBUT PRODUK (Mandatory - Mengambil referensi dari stok_berjalan secara dinamis)
    sku TEXT NOT NULL,                  -- SKU Produk (Relasi ke stok_berjalan.sku)
    category TEXT NOT NULL,             -- Kategori Produk (Diambil dari stok_berjalan)
    sub_category TEXT,                  -- Sub-Kategori Produk (Diambil dari stok_berjalan, Optional)
    name TEXT NOT NULL,                 -- Nama Produk (Diambil dari stok_berjalan)
    unit TEXT NOT NULL,                 -- Satuan (Diambil dari stok_berjalan, kg, pcs, box, dll)
    
    -- DATA KUANTITAS & HARGA (Mandatory)
    qty REAL NOT NULL CHECK(qty >= 0),                              -- Jumlah Kuantitas Retur
    price_per_unit_in REAL NOT NULL CHECK(price_per_unit_in >= 0),  -- Harga per Unit (Diambil dari base_price/running_price di stok_berjalan)
    total_price_in REAL NOT NULL CHECK(total_price_in >= 0),        -- Total Harga Retur (Hasil kalkulasi: qty * price_per_unit_in)
    
    -- DESKRIPSI DAN ALASAN RETUR (Optional)
    description TEXT,                                               -- Alasan retur atau keterangan tambahan lainnya
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md

    -- Integritas Referensial sesuai DatabaseRule.md
    FOREIGN KEY (sku) REFERENCES stok_berjalan(sku) ON DELETE CASCADE ON UPDATE CASCADE
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_stok_retur_sku ON stok_retur(sku);

-- TRIGGER UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS stok_retur_update_audit
AFTER UPDATE ON stok_retur
FOR EACH ROW
BEGIN
  UPDATE stok_retur 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- NOTE TENTANG LOGIC SINKRONISASI STOK BERJALAN:
-- Ketika ada data retur masuk (INSERT), maka qty retur tersebut akan secara dinamis dihitung 
-- ke dalam kolom virtual 'qty_retur_after_so' pada tabel 'stok_berjalan' untuk menghitung
-- 'qty_current' secara real-time lewat SQL VIEW atau logik service penunjang.
