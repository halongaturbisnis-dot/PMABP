-- Table: pembelian, pembelian_produk, pembelian_biaya
-- Description: Skema database untuk modul Pembelian (Procurement).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

-- 2. Nonaktifkan foreign key check untuk mempermudah manipulasi tabel relasional
PRAGMA foreign_keys = OFF;

-- ============================================================================
-- A. TABEL UTAMA: pembelian
-- ============================================================================

-- Pastikan tabel baseline ada jika dijalankan pertama kali
CREATE TABLE IF NOT EXISTS pembelian (
    id TEXT PRIMARY KEY,
    datetime DATETIME,
    po_number TEXT,
    additional_description TEXT,
    supplier_id TEXT,
    sum_product_price REAL,
    sum_added_cost REAL,
    grand_total_price REAL,
    payment_type TEXT,
    deposit REAL,
    outstanding REAL,
    sla_date DATETIME,
    payment_method TEXT,
    bank_and_cash_id TEXT,
    shipping_type TEXT,
    customer_id TEXT,
    proof_fileurl TEXT,
    status TEXT,
    penjualan_id TEXT, -- Kolom baru untuk dropship
    created_at DATETIME,
    created_by TEXT,
    created_timezone TEXT, 
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT
);

-- Buat tabel baru dengan struktur paling update
CREATE TABLE IF NOT EXISTS pembelian_new (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    datetime DATETIME NOT NULL,
    po_number TEXT NOT NULL UNIQUE,
    additional_description TEXT,
    supplier_id TEXT NOT NULL,
    sum_product_price REAL NOT NULL CHECK(sum_product_price >= 0),
    sum_added_cost REAL NOT NULL CHECK(sum_added_cost >= 0),
    grand_total_price REAL NOT NULL CHECK(grand_total_price >= 0),
    payment_type TEXT NOT NULL CHECK(payment_type IN ('lunas', 'tempo')),
    deposit REAL NOT NULL DEFAULT 0 CHECK(deposit >= 0),
    outstanding REAL NOT NULL DEFAULT 0 CHECK(outstanding >= 0),
    sla_date DATETIME,
    payment_method TEXT NOT NULL CHECK(payment_method IN ('Tunai', 'Non Tunai')),
    bank_and_cash_id TEXT NOT NULL,
    shipping_type TEXT NOT NULL CHECK(shipping_type IN ('Internal', 'Customer')),
    customer_id TEXT,
    proof_fileurl TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'completed' CHECK(status IN ('draft', 'pending', 'completed', 'cancelled')),
    
    -- Relasi Dropship (New Column Update)
    penjualan_id TEXT, 

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta', 
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- Relationships
    FOREIGN KEY (supplier_id) REFERENCES suplier(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bank_and_cash_id) REFERENCES bank_and_cash(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Pindahkan data dari tabel lama ke tabel baru (Aman, data tidak hilang)
-- Gunakan pemilihan kolom yang eksplisit agar tidak error jika kolom baru belum ada di tabel lama
-- Jika kolom penjualan_id belum ada di tabel lama, kita gunakan NULL
INSERT INTO pembelian_new (
    id, datetime, po_number, additional_description, supplier_id, 
    sum_product_price, sum_added_cost, grand_total_price, payment_type, 
    deposit, outstanding, sla_date, payment_method, bank_and_cash_id, 
    shipping_type, customer_id, proof_fileurl, status, penjualan_id, created_at, created_by
)
SELECT 
    id, datetime, po_number, additional_description, supplier_id, 
    sum_product_price, sum_added_cost, grand_total_price, payment_type, 
    deposit, outstanding, sla_date, payment_method, bank_and_cash_id, 
    shipping_type, customer_id, proof_fileurl, status,
    NULL as penjualan_id, 
    created_at, created_by
FROM pembelian;

-- Ganti tabel lama dengan yang baru
DROP TABLE IF EXISTS pembelian;
ALTER TABLE pembelian_new RENAME TO pembelian;

-- ============================================================================
-- B. TABEL DETIL: pembelian_produk
-- ============================================================================

-- Pastikan tabel baseline ada
CREATE TABLE IF NOT EXISTS pembelian_produk (
    id TEXT PRIMARY KEY,
    purchase_id TEXT,
    datetime DATETIME,
    po_number TEXT,
    category TEXT,
    sub_category TEXT,
    name TEXT,
    unit TEXT,
    qty REAL,
    price_per_unit REAL,
    sum_price REAL,
    kadar_air REAL,
    penjualan_produk_id TEXT, -- Kolom baru untuk dropship
    created_at DATETIME,
    created_by TEXT,
    created_timezone TEXT,
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT
);

-- Buat tabel baru dengan struktur paling update
CREATE TABLE IF NOT EXISTS pembelian_produk_new (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    purchase_id TEXT NOT NULL,
    datetime DATETIME NOT NULL,
    po_number TEXT NOT NULL,
    category TEXT NOT NULL,
    sub_category TEXT NOT NULL,
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    qty REAL NOT NULL CHECK(qty > 0),
    price_per_unit REAL NOT NULL CHECK(price_per_unit >= 0),
    sum_price REAL NOT NULL CHECK(sum_price >= 0),
    kadar_air REAL,

    -- Relasi Dropship (New Column Update)
    penjualan_produk_id TEXT,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- Relationships
    FOREIGN KEY (purchase_id) REFERENCES pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Pindahkan data produk
INSERT INTO pembelian_produk_new (
    id, purchase_id, datetime, po_number, category, sub_category, 
    name, unit, qty, price_per_unit, sum_price, kadar_air, 
    penjualan_produk_id, created_at, created_by
)
SELECT 
    id, purchase_id, datetime, po_number, category, sub_category, 
    name, unit, qty, price_per_unit, sum_price, kadar_air, 
    NULL as penjualan_produk_id, 
    created_at, created_by
FROM pembelian_produk;

DROP TABLE IF EXISTS pembelian_produk;
ALTER TABLE pembelian_produk_new RENAME TO pembelian_produk;

-- ============================================================================
-- C. TABEL DETIL: pembelian_biaya (Baseline)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pembelian_biaya (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    purchase_id TEXT NOT NULL,
    datetime DATETIME NOT NULL,
    po_number TEXT NOT NULL,
    type TEXT NOT NULL,
    cost REAL NOT NULL CHECK(cost >= 0),
    description TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',
    FOREIGN KEY (purchase_id) REFERENCES pembelian(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- D. INDEX & TRIGGERS
-- ============================================================================

-- Indexing
CREATE INDEX IF NOT EXISTS idx_pembelian_datetime ON pembelian(datetime);
CREATE INDEX IF NOT EXISTS idx_pembelian_po_number ON pembelian(po_number);
CREATE INDEX IF NOT EXISTS idx_pembelian_supplier_id ON pembelian(supplier_id);
CREATE INDEX IF NOT EXISTS idx_pembelian_customer_id ON pembelian(customer_id);
CREATE INDEX IF NOT EXISTS idx_pembelian_bank_and_cash_id ON pembelian(bank_and_cash_id);

CREATE INDEX IF NOT EXISTS idx_pembelian_produk_purchase_id ON pembelian_produk(purchase_id);
CREATE INDEX IF NOT EXISTS idx_pembelian_produk_po_number ON pembelian_produk(po_number);

CREATE INDEX IF NOT EXISTS idx_pembelian_biaya_purchase_id ON pembelian_biaya(purchase_id);
CREATE INDEX IF NOT EXISTS idx_pembelian_biaya_po_number ON pembelian_biaya(po_number);

-- Update Audit Triggers
CREATE TRIGGER IF NOT EXISTS pembelian_update_audit
AFTER UPDATE ON pembelian
FOR EACH ROW
BEGIN
  UPDATE pembelian SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS pembelian_produk_update_audit
AFTER UPDATE ON pembelian_produk
FOR EACH ROW
BEGIN
  UPDATE pembelian_produk SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS pembelian_biaya_update_audit
AFTER UPDATE ON pembelian_biaya
FOR EACH ROW
BEGIN
  UPDATE pembelian_biaya SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- Aktifkan kembali pengecekan foreign key
PRAGMA foreign_keys = ON;
