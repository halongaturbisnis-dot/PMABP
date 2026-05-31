-- Table: bank_and_cash
-- Description: Menyimpan data Kas & Bank untuk transaksi finansial.
-- Standard: Mengikuti aturan DatabaseRule.md

CREATE TABLE IF NOT EXISTS bank_and_cash (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Data Utama
    nama_akun TEXT NOT NULL,
    tipe TEXT NOT NULL CHECK(tipe IN ('Kas', 'Bank')),
    
    -- Data Bank (Mandatory jika tipe = 'Bank')
    nama_bank TEXT, 
    nomor_rekening TEXT,
    nama_pemilik TEXT,
    
    -- Status & Proteksi
    is_default INTEGER NOT NULL DEFAULT 0, -- 1 = Default, 0 = Tidak
    is_deletable INTEGER NOT NULL DEFAULT 1, -- 1 = Boleh hapus, 0 = Terproteksi
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'
);

-- Trigger untuk pembaruan updated_at otomatis
CREATE TRIGGER IF NOT EXISTS bank_and_cash_update_audit
AFTER UPDATE ON bank_and_cash
FOR EACH ROW
BEGIN
  UPDATE bank_and_cash 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;

-- Inisialisasi Data Default "Cash" (Kas)
-- Data ini tidak boleh dihapus dan merupakan data kas fisik utama.
INSERT OR IGNORE INTO bank_and_cash (
    nama_akun, 
    tipe, 
    is_default, 
    is_deletable
) VALUES (
    'Cash', 
    'Kas', 
    1, 
    0
);
