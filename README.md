# README - PT Optima Smartindo Web Scraping System

## 🎯 EXECUTIVE SUMMARY

Anda sekarang memiliki **lengkap setup package** untuk sistem otomasi pengumpulan data (Web Scraping + Lead Generation) yang siap deploy.

**Sistem terdiri dari:**
- ✅ **Firecrawl** (Web scraping engine dengan AI)
- ✅ **n8n** (Workflow orchestrator)
- ✅ **PostgreSQL** (Database)
- ✅ **Semua konfigurasi & dokumentasi**

**Kebutuhan minimum:**
- PC dengan 8GB RAM
- Docker installed
- 30 menit setup time

---

## 📦 CONTENTS OF THIS PACKAGE

### 📚 Documentation (START HERE!)

1. **QUICK_START.md** ⭐ **START HERE**
   - Fastest way to get running (30 min)
   - Step-by-step instructions
   - No prior Docker knowledge required
   - **Read this first if you just want to start**

2. **FILE_INVENTORY_AND_GUIDE.md** 📋
   - Where to put files
   - What each file does
   - Complete installation guide
   - File descriptions

3. **SETUP_GUIDE_LENGKAP.md** 📖 (COMPLETE REFERENCE)
   - 10,000+ word complete guide
   - Detailed explanations
   - All configuration options
   - Production deployment

4. **TROUBLESHOOTING_GUIDE.md** 🔧
   - Common problems & solutions
   - Testing procedures
   - Debugging tips
   - Monitoring setup

---

### 🐳 Docker Files (COPY TO YOUR PC)

```
docker-compose.postgres.yml  ← Database + pgAdmin
docker-compose.n8n.yml       ← Workflow automation
```

⚠️ **Firecrawl**: Auto-cloned from GitHub by start.sh

---

### 💾 Database Files (COPY TO YOUR PC)

```
init_db.sql    ← Initial setup
schema.sql     ← 9 tables, indexes, views, functions
```

---

### ⚙️ Configuration (COPY & CUSTOMIZE)

```
.env.example   ← Copy to .env and edit with your passwords
```

---

### 🚀 Automation Scripts (COPY & USE)

```
start.sh       ← Run this to start everything (one command!)
stop.sh        ← Run this to stop everything gracefully
```

---

## ⚡ FASTEST PATH TO RUNNING SYSTEM (30 MINUTES)

### Step 1: Copy Files (2 min)
```bash
mkdir ~/optima-scraper
cd ~/optima-scraper

# Copy all 10 files here
# Or download them from outputs
```

### Step 2: Create .env File (2 min)
```bash
cp .env.example .env

# Edit .env with text editor:
nano .env
# Change: POSTGRES_PASSWORD, N8N_BASIC_AUTH_PASSWORD, LLM_API_KEY
```

### Step 3: Make Scripts Executable (1 min)
```bash
chmod +x start.sh stop.sh
```

### Step 4: Run Startup Script (20 min)
```bash
bash start.sh

# Wait for completion... (first run takes 15-20 minutes to build Firecrawl)
# Subsequent runs take only 2-3 minutes
```

### Step 5: Verify & Access (3 min)
```
✅ Open http://localhost:5678 (n8n)
✅ Open http://localhost:5050 (pgAdmin)
✅ Open http://localhost:3002/health (Firecrawl API)

✅ All should work!
```

**Total Time: ~30 minutes** (mostly waiting for Docker builds)

---

## 📍 DEFAULT ACCESS CREDENTIALS

| Service | URL | User | Password |
|---------|-----|------|----------|
| **n8n** | http://localhost:5678 | admin | Optima2024!@# |
| **pgAdmin** | http://localhost:5050 | admin@optima.local | AdminOptima123!@# |
| **PostgreSQL** | localhost:5432 | optima_user | OptimaSmartin123!@# |
| **Firecrawl** | http://localhost:3002 | (no auth) | (no auth) |

⚠️ **IMPORTANT**: Change passwords in `.env` file before production use!

---

## 🎓 WHICH FILE TO READ?

### "I just want to get it running ASAP"
→ **Read: `QUICK_START.md`**
- 30 min to fully operational system
- Minimal explanation, step-by-step
- Good for: First-time setup

### "I want to understand the whole system"
→ **Read: `SETUP_GUIDE_LENGKAP.md`**
- Comprehensive 10,000+ word guide
- Detailed explanations of everything
- All configuration options explained
- Good for: Understanding architecture

### "Something is broken, help!"
→ **Read: `TROUBLESHOOTING_GUIDE.md`**
- Common problems & solutions
- Debugging procedures
- Testing instructions
- Good for: Problem-solving

### "Where do I put files?"
→ **Read: `FILE_INVENTORY_AND_GUIDE.md`**
- File descriptions
- Directory structure
- What each file does
- Good for: Understanding file organization

