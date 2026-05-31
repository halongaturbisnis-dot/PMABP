import { getTursoClient } from './src/logic/api/turso';
import * as dotenv from 'dotenv';
dotenv.config();

async function migrate() {
    const client = getTursoClient();
    try {
        console.log("Adding is_active column to akun...");
        await client.execute('ALTER TABLE akun ADD COLUMN is_active INTEGER DEFAULT 1;');
        console.log("Adding sales_id column to pemasukan...");
        await client.execute('ALTER TABLE pemasukan ADD COLUMN sales_id TEXT;');
        console.log("Success!");
    } catch(e) {
        console.log("Failed, column might already exist:", e);
    }
}
migrate();
