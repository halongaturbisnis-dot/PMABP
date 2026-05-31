-- Table: daftar_harga
-- Description: Master data daftar harga produk dengan dukungan harga bertingkat (Tiered Pricing/Grosir).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS daftar_harga (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- REFERENSI PRODUK (Relasi ke stok_berjalan)
    sku TEXT NOT NULL UNIQUE,           -- Stock Keeping Unit (Unique Identifier Produk)
    product_id TEXT NOT NULL,           -- ID Produk (Internal System ID)
    
    -- DATA MASTER TAMBAHAN (Denormalized for Performance)
    category TEXT NOT NULL,             -- Kategori Produk
    sub_category TEXT NOT NULL,         -- Sub-Kategori Produk
    name TEXT NOT NULL,                 -- Nama Produk
    unit TEXT NOT NULL,                 -- Satuan (kg, pcs, box, dll)
    
    -- HARGA BERTINGKAT (Tiered Pricing)
    -- Disimpan dalam format JSON string: [{"min_qty": 1, "price": 10000}, {"min_qty": 10, "price": 9500}]
    tiered_pricing TEXT NOT NULL DEFAULT '[]', 
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md

    -- CONSTRAINT RELASI
    FOREIGN KEY (sku) REFERENCES stok_berjalan(sku) ON DELETE CASCADE ON UPDATE CASCADE
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_daftar_harga_sku ON daftar_harga(sku);
CREATE INDEX IF NOT EXISTS idx_daftar_harga_product_id ON daftar_harga(product_id);
CREATE INDEX IF NOT EXISTS idx_daftar_harga_category ON daftar_harga(category);

-- TRIGGER UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS daftar_harga_update_audit
AFTER UPDATE ON daftar_harga
FOR EACH ROW
BEGIN
  UPDATE daftar_harga 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
