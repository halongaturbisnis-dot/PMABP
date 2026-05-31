-- Table: penerimaan
-- Description: Skema database untuk modul Penerimaan (Receipt) Produk.
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS penerimaan (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- KEBUTUHAN RELASI DATABASE (Mandatory)
    purchase_id TEXT NOT NULL,          -- FK ke pembelian.id
    purchase_product_id TEXT NOT NULL,  -- FK ke pembelian_produk.id
    shipping_id TEXT NOT NULL,          -- FK ke pengiriman.id
    
    -- Tanggal & Waktu (Waktu aktual kejadian sesuai TimeRule.md)
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Sorting Type (Mandatory)
    sorting_type TEXT NOT NULL CHECK(sorting_type IN ('Non QC', 'QC')),
    
    -- Rejection Data
    qty_rejection REAL NOT NULL DEFAULT 0 CHECK(qty_rejection >= 0),
    rejected_valuation REAL NOT NULL DEFAULT 0 CHECK(rejected_valuation >= 0),
    rejected_reason TEXT,               -- LONGTEXT represented as TEXT in SQLite
    rejected_proof_url TEXT,            -- Multiple files JSON string
    
    -- Acceptance Data
    qty_received_actual REAL NOT NULL CHECK(qty_received_actual >= 0),
    qty_diff REAL NOT NULL DEFAULT 0,
    accepted_valuation REAL NOT NULL CHECK(accepted_valuation >= 0),
    price_per_unit_accepted REAL NOT NULL CHECK(price_per_unit_accepted >= 0),
    
    -- Quality Attributes
    actual_moisture REAL,               -- Kadar air aktual
    
    -- Additional Metadata
    description TEXT,
    receipt_proof_url TEXT NOT NULL,    -- Multiple files JSON string (Mandatory)
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                                -- UUID User pembuat
    created_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    updated_at DATETIME,
    updated_by TEXT,                                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',    -- Standar IANA sesuai TimeRule.md
    
    -- Relationships
    FOREIGN KEY (purchase_id) REFERENCES pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (purchase_product_id) REFERENCES pembelian_produk(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (shipping_id) REFERENCES pengiriman(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- INDEX UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_penerimaan_datetime ON penerimaan(datetime);
CREATE INDEX IF NOT EXISTS idx_penerimaan_purchase_id ON penerimaan(purchase_id);
CREATE INDEX IF NOT EXISTS idx_penerimaan_purchase_product_id ON penerimaan(purchase_product_id);
CREATE INDEX IF NOT EXISTS idx_penerimaan_shipping_id ON penerimaan(shipping_id);

-- TRIGGER UNTUK PEMBARUAN AUTOMATIC AUDIT TRAIL (updated_at)
CREATE TRIGGER IF NOT EXISTS penerimaan_update_audit
AFTER UPDATE ON penerimaan
FOR EACH ROW
BEGIN
  UPDATE penerimaan 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
