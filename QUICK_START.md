# QUICK START - PT Optima Smartindo Web Scraping System

## Kondisi Awal
- PC baru dengan Docker Desktop terinstall
- Belum ada file project apapun

## Apa yang Akan Terinstall
| Service | Port | Fungsi |
|---------|------|--------|
| PostgreSQL | 5432 | Database utama (9 tabel, views, functions) |
| pgAdmin | 5050 | UI manajemen database (via browser) |
| Redis | 6379 | Queue & cache untuk n8n |
| n8n | 5678 | Workflow automation (via browser) |

---

## Step 1: Siapkan File (2 menit)

Buat folder project dan masukkan semua file:

```bash
mkdir ~/optima-scraper
cd ~/optima-scraper
```

Pastikan folder berisi file berikut:
```
optima-scraper/
├── docker-compose.yml    ← Konfigurasi semua container
├── .env                  ← Password & settings
├── init_db.sql           ← Inisialisasi database
├── schema.sql            ← 9 tabel + views + functions
├── start.sh              ← Script untuk start
├── stop.sh               ← Script untuk stop
└── health-check.sh       ← Script cek kesehatan sistem
```

## Step 2: Edit Password (1 menit)

Buka file `.env` dengan text editor dan ubah password jika diinginkan:

```bash
notepad .env        # Windows
nano .env           # Linux/Mac
```

Yang perlu diperhatikan:
- `POSTGRES_PASSWORD` — password database
- `N8N_BASIC_AUTH_PASSWORD` — password login n8n
- `PGADMIN_PASSWORD` — password pgAdmin

## Step 3: Pastikan Docker Desktop Berjalan

Buka Docker Desktop dan pastikan statusnya "Running" (ikon hijau).

## Step 4: Jalankan Sistem (3-5 menit)

```bash
cd ~/optima-scraper
bash start.sh
```

Tunggu sampai muncul pesan "System Startup Complete!".

Pertama kali akan download Docker images (~1-2 GB), jadi butuh waktu
lebih lama tergantung koneksi internet.

## Step 5: Verifikasi (2 menit)

Buka browser dan akses:

1. **n8n** — http://localhost:5678
   - User: `admin`
   - Password: `Optima2024` (atau sesuai .env)

2. **pgAdmin** — http://localhost:5050
   - Email: `admin@optima.local`
   - Password: `AdminOptima123` (atau sesuai .env)

Atau jalankan:
```bash
bash health-check.sh
```

---

## Perintah Sehari-hari

```bash
bash start.sh           # Start semua service
bash stop.sh            # Stop semua service (data aman)
bash health-check.sh    # Cek status semua service
docker compose logs -f  # Lihat log realtime
```

---

## Setup pgAdmin (Pertama Kali)

Setelah login ke pgAdmin (http://localhost:5050):

1. Klik "Add New Server"
2. Tab **General**: Name = `Optima ERP`
3. Tab **Connection**:
   - Host: `optima-postgres`
   - Port: `5432`
   - Database: `optima_erp`
   - Username: `optima_user`
   - Password: `OptimaSmartin123` (atau sesuai .env)
4. Klik Save

Anda akan melihat 2 schema: `scraping` dan `erp` dengan 9 tabel.

---

## Langkah Selanjutnya: Firecrawl

Sistem saat ini sudah menjalankan PostgreSQL + n8n + pgAdmin.
Firecrawl (mesin scraping) perlu disetup terpisah karena butuh
build dari source code. Langkah-langkah:

1. Clone Firecrawl repository
2. Konfigurasi LLM provider (OpenAI/Ollama)
3. Hubungkan ke network Docker yang sama
4. Test dari n8n workflow

Detail ada di SETUP_GUIDE_LENGKAP.md bagian 4.

---

## Troubleshooting Cepat

**Docker Desktop not running:**
- Buka Docker Desktop, tunggu sampai statusnya hijau

**Port sudah dipakai:**
```bash
# Windows: cari proses yang pakai port
netstat -ano | findstr :5678

# Linux/Mac:
lsof -i :5678
```

**Reset total (hapus semua data):**
```bash
docker compose down -v
bash start.sh
```
