# ⚡ QUICK START - 30 MINUTES TO RUNNING SYSTEM

## Prerequisites Check (5 min)
```bash
# 1. Verify Docker installed
docker --version
docker-compose --version

# Should show: Docker version 20.10+ and Docker Compose 2.0+
# If not: Download from https://www.docker.com/products/docker-desktop

# 2. Verify you have these files in your project directory:
ls -la docker-compose.postgres.yml
ls -la docker-compose.n8n.yml
ls -la schema.sql
ls -la start.sh
ls -la .env.example  # or .env
```

---

## Installation (20 min)

### Step 1: Prepare Directory
```bash
# Create project directory
mkdir ~/optima-scraper
cd ~/optima-scraper

# Download all files from outputs (OR copy-paste each file)
# Make sure you have:
# - docker-compose.postgres.yml
# - docker-compose.n8n.yml
# - schema.sql
# - init_db.sql
# - start.sh
# - stop.sh
# - .env (or copy from .env.example)
```

### Step 2: Setup Environment
```bash
# If you only have .env.example:
cp .env.example .env

# Edit .env and change passwords (IMPORTANT!)
# Replace these values:
# - POSTGRES_PASSWORD=YourSecurePassword123!
# - N8N_BASIC_AUTH_PASSWORD=YourN8NPassword!
nano .env
```

### Step 3: Make Scripts Executable
```bash
chmod +x start.sh
chmod +x stop.sh
```

### Step 4: Clone Firecrawl (First Time Only)
```bash
# Firecrawl will be cloned automatically by start.sh
# OR clone manually:
git clone https://github.com/firecrawl/firecrawl.git

# Important: Copy your custom docker-compose.yml to firecrawl/ directory
# (The start.sh script handles this, but you can do it manually too)
```

### Step 5: Start Everything!
```bash
# Run the startup script (handles all Docker operations)
bash start.sh

# Expected output after 3-5 minutes:
# ✨ System Startup Complete!
# 📍 Access Points:
#   n8n: http://localhost:5678
#   pgAdmin: http://localhost:5050
#   Firecrawl API: http://localhost:3002
```

---

## Verification (5 min)

### ✅ Open Access Points

1. **n8n (Workflow)**: http://localhost:5678
   - User: `admin`
   - Password: Value from .env (N8N_BASIC_AUTH_PASSWORD)
   - You should see n8n dashboard

2. **pgAdmin (Database UI)**: http://localhost:5050
   - Email: `admin@optima.local`
   - Password: `AdminOptima123!@#`
   - You can browse database

3. **Firecrawl API**: http://localhost:3002/health
   - Should show: `{"status":"ok"}`

### ✅ Quick Database Test

```bash
# Connect to database
psql -h localhost -U optima_user -d optima_erp

# Inside psql, run:
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema IN ('scraping', 'erp');

# Should show: 9 (all tables created)
# Type: \q to exit
```

### ✅ Test Firecrawl

```bash
# Test health endpoint
curl http://localhost:3002/health

# Should return:
# {"status":"ok"}
```

---

## First Test Run (5-10 min)

### Create Simple Test Workflow in n8n

1. **Login to n8n**: http://localhost:5678

2. **Create Workflow**:
   - Click "+ New"
   - Name: "Test Price Scraper"

3. **Add Nodes**:
   - Node 1: Manual Trigger (click "Execute")
   - Node 2: HTTP Request
     - URL: `http://firecrawl-api:3002/health`
     - Method: GET
   - Node 3: Debug node (for viewing output)

4. **Execute**:
   - Click the play button
   - Should show green "success" indicator
   - Output shows: `{"status":"ok"}`

5. **Save**: Ctrl+S

---

## Insert Sample Data

### Add Test URLs to Database

```bash
# Connect to database
psql -h localhost -U optima_user -d optima_erp

# Add sample competitor to track
INSERT INTO scraping.price_monitoring_targets 
(website_name, url_target, domain_name, category) 
VALUES 
('Test Shop', 'https://tokopedia.com/search?q=lampu+led', 'tokopedia.com', 'marketplace');

# Add sample lead source
INSERT INTO scraping.lead_generation_targets 
(source_name, url_target, domain_name, category) 
VALUES 
('Test Directory', 'https://www.google.com', 'google.com', 'directory');

# Type: \q to exit
```

---

## Configure API Keys

### For AI Extraction (Choose ONE)

**Option A: Use Ollama (FREE, LOCAL)**
- Already installed if you ran start.sh with default settings
- Model: Mistral (lightweight, fast)
- No API key needed!

**Option B: Use OpenAI (PAID but better)**

1. Get API key from https://platform.openai.com/api-keys
2. Edit `.env`:
   ```
   LLM_PROVIDER=openai
   LLM_API_KEY=sk-proj-YOUR_KEY_HERE
   LLM_MODEL_NAME=gpt-4-turbo
   ```
3. Restart Firecrawl:
   ```bash
   cd firecrawl
   docker-compose down
   docker-compose up -d
   cd ..
   ```

**Option C: Use Claude via OpenRouter (PAID)**
1. Get key from https://openrouter.ai/
2. Edit `.env`:
   ```
   LLM_PROVIDER=openrouter
   LLM_API_KEY=sk-or-YOUR_KEY_HERE
   LLM_MODEL_NAME=anthropic/claude-3-sonnet
   ```

---

## Common Commands

```bash
# View all running containers
docker ps

# View logs (follow in real-time)
docker logs -f optima-n8n
docker logs -f firecrawl-api
docker logs -f optima-postgres

# Restart a service
docker restart optima-n8n

# Stop everything (keeps data)
bash stop.sh

# Stop and remove everything (DELETES DATA!)
docker-compose down -v

# View database
psql -h localhost -U optima_user -d optima_erp

# Backup database
docker exec optima-postgres pg_dump -U optima_user optima_erp > backup.sql
```

---

## Next: Create Real Workflows

Once verified, you're ready to create actual workflows:

1. **Price Monitoring Workflow**
   - Scrape e-commerce product pages
   - Extract: name, price, brand, specs
   - Insert to database
   - Run daily/hourly

2. **Lead Generation Workflow**
   - Crawl business directories
   - Extract: company name, contact, phone, email
   - Insert to CRM database
   - Run weekly

See full documentation in `SETUP_GUIDE_LENGKAP.md` section 7 & 8.

---

## Troubleshooting

**Something not working?** Check:

1. Are all containers running?
   ```bash
   docker ps
   # All 6 should show "Up"
   ```

2. Check logs:
   ```bash
   docker logs optima-n8n 2>&1 | tail -50
   ```

3. Try restart:
   ```bash
   docker-compose -f docker-compose.n8n.yml restart optima-n8n
   ```

4. Full reset:
   ```bash
   bash stop.sh
   sleep 10
   bash start.sh
   ```

**Still stuck?** → See `TROUBLESHOOTING_GUIDE.md` for detailed solutions.

---

## Success Checklist ✓

- [ ] Docker installed and running
- [ ] All 6 containers started (docker ps shows 6 "Up")
- [ ] Can login to n8n (http://localhost:5678)
- [ ] Can access pgAdmin (http://localhost:5050)
- [ ] Firecrawl health check passes (http://localhost:3002/health)
- [ ] Database has 9 tables created
- [ ] Created and executed test workflow in n8n
- [ ] API keys configured for LLM extraction

**Congratulations! Your system is ready.** 🎉

---

**Estimated Time**: 30 minutes (one-time setup)  
**Questions?** See full guides:
- `SETUP_GUIDE_LENGKAP.md` - Complete documentation
- `TROUBLESHOOTING_GUIDE.md` - Problem solving
