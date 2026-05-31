import { getTursoClient } from './src/logic/api/turso';
import * as dotenv from 'dotenv';
dotenv.config();

async function migrate() {
    const client = getTursoClient();
    try {
        console.log("Adding purchase_id column to pengeluaran...");
        await client.execute('ALTER TABLE pengeluaran ADD COLUMN purchase_id TEXT;');
        console.log("Success!");
    } catch(e) {
        console.log("Failed, column might already exist:", e);
    }
}
migrate();
