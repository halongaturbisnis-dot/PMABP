import { getTursoClient } from './src/logic/api/turso';
import * as dotenv from 'dotenv';
dotenv.config();

async function migrate() {
    const client = getTursoClient();
    try {
        console.log("Creating Piutang tables...");
        await client.execute(`
CREATE TABLE IF NOT EXISTS piutang (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    datetime DATETIME NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK(category IN ('Penjualan', 'Pinjaman', 'Operasional', 'Lainnya')),
    sales_id TEXT,
    entity_name TEXT NOT NULL,
    principal_amount REAL NOT NULL CHECK(principal_amount >= 0),
    paid_amount REAL NOT NULL DEFAULT 0 CHECK(paid_amount >= 0),
    outstanding_amount REAL NOT NULL DEFAULT 0 CHECK(outstanding_amount >= 0),
    due_date DATETIME,
    status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Active', 'Settled', 'Cancelled')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta'
);`);

        await client.execute(`
CREATE TABLE IF NOT EXISTS piutang_pembayaran (
    id TEXT PRIMARY KEY DEFAULT (
        lower(hex(randomblob(4))) || '-' || 
        lower(hex(randomblob(2))) || '-4' || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        substr('89ab', abs(random()) % 4 + 1, 1) || 
        substr(lower(hex(randomblob(2))), 2) || '-' || 
        lower(hex(randomblob(6)))
    ),
    piutang_id TEXT NOT NULL,
    payment_date DATETIME NOT NULL,
    amount REAL NOT NULL CHECK(amount > 0),
    payment_method TEXT NOT NULL CHECK(payment_method IN ('Tunai', 'Non Tunai')),
    bank_and_cash_id TEXT NOT NULL,
    income_id TEXT,
    description TEXT,
    proof_urls TEXT,
    next_sla DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT,
    created_timezone TEXT DEFAULT 'Asia/Jakarta',
    updated_at DATETIME,
    updated_by TEXT,
    updated_timezone TEXT DEFAULT 'Asia/Jakarta',
    FOREIGN KEY (piutang_id) REFERENCES piutang(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bank_and_cash_id) REFERENCES bank_and_cash(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (income_id) REFERENCES pemasukan(id) ON DELETE SET NULL ON UPDATE CASCADE
);`);

        await client.execute(`CREATE INDEX IF NOT EXISTS idx_piutang_datetime ON piutang(datetime);`);
        await client.execute(`CREATE INDEX IF NOT EXISTS idx_piutang_due_date ON piutang(due_date);`);
        await client.execute(`CREATE INDEX IF NOT EXISTS idx_piutang_sales_id ON piutang(sales_id);`);
        await client.execute(`CREATE INDEX IF NOT EXISTS idx_piutang_status ON piutang(status);`);

        await client.execute(`CREATE INDEX IF NOT EXISTS idx_piutang_pay_piutang_id ON piutang_pembayaran(piutang_id);`);
        await client.execute(`CREATE INDEX IF NOT EXISTS idx_piutang_pay_payment_date ON piutang_pembayaran(payment_date);`);

        await client.execute(`
CREATE TRIGGER IF NOT EXISTS piutang_update_audit
AFTER UPDATE ON piutang
FOR EACH ROW
BEGIN
  UPDATE piutang SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;`);

        await client.execute(`
CREATE TRIGGER IF NOT EXISTS piutang_pembayaran_update_audit
AFTER UPDATE ON piutang_pembayaran
FOR EACH ROW
BEGIN
  UPDATE piutang_pembayaran SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;`);
        console.log("Success!");
    } catch(e) {
        console.log("Failed:", e);
    }
}
migrate();
