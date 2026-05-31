-- Module: Klaim Retur
-- Description: Database schema for 'Klaim Retur' (Return Claim) module.
-- Contains tables for: klaim_retur and klaim_retur_item.
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, StorageRule.md

-- ==========================================
-- 1. Table: klaim_retur
-- ==========================================
CREATE TABLE IF NOT EXISTS klaim_retur (
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
    invoice_number TEXT NOT NULL,       -- Link ke penjualan.invoice_number
    penjualan_id TEXT NOT NULL,         -- Relasi ke table penjualan
    customer_id TEXT NOT NULL,          -- Relasi ke table customer
    
    -- RINGKASAN KLAIM
    sum_total_refund_nominal REAL NOT NULL DEFAULT 0, -- Total nominal refund yang disetujui
    description TEXT,                   -- Deskripsi umum klaim
    proof_url TEXT,                     -- URL Bukti utama (header level)
    status TEXT DEFAULT 'Pending' CHECK(status IN ('Pending', 'Approved', 'Rejected', 'Completed')),
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (penjualan_id) REFERENCES penjualan(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_klaim_retur_invoice_number ON klaim_retur(invoice_number);
CREATE INDEX IF NOT EXISTS idx_klaim_retur_penjualan_id ON klaim_retur(penjualan_id);
CREATE INDEX IF NOT EXISTS idx_klaim_retur_customer_id ON klaim_retur(customer_id);

CREATE TRIGGER IF NOT EXISTS klaim_retur_update_audit
AFTER UPDATE ON klaim_retur
FOR EACH ROW
BEGIN
  UPDATE klaim_retur 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- ==========================================
-- 2. Table: klaim_retur_item
-- ==========================================
CREATE TABLE IF NOT EXISTS klaim_retur_item (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    klaim_retur_id TEXT NOT NULL,       -- Relasi ke klaim_retur(id)
    penjualan_produk_id TEXT NOT NULL,  -- Relasi ke penjualan_produk(id)
    
    -- DATA PRODUK (Snapshot dari PenjualanProduk)
    name TEXT NOT NULL,                 -- Nama produk yang diklaim
    unit TEXT NOT NULL,                 -- Satuan (misal: kg, pcs)
    qty REAL NOT NULL,                  -- Jumlah yang diklaim/diretur
    
    -- DETAIL KLAIM
    reason TEXT,                        -- Alasan retur per item
    proof_url TEXT,                     -- URL Bukti per item (lampiran)
    policy TEXT NOT NULL CHECK(policy IN ('Replace', 'Refund')), -- Kebijakan: Ganti Barang (Replace) atau Uang Kembali (Refund)
    refund_nominal REAL DEFAULT 0,      -- Nominal refund jika policy = 'Refund'
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- CONSTRAINT RELASI
    FOREIGN KEY (klaim_retur_id) REFERENCES klaim_retur(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (penjualan_produk_id) REFERENCES penjualan_produk(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_klaim_retur_item_header ON klaim_retur_item(klaim_retur_id);
CREATE INDEX IF NOT EXISTS idx_klaim_retur_item_produk ON klaim_retur_item(penjualan_produk_id);

CREATE TRIGGER IF NOT EXISTS klaim_retur_item_update_audit
AFTER UPDATE ON klaim_retur_item
FOR EACH ROW
BEGIN
  UPDATE klaim_retur_item 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
