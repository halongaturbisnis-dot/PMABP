# Guidance: Environment Switching (EnvironmentSwitchingRule)

## 1. Filosofi Utama: Build Once, Run Anywhere
Aplikasi ini dikembangkan untuk berjalan mulus di **Google AI Studio (Development)** dan **Vercel (Production)** tanpa memerlukan perubahan kode manual saat berpindah environment.

### Prinsip Utama:
- **Agnostic Logic**: Logika backend dan frontend tidak boleh "hardcoded" merujuk pada satu platform spesifik.
- **Environment Discovery**: Gunakan `config.ts` sebagai satu-satunya gerbang akses ke variabel lingkungan.
- **Vite Standard-Compliant**: Gunakan prefix `VITE_` untuk variabel yang dibutuhkan di sisi client agar kompatibel dengan sistem build modern.

---

## 2. Struktur Pengelolaan Environment
Semua akses environment variable WAJIB melalui `src/logic/utils/config.ts`.

### Aturan Penamaan:
| Platform | Client Variable (Prefixed) | Server Variable (Secret) |
| :--- | :--- | :--- |
| **Development (AI Studio)** | `VITE_APP_URL` | `GEMINI_API_KEY` |
| **Production (Vercel)** | `VITE_APP_URL` | `GEMINI_API_KEY` |

**DILARANG** mengakses `process.env` atau `import.meta.env` secara langsung di dalam komponen UI.

---

## 3. Strategi Switching Otomatis

### A. API Base URL
Selalu gunakan relative path atau variabel `config.appUrl`. Jangan pernah hardcode `https://ais-dev-...`.

### B. Feature Flags
Gunakan variabel env untuk mengaktifkan/menonaktifkan fitur yang hanya tersedia di satu platform (misal: Debugger tools di dev, Analytics di prod).

```tsx
// Contoh di config.ts
export const config = {
  isDev: import.meta.env.DEV,
  enableAnalytics: import.meta.env.VITE_ENABLE_ANALYTICS === 'true'
};
```

---

## 4. Penanganan Common Issues (Vercel specific)

1. **Case Sensitivity**: Vercel menggunakan Linux (Case Sensitive). Pastikan semua import file sesuai dengan nama file aslinya (misal: `App.tsx` vs `app.tsx`).
2. **Build Failure**: Pastikan `lint_applet` lolos 100% sebelum mencoba mendeploy. Vercel akan menghentikan build jika ada error TypeScript.
3. **API Proxies**: Jika menggunakan backend proxy di AI Studio (`server.ts`), pastikan konfigurasi `vercel.json` sudah disiapkan untuk mengarahkan route `/api/*` ke serverless functions jika diperlukan.

---

## 5. Invariant: Development-Safe, Deployment-Ready
Setiap file baru yang dibuat harus mengikuti aturan:
- **Satu Sumber Validasi**: Gunakan `config.validate()` untuk memastikan semua variabel kunci tersedia.
- **Default Fallbacks**: Berikan nilai default yang aman jika variabel lingkungan tidak ditemukan, agar aplikasi tidak "White Screen" saat deploy tanpa konfigurasi awal.
