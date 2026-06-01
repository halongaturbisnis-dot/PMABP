-- Module: Penjualan
-- Description: Database schema for Sales (Penjualan) module.
-- Contains tables for: penjualan, penjualan_produk, penjualan_produk_mixing, and penjualan_biaya.
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, StorageRule.md

PRAGMA foreign_keys = OFF;

-- ==========================================
-- 1. Table: penjualan
-- ==========================================
CREATE TABLE IF NOT EXISTS penjualan (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- DATA TRANSAKSI
    datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sales_id TEXT,                      -- Relasi ke marketing (opsional/kosongkan dulu)
    sales_name TEXT,                    -- Nama sales saat transaksi
    invoice_number TEXT NOT NULL UNIQUE, -- Nomor Invoice
    customer_id TEXT NOT NULL,          -- Relasi ke table customer
    
    -- RINGKASAN FINANSIAL
    sum_product_price REAL NOT NULL DEFAULT 0, -- Total harga produk (subtotal)
    sum_added_cost REAL NOT NULL DEFAULT 0,    -- Total biaya tambahan
    discount_type TEXT DEFAULT 'price',        -- 'price' atau 'percent'
    discount_value REAL DEFAULT 0,             -- Nilai diskon
    discount_amount REAL DEFAULT 0,            -- Hasil nominal diskon dalam rupiah
    grand_total REAL NOT NULL DEFAULT 0,       -- (Total Produk + Biaya Tambahan) - Diskon
    
    -- STATUS PEMBAYARAN
    payment_type TEXT NOT NULL CHECK(payment_type IN ('Lunas', 'Tempo')),
    deposit REAL DEFAULT 0,             -- Uang muka jika tempo
    outstanding REAL DEFAULT 0,         -- Sisa tagihan jika tempo
    sla_date DATETIME,                  -- Tanggal jatuh tempo (jika tempo)
    
    -- METODE PEMBAYARAN & SUMBER DANA
    payment_method TEXT NOT NULL CHECK(payment_method IN ('Tunai', 'Non Tunai')),
    bank_cash_source_id TEXT NOT NULL,  -- Relasi ke bank_and_cash
    
    -- LAMPIRAN & KETERANGAN
    payment_proof_fileurls TEXT DEFAULT '[]', -- JSON string array URL bukti bayar
    keterangan TEXT,
    status TEXT DEFAULT 'Draft',        -- Draft, Confirmed, Cancelled, Completed
    invoice_pdf_url TEXT,               -- URL file PDF invoice yang di-generate
    
    -- APPROVAL WORKFLOW
    approver_id TEXT,                   -- Relasi ke akun(id)
    approver_name TEXT,                 -- Nama approver saat dipilih
    approval_status TEXT CHECK(approval_status IN ('Pending', 'Approved', 'Rejected')) DEFAULT 'Pending',
    approval_signature_url TEXT,       -- URL tanda tangan approver
    approval_at DATETIME,               -- Tanggal approval
    approval_note TEXT,                 -- Catatan dari approver
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (bank_cash_source_id) REFERENCES bank_and_cash(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_penjualan_invoice_number ON penjualan(invoice_number);
CREATE INDEX IF NOT EXISTS idx_penjualan_customer_id ON penjualan(customer_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_datetime ON penjualan(datetime);

CREATE TRIGGER IF NOT EXISTS penjualan_update_audit
AFTER UPDATE ON penjualan
FOR EACH ROW
BEGIN
  UPDATE penjualan 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- ==========================================
-- 2. Table: penjualan_produk
-- ==========================================
CREATE TABLE IF NOT EXISTS penjualan_produk (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    penjualan_id TEXT NOT NULL,         -- Relasi ke penjualan(id)
    
    -- DATA PRODUK
    is_mixing INTEGER NOT NULL DEFAULT 0, -- 1 jika produk racikan/custom, 0 jika produk normal
    is_dropship INTEGER NOT NULL DEFAULT 0, -- 1 jika dropship
    sku TEXT,                           -- SKU (NULL jika custom mixing baru tanpa SKU master)
    name TEXT NOT NULL,                 -- Nama produk (diambil dari master atau inputan untuk custom)
    kategori TEXT,                      -- Kategori Produk (khusus dropship)
    sub_kategori TEXT,                  -- Sub Kategori Produk (khusus dropship)
    unit TEXT NOT NULL,                 -- Satuan
    qty REAL NOT NULL DEFAULT 0,
    
    -- HARGA & PROFIT SNAPSHOT (Contractual)
    unit_selling_price REAL NOT NULL,    -- Harga jual per unit saat transaksi
    unit_base_price REAL NOT NULL,       -- Harga HPP/Dasar saat transaksi
    total_selling_price REAL NOT NULL,   -- qty * unit_selling_price
    total_base_price REAL NOT NULL,      -- qty * unit_base_price
    margin_amount REAL NOT NULL,         -- profit nominal
    margin_percentage REAL NOT NULL,     -- profit persentase
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (penjualan_id) REFERENCES penjualan(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_penjualan_produk_penjualan_id ON penjualan_produk(penjualan_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_produk_sku ON penjualan_produk(sku);

CREATE TRIGGER IF NOT EXISTS penjualan_produk_update_audit
AFTER UPDATE ON penjualan_produk
FOR EACH ROW
BEGIN
  UPDATE penjualan_produk 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- ==========================================
-- 3. Table: penjualan_produk_mixing
-- ==========================================
CREATE TABLE IF NOT EXISTS penjualan_produk_mixing (
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
    penjualan_produk_id TEXT NOT NULL,
    
    -- DATA KOMPOSISI
    sku TEXT NOT NULL,
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    qty_composition REAL NOT NULL,
    total_qty REAL NOT NULL,
    
    -- SNAPSHOT HARGA BAHAN BAKU
    base_price_snapshot REAL NOT NULL,
    total_base_price REAL NOT NULL,
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (penjualan_id) REFERENCES penjualan(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (penjualan_produk_id) REFERENCES penjualan_produk(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (sku) REFERENCES stok_berjalan(sku) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_penjualan_mixing_produk_id ON penjualan_produk_mixing(penjualan_produk_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_mixing_sku ON penjualan_produk_mixing(sku);

CREATE TRIGGER IF NOT EXISTS penjualan_produk_mixing_update_audit
AFTER UPDATE ON penjualan_produk_mixing
FOR EACH ROW
BEGIN
  UPDATE penjualan_produk_mixing 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- ==========================================
-- 5. MIGRATION: UPDATE penjualan_produk MENDUKUNG DROPSHIP
-- Menambahkan is_dropship, kategori, dan sub_kategori secara aman (Idempotent 4.B DatabaseRule.md)
-- ==========================================

CREATE TABLE IF NOT EXISTS penjualan_produk_new (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    penjualan_id TEXT NOT NULL,
    is_mixing INTEGER NOT NULL DEFAULT 0,
    is_dropship INTEGER NOT NULL DEFAULT 0, -- Kolom Baru
    sku TEXT,
    name TEXT NOT NULL,
    kategori TEXT,                          -- Kolom Baru
    sub_kategori TEXT,                      -- Kolom Baru
    unit TEXT NOT NULL,
    qty REAL NOT NULL DEFAULT 0,
    unit_selling_price REAL NOT NULL,
    unit_base_price REAL NOT NULL,
    total_selling_price REAL NOT NULL,
    total_base_price REAL NOT NULL,
    margin_amount REAL NOT NULL,
    margin_percentage REAL NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',
    FOREIGN KEY (penjualan_id) REFERENCES penjualan(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Copy data lama, biarkan is_dropship menggunakan default (0), dan kategori/sub_kategori menjadi NULL
INSERT INTO penjualan_produk_new (
    id, penjualan_id, is_mixing, sku, name, unit, qty, 
    unit_selling_price, unit_base_price, total_selling_price, total_base_price, 
    margin_amount, margin_percentage, created_at, created_by, created_timezone, 
    updated_at, updated_by, updated_timezone
)
SELECT 
    id, penjualan_id, is_mixing, sku, name, unit, qty, 
    unit_selling_price, unit_base_price, total_selling_price, total_base_price, 
    margin_amount, margin_percentage, created_at, created_by, created_timezone, 
    updated_at, updated_by, updated_timezone
FROM penjualan_produk;

DROP TABLE IF EXISTS penjualan_produk;
ALTER TABLE penjualan_produk_new RENAME TO penjualan_produk;

CREATE INDEX IF NOT EXISTS idx_penjualan_produk_penjualan_id ON penjualan_produk(penjualan_id);
CREATE INDEX IF NOT EXISTS idx_penjualan_produk_sku ON penjualan_produk(sku);

CREATE TRIGGER IF NOT EXISTS penjualan_produk_update_audit
AFTER UPDATE ON penjualan_produk
FOR EACH ROW
BEGIN
  UPDATE penjualan_produk 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

CREATE TABLE IF NOT EXISTS penjualan_biaya (
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
    
    -- DATA BIAYA
    nama_biaya TEXT NOT NULL,
    nominal REAL NOT NULL DEFAULT 0,
    keterangan TEXT,
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (penjualan_id) REFERENCES penjualan(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_penjualan_biaya_penjualan_id ON penjualan_biaya(penjualan_id);

CREATE TRIGGER IF NOT EXISTS penjualan_biaya_update_audit
AFTER UPDATE ON penjualan_biaya
FOR EACH ROW
BEGIN
  UPDATE penjualan_biaya 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

PRAGMA foreign_keys = ON;