---

## 🔍 WHAT GETS CREATED

### Docker Containers (6 total)
```
1. optima-postgres          ← PostgreSQL database
2. optima-pgadmin           ← Database UI management
3. firecrawl-api            ← Web scraping engine
4. firecrawl-postgres       ← Firecrawl database
5. firecrawl-redis          ← Job queue/caching
6. optima-n8n               ← Workflow automation
```

### Database (PostgreSQL)
```
2 Schemas: 'scraping' and 'erp'
9 Tables:
  - job_history
  - logs
  - price_monitoring_targets
  - lead_generation_targets
  - competitor_products
  - b2b_leads
  - lead_deduplication
  - data_sync_log
  - lead_contact_history

+ 10+ Indexes for performance
+ 5 SQL Views for BI
+ 2 SQL Functions for operations
```

### Workflows (Ready to create in n8n)
```
✓ Price Monitoring
  └─ Scrape competitor websites
  └─ Extract product data
  └─ Store to database
  └─ Run daily/hourly

✓ Lead Generation
  └─ Crawl business directories
  └─ Extract contact data
  └─ Dedup & quality score
  └─ Insert to CRM
  └─ Run weekly
```

---

## 🚀 AFTER INITIAL SETUP

### Day 1: Verify System Works
- [ ] All containers running (docker ps)
- [ ] Can login to n8n
- [ ] Can access pgAdmin
- [ ] Can execute test workflow

### Day 2-3: Create First Workflows
- [ ] Price monitoring workflow
- [ ] Lead generation workflow
- [ ] Configure extraction prompts
- [ ] Test with real websites

### Day 4-5: Automate & Schedule
- [ ] Setup daily/hourly triggers
- [ ] Configure email notifications
- [ ] Setup backup procedures
- [ ] Monitor performance

### Day 6+: Optimize & Maintain
- [ ] Fine-tune extraction prompts
- [ ] Add more data sources
- [ ] Monitor data quality
- [ ] Regular backups

---

## 🔧 ESSENTIAL COMMANDS

### Start/Stop System
```bash
bash start.sh    # Start all containers
bash stop.sh     # Stop all containers gracefully
```

### View Status
```bash
docker ps                          # List running containers
docker logs -f optima-n8n         # View n8n logs
docker logs -f firecrawl-api      # View Firecrawl logs
```

### Access Database
```bash
psql -h localhost -U optima_user -d optima_erp

# Inside psql:
SELECT COUNT(*) FROM erp.competitor_products;
SELECT COUNT(*) FROM erp.b2b_leads;
\dt scraping.*    # List tables
\q               # Exit
```

### Backup Database
```bash
docker exec optima-postgres pg_dump -U optima_user optima_erp > backup_$(date +%Y%m%d).sql
```

### View Workflows
```bash
# Browser: http://localhost:5678
# Or in database:
psql -h localhost -U optima_user -d optima_erp
SELECT * FROM n8n_workflow WHERE name LIKE '%Price%';
```

---

## 📋 SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────┐
│         WEB SCRAPING AUTOMATION SYSTEM              │
│         PT Optima Smartindo Industry                 │
└─────────────────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
    ┌───▼──┐   ┌───▼──┐   ┌───▼──┐
    │  n8n │   │ Fire │   │  DB  │
    │ :5678│   │crawl │   │:5432 │
    │      │   │:3002 │   │      │
    └──────┘   └──────┘   └──────┘
        │          │         │
        └──────────┼─────────┘
                   │
          (Docker Network: optima-network)
          (All containers on same internal network)
          (All data persistent in Docker volumes)
```

**Data Flow:**
```
n8n Triggers
    ↓
Firecrawl scrapes website
    ↓
AI extracts structured data
    ↓
n8n transforms data
    ↓
PostgreSQL stores in tables
    ↓
Data available for BI/reporting
```

---

## ✅ QUICK VERIFICATION

### All Containers Running?
```bash
docker ps | wc -l
# Should show: 7 (6 running + header line)
```

### All Services Responding?
```bash
curl http://localhost:5678/healthz    # n8n
curl http://localhost:3002/health     # Firecrawl
psql -h localhost -c "SELECT 1;"      # PostgreSQL
```

### Database Tables Created?
```bash
psql -h localhost -U optima_user -d optima_erp -c \
"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('scraping', 'erp');"
# Should return: 9
```

---

## ⚠️ COMMON GOTCHAS

### "Port already in use"
```bash
# Find process using port
lsof -i :5678

# Kill it
kill -9 <PID>

# Or change port in docker-compose file
```

### "Docker not installed"
```bash
# Download: https://www.docker.com/products/docker-desktop
# Then verify: docker --version
```

### "PostgreSQL connection refused"
```bash
# Wait 10 seconds after start.sh
sleep 10

