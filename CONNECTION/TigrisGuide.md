# Panduan Integrasi Tigris Storage (S3 Compatible) di Google AI Studio

Dokumen ini menjelaskan langkah-langkah untuk mengintegrasikan Tigris Storage sebagai solusi penyimpanan file (Object Storage) yang kompatibel dengan protokol S3.

## 1. Persiapan di Dashboard Tigris

1. **Buat Bucket**: Buat bucket baru (contoh nama: `fakhri`).
2. **Pengaturan Akses (Access and Sharing)**:
   - Atur **Public / Private Access** menjadi **Public**.
   - Matikan (OFF) **Allow Object ACL** (Tigris merekomendasikan penggunaan kebijakan bucket untuk publik).
   - Pastikan **Disable Directory Listing** aktif (ON) untuk keamanan folder.
3. **Dapatkan Access Keys**:
   - Di tab **Access Keys**, buat key baru.
   - Salin dan simpan nilai berikut:
     - `Access Key ID`
     - `Secret Access Key`
     - `Endpoint URL S3` (Biasanya `https://t3.storage.dev`)

## 2. Konfigurasi Environment Variables di Google AI Studio

Buka menu **Settings** di Google AI Studio dan masukkan variabel berikut:

| Nama Variabel | Contoh Nilai | Keterangan |
| :--- | :--- | :--- |
| `TIGRIS_STORAGE_ACCESS_KEY_ID` | `tid_...` | ID Kunci Akses dari Tigris |
| `TIGRIS_STORAGE_SECRET_ACCESS_KEY` | `tsec_...` | Kunci Rahasia dari Tigris |
| `TIGRIS_STORAGE_ENDPOINT` | `https://t3.storage.dev` | Endpoint S3 Tigris |
| `TIGRIS_STORAGE_BUCKET` | `fakhri` | Nama bucket yang Anda buat |

## 3. Implementasi Kode Backend (Express)

Gunakan `@aws-sdk/client-s3` untuk berinteraksi dengan Tigris.

```typescript
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const s3Client = new S3Client({
  region: "auto",
  endpoint: process.env.TIGRIS_STORAGE_ENDPOINT,
  credentials: {
    accessKeyId: process.env.TIGRIS_STORAGE_ACCESS_KEY_ID,
    secretAccessKey: process.env.TIGRIS_STORAGE_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true, // WAJIB untuk Tigris
});
```

### Logika Upload dan Public URL
Untuk bucket publik, format URL akses langsung adalah:
`https://<nama-bucket>.t3.tigrisfiles.io/<key-file>`

Contoh implementasi upload:
```typescript
await s3Client.send(new PutObjectCommand({
  Bucket: process.env.TIGRIS_STORAGE_BUCKET,
  Key: `folder/${filename}`,
  Body: fileBuffer,
  ContentType: "application/pdf"
}));

const publicUrl = `https://${process.env.TIGRIS_STORAGE_BUCKET}.t3.tigrisfiles.io/folder/${filename}`;
```

## 4. Troubleshooting
- **Access Denied**: Pastikan bucket diset ke **Public**.
- **URL Tidak Bisa Dibuka**: Gunakan format subdomain `.t3.tigrisfiles.io` untuk akses langsung via browser.
- **CORS Error**: Atur CORS di dashboard Tigris jika melakukan upload langsung dari browser (Client-side). Dalam panduan ini, upload dilakukan via Backend (Server-side) untuk keamanan.
