-- Table: stok_opname
-- Description: Menyimpan data pencatatan Stok Opname (Audit stok fisik vs sistem)

CREATE TABLE IF NOT EXISTS stok_opname (
    id TEXT PRIMARY KEY,
    no_so TEXT NOT NULL,
    sku TEXT NOT NULL,
    qty_system INTEGER NOT NULL,
    qty_actual INTEGER NOT NULL,
    qty_diff INTEGER NOT NULL,
    harga_per_unit REAL DEFAULT 0,
    total_valuasi_aktual REAL DEFAULT 0,
    total_valuasi_selisih REAL DEFAULT 0,
    notes TEXT,
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_timezone TEXT,

    FOREIGN KEY (sku) REFERENCES stok_berjalan(sku) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Indeks untuk mempercepat pencarian berdasarkan SKU dan Nomor SO
CREATE INDEX IF NOT EXISTS idx_stok_opname_sku ON stok_opname(sku);
CREATE INDEX IF NOT EXISTS idx_stok_opname_no_so ON stok_opname(no_so);

-- TRIGGER: stok_opname_update_audit
-- Otomatis memperbarui updated_at setiap kali ada perubahan data (meskipun stok opname jarang diupdate)
CREATE TRIGGER IF NOT EXISTS stok_opname_update_audit
AFTER UPDATE ON stok_opname
FOR EACH ROW
BEGIN
  UPDATE stok_opname 
  SET updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
END;