# Then try again
psql -h localhost -U optima_user -d optima_erp -c "SELECT 1;"
```

### "LLM API not working"
```bash
# Check your API key in .env
# For OpenAI: Must start with "sk-proj-"
# For Ollama: No key needed

# Restart Firecrawl
cd firecrawl
docker-compose restart firecrawl-api
```

---

## 📞 SUPPORT & RESOURCES

### Documentation In This Package
- `QUICK_START.md` - Fast setup guide
- `SETUP_GUIDE_LENGKAP.md` - Complete reference
- `TROUBLESHOOTING_GUIDE.md` - Problem solving
- `FILE_INVENTORY_AND_GUIDE.md` - File descriptions

### External Resources
- **Firecrawl Docs**: https://docs.firecrawl.dev/
- **n8n Docs**: https://docs.n8n.io/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Docker Docs**: https://docs.docker.com/

### Useful Commands
```bash
# View logs in real-time
docker logs -f optima-n8n

# Exec command in container
docker exec optima-postgres psql -U optima_user -d optima_erp -c "SELECT version();"

# Inspect container
docker inspect optima-n8n

# Clean unused Docker resources
docker system prune
```

---

## 📊 EXPECTED PERFORMANCE

| Operation | Time | Notes |
|-----------|------|-------|
| System startup | 2-3 min | After first setup |
| Firecrawl scrape | 10-30 sec | Depends on page size |
| AI extraction | 5-15 sec | Using LLM |
| Database insert | <1 sec | Bulk operations |
| Full workflow cycle | 30-60 sec | End-to-end |

---

## 🎯 NEXT STEPS

### 1. Complete Initial Setup
- [ ] Copy all files to ~/optima-scraper/
- [ ] Edit .env with your passwords
- [ ] Run `bash start.sh`
- [ ] Verify all containers running

### 2. Create Test Workflow
- [ ] Login to n8n
- [ ] Create "Manual Trigger" + "HTTP Request" workflow
- [ ] Test Firecrawl API
- [ ] Save workflow

### 3. Setup Real Workflows
- [ ] Price monitoring workflow
- [ ] Lead generation workflow
- [ ] Configure target websites
- [ ] Test with real data

### 4. Automate
- [ ] Setup schedules
- [ ] Configure notifications
- [ ] Setup backups
- [ ] Monitor performance

### 5. Production Deployment
- [ ] Change all default passwords
- [ ] Setup SSL/HTTPS
- [ ] Configure external backups
- [ ] Setup monitoring
- [ ] Plan for high availability

---

## 📝 LICENSE & USAGE

This package is provided for **PT Optima Smartindo Industry**.

**Included:**
- ✅ Docker configurations
- ✅ Database schemas
- ✅ Documentation & guides
- ✅ Startup/shutdown scripts
- ✅ All configuration templates

**Not Included:**
- ⚠️ API keys (you must provide)
- ⚠️ SSL certificates (for HTTPS)
- ⚠️ Custom business logic (you implement)
- ⚠️ Target website lists (you define)

---

## 🎓 LEARNING PATH

### For Non-Technical Users
1. Follow `QUICK_START.md` to get system running
2. Use n8n UI to create workflows (no coding)
3. Configure target websites
4. Monitor results in database

### For Developers/DevOps
1. Study `SETUP_GUIDE_LENGKAP.md` architecture
2. Customize Docker configs as needed
3. Extend with custom node types
4. Setup CI/CD if needed

### For Database Administrators
1. Review `schema.sql` table structures
2. Implement backup procedures
3. Monitor performance & indexes
4. Optimize queries as needed

---

## 🎯 QUICK LINKS

**Get Started Fast:**
→ [QUICK_START.md](./QUICK_START.md) (30 minutes)

**Understand Architecture:**
→ [SETUP_GUIDE_LENGKAP.md](./SETUP_GUIDE_LENGKAP.md) (detailed)

**Find File Locations:**
→ [FILE_INVENTORY_AND_GUIDE.md](./FILE_INVENTORY_AND_GUIDE.md)

**Fix Problems:**
→ [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md)

---

## ✨ YOU'RE ALL SET!

**Everything you need to build a professional web scraping automation system is included.**

**Next step:**
1. Open `QUICK_START.md`
2. Follow the 4 simple steps
3. You'll have a running system in 30 minutes

**Questions?** Check the troubleshooting guide or refer to the complete setup guide.

---

**Version**: 1.0  
**Status**: Production Ready  
**Created**: April 2024  
**For**: PT Optima Smartindo Industry

---

## 🚀 LET'S BUILD SOMETHING GREAT!

From zero to fully-automated web scraping system in 30 minutes.

**Start with**: `QUICK_START.md`
