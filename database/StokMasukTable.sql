-- Table: stok_masuk
-- Description: Mencatat setiap transaksi stok yang masuk ke gudang (berasal dari pembelian atau pemrosesan).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS stok_masuk (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- KEBUTUHAN RELASI DATABASE (Optional for manual entry)
    purchase_id TEXT,                 -- FK ke pembelian.id
    purchase_product_id TEXT,         -- FK ke pembelian_produk.id
    receiving_id TEXT,                -- FK ke penerimaan.id
    processing_id TEXT,               -- FK ke pemrosesan.id
    
    -- DATA ATRIBUT PRODUK (Mandatory)
    sku TEXT NOT NULL,                  -- SKU Produk (Relasi ke stok_berjalan.sku)
    category TEXT NOT NULL,             -- Kategori
    sub_category TEXT,                  -- Sub Kategori (Optional)
    name TEXT NOT NULL,                 -- Nama Produk
    unit TEXT NOT NULL,                 -- Satuan (kg, pcs, dll)
    
    -- DATA KUANTITAS & HARGA (Mandatory)
    qty_in REAL NOT NULL CHECK(qty_in >= 0),
    price_per_unit_in REAL NOT NULL CHECK(price_per_unit_in >= 0),
    total_price_in REAL NOT NULL CHECK(total_price_in >= 0),
    
    -- MOVING AVERAGE PRICE (Valuasi Baru)
    -- Dihitung berdasarkan rumus moving average terhadap data di stok_berjalan
    new_running_stock_price_per_unit REAL NOT NULL CHECK(new_running_stock_price_per_unit >= 0),
    
    -- DESKRIPSI (Optional)
    description TEXT,
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md

    -- Integritas Referensial sesuai DatabaseRule.md
    FOREIGN KEY (purchase_id) REFERENCES pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (purchase_product_id) REFERENCES pembelian_produk(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (receiving_id) REFERENCES penerimaan(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (processing_id) REFERENCES pemrosesan(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (sku) REFERENCES stok_berjalan(sku) ON DELETE CASCADE ON UPDATE CASCADE
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_stok_masuk_sku ON stok_masuk(sku);
CREATE INDEX IF NOT EXISTS idx_stok_masuk_purchase_id ON stok_masuk(purchase_id);
CREATE INDEX IF NOT EXISTS idx_stok_masuk_receiving_id ON stok_masuk(receiving_id);
CREATE INDEX IF NOT EXISTS idx_stok_masuk_processing_id ON stok_masuk(processing_id);

-- TRIGGER UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS stok_masuk_update_audit
AFTER UPDATE ON stok_masuk
FOR EACH ROW
BEGIN
  UPDATE stok_masuk 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
