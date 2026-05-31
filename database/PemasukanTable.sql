-- Table: pemasukan
-- Description: Menyimpan data transaksi pemasukan (Revenue/Income).
-- Standard: Mengikuti aturan DatabaseRule.md, TimeRule.md, dan StorageRule.md

CREATE TABLE IF NOT EXISTS pemasukan (
    -- Identitas Unik (UUID v4) sesuai standar DatabaseRule.md
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Data Transaksi
    transaction_date DATETIME NOT NULL, -- Waktu aktual kejadian (TimeRule.md)
    bank_and_cash_id TEXT NOT NULL,      -- Sumber dana (FK ke bank_and_cash)
    type TEXT NOT NULL,                  -- Kategori/Tipe pemasukan
    description TEXT NOT NULL,           -- Deskripsi pemasukan
    amount REAL NOT NULL CHECK(amount >= 0), -- Nominal pemasukan (Mandatory)
    
    -- Bukti Pemasukan (StorageRule.md)
    -- Disimpan dalam format JSON string array jika lebih dari satu
    proof_urls TEXT NOT NULL,            -- Mandatory sesuai request (*)
    
    -- Status Transaksi
    status TEXT NOT NULL DEFAULT 'clear' CHECK(status IN ('clear', 'unclear')),
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',

    -- Relationship
    FOREIGN KEY (bank_and_cash_id) REFERENCES bank_and_cash(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Index untuk optimasi pencarian
CREATE INDEX IF NOT EXISTS idx_pemasukan_date ON pemasukan(transaction_date);
CREATE INDEX IF NOT EXISTS idx_pemasukan_source ON pemasukan(bank_and_cash_id);
CREATE INDEX IF NOT EXISTS idx_pemasukan_status ON pemasukan(status);

-- Trigger untuk pembaruan updated_at otomatis
CREATE TRIGGER IF NOT EXISTS pemasukan_update_audit
AFTER UPDATE ON pemasukan
FOR EACH ROW
BEGIN
  UPDATE pemasukan 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
