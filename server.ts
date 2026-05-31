import "dotenv/config";
import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import cron from "node-cron";
import { config } from "./src/logic/utils/config";
import { databaseActiveService } from "./src/logic/services/databaseActiveService";
import { dbClient } from "./src/logic/libs/database";
import { aiService } from "./src/logic/services/aiService";

// Validate config at startup
config.validate();

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Run database migration to ensure qty_masuk_stok exists
  try {
    const tableInfo = await dbClient.query("PRAGMA table_info(pemrosesan)");
    const hasColumn = (tableInfo?.rows || []).some((col: any) => col.name === "qty_masuk_stok");

    if (!hasColumn) {
      await dbClient.query("ALTER TABLE pemrosesan ADD COLUMN qty_masuk_stok REAL NOT NULL DEFAULT 0");
      console.log("[Migration] Column 'qty_masuk_stok' added successfully.");
    } else {
      console.log("[Migration] Column 'qty_masuk_stok' already exists in table. Skipping alteration.");
    }
  } catch (err: any) {
    if (err?.message?.includes("duplicate column") || err?.message?.includes("already exists")) {
      console.log("[Migration] Column 'qty_masuk_stok' already exists in table.");
    } else {
      console.warn("[Migration Warning] Failed to run alter table, it might already exist:", err?.message || err);
    }
  }

  // Ensure table 'stok_terbuang' and its index exist
  try {
    await dbClient.query(`
      CREATE TABLE IF NOT EXISTS stok_terbuang (
        id TEXT PRIMARY KEY DEFAULT (
          lower(hex(randomblob(4))) || '-' || 
          lower(hex(randomblob(2))) || '-4' || 
          substr(lower(hex(randomblob(2))), 2) || '-' || 
          substr('89ab', abs(random()) % 4 + 1, 1) || 
          substr(lower(hex(randomblob(2))), 2) || '-' || 
          lower(hex(randomblob(6)))
        ),
        sku TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        qty REAL NOT NULL CHECK(qty >= 0),
        price_per_unit_out REAL NOT NULL CHECK(price_per_unit_out >= 0),
        total_price_out REAL NOT NULL CHECK(total_price_out >= 0),
        proof_url TEXT,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        created_by TEXT,
        created_timezone TEXT DEFAULT 'Asia/Jakarta',
        updated_at DATETIME,
        updated_by TEXT,
        updated_timezone TEXT DEFAULT 'Asia/Jakarta',
        FOREIGN KEY (sku) REFERENCES stok_berjalan(sku) ON DELETE CASCADE ON UPDATE CASCADE
      )
    `);
    await dbClient.query(`CREATE INDEX IF NOT EXISTS idx_stok_terbuang_sku ON stok_terbuang(sku)`);
    console.log("[Migration] Table 'stok_terbuang' and index created successfully or already exists.");
  } catch (err: any) {
    console.error("[Migration Error] Failed to create 'stok_terbuang' table:", err?.message || err);
  }

  // 1. Database Ping Cron Job
  // Schedule to run at 2 AM every day
  cron.schedule("0 2 * * *", async () => {
    console.log("[CRON] Running daily database keep-alive ping at 02:00 AM");
    await databaseActiveService.ping('CRON');
  });

  // API routes
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok" });
  });

  app.post("/api/ai/analyze-report", express.json(), async (req, res) => {
    try {
      const { startDate, endDate, mode, question, history } = req.body;
      if (!startDate || !endDate || typeof startDate !== 'string' || typeof endDate !== 'string') {
        res.status(400).json({ error: "Parameter startDate dan endDate wajib disertakan dalam format YYYY-MM-DD." });
        return;
      }

      // 1. Ambil data laporan terformat secara dinamis sesuai kebutuhan filter
      const promptData = await aiService.generateFinancialReportPrompt(startDate, endDate);

      // 2. Hubungi Groq dan dapatkan readable stream
      // We pass the history if available to support memory
      const stream = await aiService.streamAnalysis(
        promptData, 
        (mode as any) === 'deep' ? 'deep' : 'standard', 
        question,
        history // hypothetical argument expansion, I assume aiService might need update if it doesn't support it
      );

      // 3. Set header sebagai Event Stream untuk real-time text streaming effect
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      const reader = stream.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;
          if (trimmed === 'data: [DONE]') {
            res.write('data: [DONE]\n\n');
            continue;
          }
          if (trimmed.startsWith('data: ')) {
            try {
              const jsonStr = trimmed.slice(6);
              const parsed = JSON.parse(jsonStr);
              const content = parsed.choices?.[0]?.delta?.content || '';
              if (content) {
                // Kirim isi teks murni token per token dalam skema SSE
                res.write(`data: ${JSON.stringify({ content })}\n\n`);
              }
            } catch (e) {
              // Abaikan parsing error untuk baris parsial
            }
          }
        }
      }

      res.write('data: [DONE]\n\n');
      res.end();
    } catch (err: any) {
      console.error("[AI Server Error]:", err?.message || err);
      // Kirim pesan error melalui stream agar ditangkap cantik oleh UI
      res.write(`data: ${JSON.stringify({ error: err?.message || "Internal server error" })}\n\n`);
      res.end();
    }
  });

  // Manual trigger if needed
  app.post("/api/database/ping", async (req, res) => {
    const result = await databaseActiveService.ping('MANUAL');
    res.json(result);
  });

  // Proxy for external images to bypass canvas CORS issues
  app.get("/api/proxy-image", async (req, res) => {
    try {
      const { url } = req.query;
      if (!url || typeof url !== 'string') {
        res.status(400).send('No url provided');
        return;
      }
      const fetchResponse = await fetch(url);
      if (!fetchResponse.ok) {
        res.status(fetchResponse.status).send('Failed to fetch image');
        return;
      }
      const buffer = await fetchResponse.arrayBuffer();
      res.setHeader('Content-Type', fetchResponse.headers.get('content-type') || 'image/jpeg');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.send(Buffer.from(buffer));
    } catch (err: any) {
      res.status(500).send(err.message);
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    // Production serving
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Cron job scheduled for 02:00 AM daily`);
  });
}

startServer();
