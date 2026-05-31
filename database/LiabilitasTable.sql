-- Table: liabilitas, liabilitas_pembayaran
-- Description: Skema database untuk modul Liabilitas (Hutang/Kewajiban).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

-- 1. Tabel Utama: liabilitas
CREATE TABLE IF NOT EXISTS liabilitas (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Tanggal Muncul Liabilitas
    datetime DATETIME NOT NULL,
    
    -- Deskripsi / Nama Liabilitas
    name TEXT NOT NULL,
    
    -- Catatan Tambahan (Optional)
    description TEXT,
    
    -- Kategori (Misal: Pembelian, Pinjaman, Operasional)
    category TEXT NOT NULL CHECK(category IN ('Pembelian', 'Pinjaman', 'Operasional', 'Lainnya')),
    
    -- Relasi ke Pembelian (Optional, jika category = 'Pembelian')
    purchase_id TEXT, -- Relasi logis ke pembelian(id)
    
    -- ID Pihak Terkait (Supplier/Lainnya)
    entity_name TEXT NOT NULL, -- Nama Supplier atau Pihak Pemberi Hutang
    
    -- Nilai Pokok Liabilitas
    principal_amount REAL NOT NULL CHECK(principal_amount >= 0),
    
    -- Nilai Terbayar (Akumulasi dari liabilitas_pembayaran)
    paid_amount REAL NOT NULL DEFAULT 0 CHECK(paid_amount >= 0),
    
    -- Sisa Liabilitas (principal_amount - paid_amount)
    outstanding_amount REAL NOT NULL DEFAULT 0 CHECK(outstanding_amount >= 0),
    
    -- Batas Waktu Pelunasan (SLA/Tempo)
    due_date DATETIME,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Active', 'Settled', 'Cancelled')),
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'
);

-- 2. Tabel Detil: liabilitas_pembayaran (Cicilan/Pembayaran Hutang)
CREATE TABLE IF NOT EXISTS liabilitas_pembayaran (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    liabilitas_id TEXT NOT NULL,
    
    -- Tanggal Pembayaran
    payment_date DATETIME NOT NULL,
    
    -- Nominal Pembayaran
    amount REAL NOT NULL CHECK(amount > 0),
    
    -- Metode Pembayaran
    payment_method TEXT NOT NULL CHECK(payment_method IN ('Tunai', 'Non Tunai')),
    
    -- Saluran Finansial (FK ke bank_and_cash)
    bank_and_cash_id TEXT NOT NULL,
    
    -- Relasi ke Pengeluaran (Setiap pembayaran cicilan otomatis jadi pengeluaran)
    expense_id TEXT,
    
    description TEXT,
    
    -- Bukti Pembayaran (JSON String URL)
    proof_urls TEXT,
    
    -- SLA Berikutnya (Jatuh tempo cicilan selanjutnya)
    next_sla DATETIME,
    
    -- Audit Trail
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    FOREIGN KEY (liabilitas_id) REFERENCES liabilitas(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bank_and_cash_id) REFERENCES bank_and_cash(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (expense_id) REFERENCES pengeluaran(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- INDEX
CREATE INDEX IF NOT EXISTS idx_liabilitas_datetime ON liabilitas(datetime);
CREATE INDEX IF NOT EXISTS idx_liabilitas_due_date ON liabilitas(due_date);
CREATE INDEX IF NOT EXISTS idx_liabilitas_purchase_id ON liabilitas(purchase_id);
CREATE INDEX IF NOT EXISTS idx_liabilitas_status ON liabilitas(status);

CREATE INDEX IF NOT EXISTS idx_liabilitas_pay_liabilitas_id ON liabilitas_pembayaran(liabilitas_id);
CREATE INDEX IF NOT EXISTS idx_liabilitas_pay_payment_date ON liabilitas_pembayaran(payment_date);

-- TRIGGER update_at
CREATE TRIGGER IF NOT EXISTS liabilitas_update_audit
AFTER UPDATE ON liabilitas
FOR EACH ROW
BEGIN
  UPDATE liabilitas SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS liabilitas_pembayaran_update_audit
AFTER UPDATE ON liabilitas_pembayaran
FOR EACH ROW
BEGIN
  UPDATE liabilitas_pembayaran SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- ==============================================================================
-- MIGRATION SCRIPT (Untuk Database yang Sudah Ada Sebelum next_sla Dibuat)
-- ==============================================================================
-- Jika Anda mengupdate database yang sudah ada sebelumnya, silakan jalankan
-- perintah ALTER TABLE berikut ini secara manual di Turso CLI / UI Anda.
-- (SQLite tidak mendukung fitur IF NOT EXISTS pada klausa ALTER TABLE ADD COLUMN)
-- 
-- ALTER TABLE liabilitas_pembayaran ADD COLUMN next_sla DATETIME;
-- ==============================================================================
