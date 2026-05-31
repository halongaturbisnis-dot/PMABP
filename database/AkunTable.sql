-- Table: akun
-- Description: Menyimpan data akun pengguna untuk autentikasi dan otorisasi modul.
-- Standard: Mengikut aturan DatabaseRule.md dan StorageRule.md (untuk foto profil)

CREATE TABLE IF NOT EXISTS akun (
    -- Identitas Unik (UUID v4)
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    
    -- Kredensial & Identitas
    kode_akses TEXT NOT NULL UNIQUE, -- Digunakan untuk Login
    password TEXT NOT NULL,         -- Hash password (disarankan hash di level aplikasi)
    username TEXT NOT NULL,
    foto_profil TEXT,               -- URL file di Tigris Storage
    telepon TEXT,
    
    -- Otorisasi
    jabatan TEXT NOT NULL,
    peran TEXT NOT NULL CHECK(peran IN ('User', 'Admin', 'Guest')),
    akses_modul TEXT NOT NULL,      -- Array JSON berisi daftar modul yang diizinkan
    has_invoice_approval INTEGER DEFAULT 0, -- 1 jika memiliki hak akses invoice approval, 0 jika tidak
    is_active INTEGER DEFAULT 1,    -- 1 jika Aktif, 0 jika Non-Aktif
    
    -- Audit Trail (Mandatory sesuai DatabaseRule.md)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,                -- UUID User pembuat (Null jika pendaftaran mandiri/pertama)
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    
    updated_at DATETIME,
    updated_by TEXT,                -- UUID User pengubah terakhir
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'
);

-- Index untuk performa login
CREATE INDEX IF NOT EXISTS idx_akun_kode_akses ON akun(kode_akses);

-- Trigger untuk pembaruan updated_at otomatis
CREATE TRIGGER IF NOT EXISTS akun_update_audit
AFTER UPDATE ON akun
FOR EACH ROW
BEGIN
  UPDATE akun 
  SET updated_at = CURRENT_TIMESTAMP 
  WHERE id = OLD.id;
END;
