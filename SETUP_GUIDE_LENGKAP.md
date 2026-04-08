# 🚀 SETUP GUIDE LENGKAP: WEB SCRAPING AUTOMATION SYSTEM
## PT Optima Smartindo Industry - LED Manufacturer

**Status**: Complete Step-by-Step Setup Guide (Firecrawl + n8n + PostgreSQL)  
**Target System**: Ubuntu 20.04+ / Windows Server dengan Docker Desktop  
**Estimated Time**: 2-3 jam untuk setup, testing, dan first run

---

## 📋 TABLE OF CONTENTS
1. [Prerequisites & Environment Setup](#1-prerequisites--environment-setup)
2. [Docker Installation](#2-docker-installation)
3. [Database Setup (PostgreSQL)](#3-database-setup-postgresql)
4. [Firecrawl Installation & Configuration](#4-firecrawl-installation--configuration)
5. [n8n Installation & Configuration](#5-n8n-installation--configuration)
6. [Database Schema Design](#6-database-schema-design)
7. [n8n Workflow Setup](#7-n8n-workflow-setup)
8. [AI Extraction Prompts](#8-ai-extraction-prompts)
9. [Testing & Debugging](#9-testing--debugging)
10. [Production Deployment & Monitoring](#10-production-deployment--monitoring)

---

# 1. PREREQUISITES & ENVIRONMENT SETUP

## 1.1 Hardware Requirements
```
Minimum:
- RAM: 8 GB (recommended 16 GB)
- Storage: 100 GB SSD (untuk Docker images + data)
- CPU: 4 cores
- Network: LAN lokal (intranet)

Recommended:
- RAM: 16+ GB
- Storage: 256 GB SSD
- CPU: 8 cores
```

## 1.2 OS & Base Packages

### **Linux (Ubuntu 20.04+)**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git nano vim

# Create working directory
mkdir -p ~/optima-scraper/{firecrawl,n8n,postgres,data}
cd ~/optima-scraper
```

### **Windows (dengan WSL2 + Docker Desktop)**
```powershell
# Install WSL2 (jika belum ada)
wsl --install

# Download Docker Desktop
# https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version
```

## 1.3 API Keys yang Dibutuhkan
Siapkan sebelum instalasi:
- **OpenAI API Key** (untuk extraction AI) - atau gunakan Claude API atau Ollama lokal
- **Atau**: Setup Ollama lokal (free, tanpa API key)

---

# 2. DOCKER INSTALLATION

## 2.1 Install Docker & Docker Compose

### **Linux (Ubuntu)**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

### **Windows (Docker Desktop)**
```powershell
# Download dari: https://www.docker.com/products/docker-desktop
# Install dan restart

# Verify
docker --version
docker-compose --version
```

## 2.2 Verify Docker Installation
```bash
docker run hello-world
# Jika berhasil, akan print "Hello from Docker!"
```

---

# 3. DATABASE SETUP (POSTGRESQL)

## 3.1 Create Docker Compose for PostgreSQL

File: `~/optima-scraper/docker-compose.postgres.yml`

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: optima-postgres
    environment:
      POSTGRES_USER: optima_user
      POSTGRES_PASSWORD: OptimaSmartin123!@# # CHANGE THIS!
      POSTGRES_DB: optima_erp
      TZ: Asia/Jakarta
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init_db.sql:/docker-entrypoint-initdb.d/init_db.sql
    networks:
      - optima-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U optima_user"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: optima-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@optima.local
      PGADMIN_DEFAULT_PASSWORD: AdminOptima123!@# # CHANGE THIS!
      PGADMIN_CONFIG_SERVER_MODE: 'False'
    ports:
      - "5050:80"
    networks:
      - optima-network
    depends_on:
      - postgres
    restart: always

volumes:
  postgres_data:
    driver: local

networks:
  optima-network:
    driver: bridge
```

## 3.2 Initialize Database

File: `~/optima-scraper/init_db.sql`

```sql
-- Create schemas
CREATE SCHEMA IF NOT EXISTS scraping;
CREATE SCHEMA IF NOT EXISTS erp;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON SCHEMA erp TO optima_user;

-- Tables will be created in Step 6
```

## 3.3 Start PostgreSQL

```bash
cd ~/optima-scraper

# Start PostgreSQL & pgAdmin
docker-compose -f docker-compose.postgres.yml up -d

# Verify
docker ps
# Seharusnya muncul 2 containers: optima-postgres & optima-pgadmin

# Check logs
docker logs optima-postgres

# Test connection (optional, install psql dulu)
psql -h localhost -U optima_user -d optima_erp -c "SELECT version();"
```

## 3.4 Access pgAdmin (Optional)
- URL: `http://localhost:5050`
- Email: `admin@optima.local`
- Password: `AdminOptima123!@#`

---

# 4. FIRECRAWL INSTALLATION & CONFIGURATION

## 4.1 Download Firecrawl Repository

```bash
cd ~/optima-scraper

# Clone official repository
git clone https://github.com/firecrawl/firecrawl.git
cd firecrawl

# Checkout latest stable version
git checkout main
```

## 4.2 Create Custom docker-compose.yml

File: `~/optima-scraper/firecrawl/docker-compose.yml` (REPLACE existing)

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: firecrawl-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - optima-network
    restart: always

  postgres:
    image: postgres:15-alpine
    container_name: firecrawl-postgres
    environment:
      POSTGRES_USER: firecrawl_user
      POSTGRES_PASSWORD: FirecrawlPass123!@# # CHANGE THIS!
      POSTGRES_DB: firecrawl_db
      TZ: Asia/Jakarta
    ports:
      - "5433:5432"  # Different port from main ERP DB
    volumes:
      - firecrawl_postgres_data:/var/lib/postgresql/data
    networks:
      - optima-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U firecrawl_user"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always

  api:
    image: firecrawl:latest
    build:
      context: ./apps/api
      dockerfile: Dockerfile
    container_name: firecrawl-api
    environment:
      # Database
      DATABASE_URL: postgresql://firecrawl_user:FirecrawlPass123!@#@firecrawl-postgres:5432/firecrawl_db
      REDIS_URL: redis://firecrawl-redis:6379
      
      # API Configuration
      NODE_ENV: production
      LOG_LEVEL: info
      FIRECRAWL_API_KEY: firecrawl_local_key_${RANDOM}
      ALLOW_METRICS: 'true'
      
      # AI Extraction - Choose ONE:
      
      # Option 1: OpenAI
      LLM_API_KEY: sk-your-openai-key-here
      LLM_MODEL_NAME: gpt-4-turbo
      LLM_PROVIDER: openai
      
      # Option 2: Ollama (Local, FREE)
      # LLM_API_KEY: dummy
      # LLM_MODEL_NAME: mistral
      # LLM_PROVIDER: ollama
      # OLLAMA_API_BASE: http://ollama:11434
      
      # Option 3: Claude (via OpenRouter)
      # LLM_API_KEY: sk-or-your-openrouter-key
      # LLM_MODEL_NAME: anthropic/claude-3-sonnet
      # LLM_PROVIDER: openrouter
      
      # Scraping Configuration
      USE_DB_AUTHENTICATION: 'false'  # Disable auth karena lokal intranet
      PLAYWRIGHT_TIMEOUT: 30000
      CRAWL_TIMEOUT: 300000
      MAX_CRAWL_DEPTH: 3
      MAX_CONCURRENT_JOBS: 5
      
      # Rate Limiting
      REQUEST_TIMEOUT: 30000
      BLOCKING_DOMAINS: facebook.com,instagram.com,twitter.com
      
    ports:
      - "3002:3002"
    volumes:
      - ./apps/api:/app
      - /app/node_modules
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - optima-network
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3002/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  redis_data:
    driver: local
  firecrawl_postgres_data:
    driver: local

networks:
  optima-network:
    driver: bridge
```

## 4.3 Build & Start Firecrawl

```bash
cd ~/optima-scraper/firecrawl

# Build image (pertama kali saja, memakan waktu 10-15 menit)
docker-compose build

# Start services
docker-compose up -d

# Verify
docker-compose ps
docker logs firecrawl-api

# Test API endpoint
curl http://localhost:3002/health
# Expected response: {"status": "ok"}
```

## 4.4 Setup AI Provider (Choose One)

### **Option A: OpenAI (Recommended untuk production)**
```bash
# Edit docker-compose.yml, set:
LLM_API_KEY: sk-proj-xxxxx...
LLM_PROVIDER: openai
LLM_MODEL_NAME: gpt-4-turbo

# Restart
docker-compose down && docker-compose up -d
```

### **Option B: Ollama (FREE, LOCAL - Recommended untuk testing)**
```bash
# Install Ollama locally
# https://ollama.ai

# Pull model
ollama pull mistral

# Add Ollama service to docker-compose.yml:
ollama:
  image: ollama/ollama:latest
  container_name: firecrawl-ollama
  ports:
    - "11434:11434"
  networks:
    - optima-network
  volumes:
    - ollama_data:/root/.ollama
  restart: always

# Update Firecrawl env:
LLM_PROVIDER: ollama
OLLAMA_API_BASE: http://firecrawl-ollama:11434

# Restart
docker-compose down && docker-compose up -d
```

## 4.5 Test Firecrawl Endpoints

```bash
# Test 1: Health Check
curl http://localhost:3002/health

# Test 2: Scrape endpoint
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "formats": ["markdown"]
  }'

# Test 3: Extract endpoint (dengan AI)
curl -X POST http://localhost:3002/v1/extract \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com",
    "prompt": "Extract product name and price",
    "schema": {
      "type": "object",
      "properties": {
        "product_name": {"type": "string"},
        "price": {"type": "number"}
      }
    }
  }'
```

---

# 5. N8N INSTALLATION & CONFIGURATION

## 5.1 Create n8n Docker Compose

File: `~/optima-scraper/docker-compose.n8n.yml`

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: optima-n8n
    environment:
      # Basic Configuration
      N8N_HOST: 0.0.0.0
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      TZ: Asia/Jakarta
      
      # Database
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: optima-postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: optima_erp
      DB_POSTGRESDB_USER: optima_user
      DB_POSTGRESDB_PASSWORD: OptimaSmartin123!@#
      
      # Webhook Configuration
      WEBHOOK_URL: http://localhost:5678/
      N8N_SECURE_COOKIE: 'false'  # Set to true in production with HTTPS
      
      # Security
      N8N_BASIC_AUTH_ACTIVE: 'true'
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: Optima2024!@#
      
      # Timezone & locale
      LC_ALL: id_ID.UTF-8
      LANG: id_ID.UTF-8
      
      # Performance
      GENERIC_FUNCTION_TIMEOUT: 600
      N8N_LOG_LEVEL: info
      
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
      - ./n8n_workflows:/workflows  # Mount for workflow backups
    depends_on:
      - optima-postgres
    networks:
      - optima-network
    restart: always

volumes:
  n8n_data:
    driver: local

networks:
  optima-network:
    driver: bridge
    external: true  # Use existing network dari PostgreSQL setup
```

## 5.2 Start n8n

```bash
cd ~/optima-scraper

# Create workflows directory
mkdir -p n8n_workflows

# Start n8n
docker-compose -f docker-compose.n8n.yml up -d

# Verify
docker logs optima-n8n

# Access n8n
# URL: http://localhost:5678
# Username: admin
# Password: Optima2024!@#
```

## 5.3 n8n Initial Setup

```bash
# Wait for n8n to fully start (1-2 minutes)
sleep 120

# Check if running
docker logs optima-n8n | grep "n8n ready on"

# Open browser
# http://localhost:5678
```

---

# 6. DATABASE SCHEMA DESIGN

## 6.1 Create All Tables

File: `~/optima-scraper/schema.sql`

```sql
-- ============================================
-- SCHEMA: scraping
-- PURPOSE: Menyimpan metadata job dan logs
-- ============================================

CREATE SCHEMA IF NOT EXISTS scraping;

-- Table: Job History
CREATE TABLE IF NOT EXISTS scraping.job_history (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    job_type VARCHAR(50) NOT NULL, -- 'price_monitoring' or 'lead_generation'
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    target_url VARCHAR(2048) NOT NULL,
    firecrawl_job_id VARCHAR(255),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    record_count INT DEFAULT 0,
    api_response JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: Scraping Logs
CREATE TABLE IF NOT EXISTS scraping.logs (
    log_id SERIAL PRIMARY KEY,
    job_id INT REFERENCES scraping.job_history(job_id),
    log_level VARCHAR(20), -- INFO, WARN, ERROR
    message TEXT,
    context JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index untuk performa query
CREATE INDEX idx_job_status ON scraping.job_history(status);
CREATE INDEX idx_job_type ON scraping.job_history(job_type);
CREATE INDEX idx_job_created ON scraping.job_history(created_at);

-- ============================================
-- SCHEMA: erp
-- PURPOSE: Data produk dan leads untuk ERP
-- ============================================

CREATE SCHEMA IF NOT EXISTS erp;

-- Table 1: Competitor Product Pricing
CREATE TABLE IF NOT EXISTS erp.competitor_products (
    product_id SERIAL PRIMARY KEY,
    source_website VARCHAR(255) NOT NULL, -- competitor domain
    source_url VARCHAR(2048),
    product_name VARCHAR(500) NOT NULL,
    brand VARCHAR(255),
    price_idr DECIMAL(12, 2),
    currency VARCHAR(10) DEFAULT 'IDR',
    product_category VARCHAR(255),
    specification TEXT, -- JSON format: {"wattage": "10W", "color": "warmwhite", ...}
    availability_status VARCHAR(100), -- in_stock, out_of_stock, discontinued
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_price_change TIMESTAMP,
    previous_price_idr DECIMAL(12, 2),
    price_change_percent DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    job_id INT REFERENCES scraping.job_history(job_id)
);

-- Table 2: B2B Leads
CREATE TABLE IF NOT EXISTS erp.b2b_leads (
    lead_id SERIAL PRIMARY KEY,
    source_website VARCHAR(255) NOT NULL, -- lead aggregator domain
    company_name VARCHAR(500) NOT NULL,
    pic_name VARCHAR(255), -- Person in Charge
    pic_title VARCHAR(255), -- e.g., "Direktur", "Project Manager"
    phone_number VARCHAR(50),
    email VARCHAR(255),
    company_address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    specialization TEXT, -- JSON: {"categories": ["Mekanikal", "Elektrikal"], ...}
    company_website VARCHAR(255),
    business_registration_number VARCHAR(50), -- e.g., SIUP/TDP
    estimated_company_size VARCHAR(50), -- SME, Enterprise, Corporation
    lead_quality_score DECIMAL(3, 1) DEFAULT 5, -- 1-10 score
    lead_status VARCHAR(50) DEFAULT 'new', -- new, contacted, qualified, won, lost
    last_contacted TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    job_id INT REFERENCES scraping.job_history(job_id)
);

-- Table 3: Audit & Status Tracking
CREATE TABLE IF NOT EXISTS erp.data_sync_log (
    sync_id SERIAL PRIMARY KEY,
    data_type VARCHAR(50), -- 'competitor_products' or 'b2b_leads'
    total_records INT,
    inserted_records INT DEFAULT 0,
    updated_records INT DEFAULT 0,
    failed_records INT DEFAULT 0,
    sync_status VARCHAR(50), -- success, partial, failed
    error_details TEXT,
    sync_started_at TIMESTAMP,
    sync_ended_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes untuk performa
CREATE INDEX idx_competitor_source ON erp.competitor_products(source_website);
CREATE INDEX idx_competitor_created ON erp.competitor_products(created_at DESC);
CREATE INDEX idx_competitor_price ON erp.competitor_products(price_idr);
CREATE INDEX idx_lead_source ON erp.b2b_leads(source_website);
CREATE INDEX idx_lead_status ON erp.b2b_leads(lead_status);
CREATE INDEX idx_lead_city ON erp.b2b_leads(city);
CREATE INDEX idx_lead_created ON erp.b2b_leads(created_at DESC);

-- ============================================
-- VIEWS FOR BUSINESS INTELLIGENCE
-- ============================================

-- View: Price Comparison
CREATE OR REPLACE VIEW erp.v_price_comparison AS
SELECT 
    product_name,
    brand,
    source_website,
    price_idr,
    last_seen,
    price_change_percent,
    RANK() OVER (PARTITION BY product_name ORDER BY price_idr ASC) as price_rank
FROM erp.competitor_products
WHERE last_seen >= NOW() - INTERVAL '7 days'
ORDER BY product_name, price_idr;

-- View: Active Leads by City
CREATE OR REPLACE VIEW erp.v_active_leads_by_city AS
SELECT 
    city,
    COUNT(*) as total_leads,
    SUM(CASE WHEN lead_status = 'new' THEN 1 ELSE 0 END) as new_leads,
    SUM(CASE WHEN lead_status = 'qualified' THEN 1 ELSE 0 END) as qualified_leads
FROM erp.b2b_leads
WHERE lead_status IN ('new', 'contacted', 'qualified')
GROUP BY city
ORDER BY total_leads DESC;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA erp TO optima_user;
GRANT ALL PRIVILEGES ON SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA erp TO optima_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA scraping TO optima_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA erp TO optima_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA scraping TO optima_user;
```

## 6.2 Execute Schema Creation

```bash
# Connect to PostgreSQL and execute
psql -h localhost -U optima_user -d optima_erp -f ~/optima-scraper/schema.sql

# Verify tables
psql -h localhost -U optima_user -d optima_erp -c "\dt scraping.* erp.*"

# Should show all 5 tables
```

---

# 7. N8N WORKFLOW SETUP

## 7.1 Use Case A: Competitor Price Monitoring Workflow

### **Workflow Name**: `Competitor Price Monitor`

**Flow Diagram:**
```
[Manual Trigger] 
    ↓
[Get Target URLs] → [PostgreSQL: Get URLs dari config table]
    ↓
[Loop URLs]
    ↓
[Call Firecrawl API] → [POST /v1/scrape dengan AI extraction]
    ↓
[Wait for Processing] → [Polling job status setiap 5 detik]
    ↓
[Extract Data] → [Transform response ke format tabel]
    ↓
[Insert to DB] → [PostgreSQL: INSERT competitor_products]
    ↓
[Log Status] → [PostgreSQL: Update job_history]
    ↓
[Send Notification] → [Email/Slack ke tim]
```

### **Workflow JSON** (Import di n8n)

```json
{
  "name": "Competitor Price Monitor - AUTO",
  "nodes": [
    {
      "parameters": {},
      "name": "Manual Trigger",
      "type": "n8n-nodes-base.manualTrigger",
      "typeVersion": 1,
      "position": [0, 0]
    },
    {
      "parameters": {
        "query": "SELECT url_target, website_name FROM scraping.price_monitoring_targets WHERE is_active = true",
        "options": {}
      },
      "name": "Get Target URLs",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2,
      "position": [300, 0],
      "credentials": {
        "postgres": "Local_ERP_Database"
      }
    },
    {
      "parameters": {
        "loopProperty": "rows"
      },
      "name": "Loop Each URL",
      "type": "n8n-nodes-base.itemLists",
      "typeVersion": 1,
      "position": [600, 0]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://firecrawl-api:3002/v1/scrape",
        "headers": {},
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "url",
              "value": "={{ $node[\"Loop Each URL\"].json.url_target }}"
            },
            {
              "name": "formats",
              "value": "extract"
            },
            {
              "name": "extractorOptions",
              "value": "{\"mode\": \"llm-extraction\", \"extractionPrompt\": \"Extract product catalog data in JSON array format. For each product found: {\\\"nama_produk\\\": string, \\\"harga_rupiah\\\": number, \\\"merek\\\": string, \\\"spesifikasi\\\": object}\"}"
            }
          ]
        }
      },
      "name": "Call Firecrawl Scrape",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [900, 0]
    },
    {
      "parameters": {
        "amount": 30,
        "unit": "seconds"
      },
      "name": "Wait 30 Seconds",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1,
      "position": [1200, 0]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://firecrawl-api:3002/v1/scrape",
        "headers": {},
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "url",
              "value": "={{ $node[\"Loop Each URL\"].json.url_target }}"
            },
            {
              "name": "formats",
              "value": "extract"
            }
          ]
        }
      },
      "name": "Insert to DB",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2,
      "position": [1500, 0],
      "credentials": {
        "postgres": "Local_ERP_Database"
      }
    }
  ],
  "connections": {
    "Manual Trigger": {
      "main": [
        [
          {
            "node": "Get Target URLs",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Get Target URLs": {
      "main": [
        [
          {
            "node": "Loop Each URL",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Loop Each URL": {
      "main": [
        [
          {
            "node": "Call Firecrawl Scrape",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Call Firecrawl Scrape": {
      "main": [
        [
          {
            "node": "Wait 30 Seconds",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Wait 30 Seconds": {
      "main": [
        [
          {
            "node": "Insert to DB",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

## 7.2 Use Case B: B2B Lead Generation Workflow

**Flow Diagram:**
```
[Scheduled Trigger: Daily 08:00]
    ↓
[Get Lead Source URLs] → [PostgreSQL: Get aktif lead aggregators]
    ↓
[For Each Lead Source]
    ↓
[Call Firecrawl Crawl] → [POST /v1/crawl untuk multi-page exploration]
    ↓
[Monitor Job Status] → [GET /v1/crawl dengan polling]
    ↓
[Extract Company Data] → [AI transform ke {name, PIC, phone, email, address, specialization}]
    ↓
[Deduplication] → [Check apakah lead sudah ada di DB]
    ↓
[Insert New Leads] → [PostgreSQL: INSERT b2b_leads]
    ↓
[Calculate Quality Score] → [Berdasarkan completeness & source credibility]
    ↓
[Generate Report] → [Email summary ke Sales Manager]
```

---

# 8. AI EXTRACTION PROMPTS

## 8.1 Price Monitoring - LLM Prompt

**Purpose**: Extract structured product data dari e-commerce website

```json
{
  "systemPrompt": "You are a data extraction specialist. Extract product information from HTML content in structured JSON format. Be precise with prices and currency. Return ONLY valid JSON.",
  
  "extractionPrompt": "Analyze the webpage content and extract ALL products visible. For each product, create an object with these exact fields:
  
  {
    \"products\": [
      {
        \"nama_produk\": \"exact product name\",
        \"harga_rupiah\": number (convert to IDR if needed, use 0 if not found),
        \"merek\": \"brand name or 'Unknown' if not found\",
        \"spesifikasi\": {
          \"wattage\": \"power in watts if available\",
          \"color_temperature\": \"warm/cool/daylight if mentioned\",
          \"base_type\": \"E27, E14, GU10, etc if mentioned\",
          \"other_specs\": \"any other relevant specifications\"
        },
        \"availability\": \"in_stock or out_of_stock\",
        \"source_url\": \"direct product URL if available\"
      }
    ]
  }
  
  IMPORTANT:
  - Extract ALL visible products, not just first 5
  - If price is not in Rupiah, convert approximately
  - If any field not found, use null
  - Return only JSON, no explanations",
  
  "schema": {
    "type": "object",
    "properties": {
      "products": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "nama_produk": {"type": "string"},
            "harga_rupiah": {"type": "number"},
            "merek": {"type": "string"},
            "spesifikasi": {"type": "object"},
            "availability": {"type": "string"},
            "source_url": {"type": "string"}
          },
          "required": ["nama_produk", "harga_rupiah"]
        }
      }
    }
  }
}
```

## 8.2 Lead Generation - LLM Prompt

**Purpose**: Extract B2B company contact data dari direktori bisnis

```json
{
  "systemPrompt": "You are a business intelligence specialist. Extract company contact information from directory pages. Return complete, accurate data in structured JSON format. When PIC information is available, include it.",
  
  "extractionPrompt": "Analyze the business directory page and extract company profile information. For EACH company listed, create an object:

  {
    \"companies\": [
      {
        \"nama_perusahaan\": \"Official registered company name\",
        \"pic\": {
          \"nama\": \"Full name of contact person\",
          \"title\": \"Job title (e.g., Direktur, Manager)\",
          \"phone\": \"Phone number with area code if available\",
          \"email\": \"Email address if visible\"
        },
        \"alamat\": \"Full street address\",
        \"kota\": \"City name\",
        \"provinsi\": \"Province/State\",
        \"kode_pos\": \"Postal code if available\",
        \"spesialisasi\": {
          \"kategori_pekerjaan\": [\"List of specializations\"],
          \"industri\": \"Industry classification\",
          \"sub_kategori\": \"More specific category if available\"
        },
        \"website\": \"Company website URL if linked\",
        \"nomor_izin_usaha\": \"Business registration number if visible\",
        \"ukuran_estimasi\": \"Estimated company size: SME, Enterprise, Corporation\",
        \"profile_url\": \"Link to full profile if available\"
      }
    ]
  }
  
  IMPORTANT:
  - Extract ALL companies on the page, including paginated results
  - For phone: keep formatting as shown (e.g., +62, 021, 0123)
  - For email: only include verified/official email addresses
  - For specialization: infer from job descriptions, project listings
  - If field not found: use null
  - Return only valid JSON with no additional text",
  
  "schema": {
    "type": "object",
    "properties": {
      "companies": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "nama_perusahaan": {"type": "string"},
            "pic": {
              "type": "object",
              "properties": {
                "nama": {"type": "string"},
                "title": {"type": "string"},
                "phone": {"type": "string"},
                "email": {"type": "string"}
              }
            },
            "alamat": {"type": "string"},
            "kota": {"type": "string"},
            "provinsi": {"type": "string"},
            "kode_pos": {"type": "string"},
            "spesialisasi": {
              "type": "object",
              "properties": {
                "kategori_pekerjaan": {"type": "array"},
                "industri": {"type": "string"},
                "sub_kategori": {"type": "string"}
              }
            },
            "website": {"type": "string"},
            "nomor_izin_usaha": {"type": "string"},
            "ukuran_estimasi": {"type": "string"}
          },
          "required": ["nama_perusahaan"]
        }
      }
    }
  }
}
```

---

# 9. TESTING & DEBUGGING

## 9.1 Health Checks

```bash
# Check all services
docker ps -a

# Health check logs
docker logs firecrawl-api | grep "health\|ready\|error" | tail -20
docker logs optima-postgres | grep "error\|ready" | tail -10
docker logs optima-n8n | grep "n8n ready\|error" | tail -10

# Test connectivity between containers
docker exec firecrawl-api ping optima-postgres
docker exec optima-n8n curl http://firecrawl-api:3002/health
```

## 9.2 Test Firecrawl API Manually

```bash
# Test 1: Simple scrape
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.benulampu.com",
    "formats": ["markdown"]
  }' | jq .

# Test 2: Extract dengan AI (Price Monitoring)
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.benulampu.com/products",
    "formats": ["extract"],
    "extractorOptions": {
      "mode": "llm-extraction",
      "extractionPrompt": "Extract product names and prices as JSON"
    }
  }' | jq .

# Test 3: Crawl (untuk lead generation)
curl -X POST http://localhost:3002/v1/crawl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.direktori-kontraktor.com",
    "maxDepth": 2,
    "formats": ["extract"],
    "extractorOptions": {
      "mode": "llm-extraction",
      "extractionPrompt": "Extract company names and contacts"
    }
  }' | jq .
```

## 9.3 Test n8n Workflow

```bash
# 1. Login ke n8n
# http://localhost:5678
# Username: admin
# Password: Optima2024!@#

# 2. Buat test workflow
# - Add Manual Trigger
# - Add HTTP Request node pointing ke Firecrawl
# - Add Debug node
# - Execute & lihat hasil

# 3. Test Database connection
# - Add PostgreSQL node
# - Execute query: SELECT 1 as test_value
# - Should return: [{"test_value": 1}]

# 4. Test dengan real URL
# - Copy workflow JSON dari section 7.1
# - Edit URLs sesuai kebutuhan
# - Save & Activate
```

## 9.4 Debugging Tips

```bash
# Lihat real-time logs
docker logs -f firecrawl-api
docker logs -f optima-n8n
docker logs -f optima-postgres

# Check database
psql -h localhost -U optima_user -d optima_erp -c "SELECT * FROM scraping.job_history LIMIT 5;"

# Network debugging
docker network inspect optima-network

# Clear & restart services (jika ada masalah)
docker-compose -f docker-compose.postgres.yml down
docker-compose -f docker-compose.postgres.yml up -d
# Repeat untuk firecrawl dan n8n
```

---

# 10. PRODUCTION DEPLOYMENT & MONITORING

## 10.1 Production docker-compose.yml (All Services)

File: `~/optima-scraper/docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  # ===== POSTGRESQL (ERP Database) =====
  postgres:
    image: postgres:15-alpine
    container_name: optima-postgres
    environment:
      POSTGRES_USER: optima_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-OptimaSmartin123!@#}
      POSTGRES_DB: optima_erp
      TZ: Asia/Jakarta
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init_db.sql:/docker-entrypoint-initdb.d/init_db.sql
      - ./backups:/backups
    networks:
      - optima-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U optima_user"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ===== FIRECRAWL (Web Scraping Engine) =====
  firecrawl:
    image: firecrawl:latest
    build:
      context: ./firecrawl/apps/api
      dockerfile: Dockerfile
    container_name: firecrawl-api
    environment:
      DATABASE_URL: postgresql://firecrawl_user:${FIRECRAWL_DB_PASSWORD:-FirecrawlPass123!@#}@firecrawl-postgres:5432/firecrawl_db
      REDIS_URL: redis://firecrawl-redis:6379
      NODE_ENV: production
      LLM_API_KEY: ${LLM_API_KEY:-}
      LLM_MODEL_NAME: ${LLM_MODEL_NAME:-gpt-4-turbo}
      LLM_PROVIDER: ${LLM_PROVIDER:-openai}
      USE_DB_AUTHENTICATION: 'false'
      MAX_CRAWL_DEPTH: 3
      MAX_CONCURRENT_JOBS: 10
    ports:
      - "3002:3002"
    depends_on:
      firecrawl-postgres:
        condition: service_healthy
      firecrawl-redis:
        condition: service_started
    networks:
      - optima-network
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3002/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  firecrawl-postgres:
    image: postgres:15-alpine
    container_name: firecrawl-postgres
    environment:
      POSTGRES_USER: firecrawl_user
      POSTGRES_PASSWORD: ${FIRECRAWL_DB_PASSWORD:-FirecrawlPass123!@#}
      POSTGRES_DB: firecrawl_db
      TZ: Asia/Jakarta
    ports:
      - "5433:5432"
    volumes:
      - firecrawl_postgres_data:/var/lib/postgresql/data
    networks:
      - optima-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U firecrawl_user"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always

  firecrawl-redis:
    image: redis:7-alpine
    container_name: firecrawl-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - optima-network
    restart: always

  # ===== N8N (Workflow Orchestrator) =====
  n8n:
    image: n8nio/n8n:latest
    container_name: optima-n8n
    environment:
      N8N_HOST: 0.0.0.0
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      TZ: Asia/Jakarta
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: optima-postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: optima_erp
      DB_POSTGRESDB_USER: optima_user
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD:-OptimaSmartin123!@#}
      WEBHOOK_URL: http://localhost:5678/
      N8N_BASIC_AUTH_ACTIVE: 'true'
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: ${N8N_PASSWORD:-Optima2024!@#}
      N8N_LOG_LEVEL: info
      GENERIC_FUNCTION_TIMEOUT: 600
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
      - ./n8n_workflows:/workflows
    depends_on:
      - postgres
    networks:
      - optima-network
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ===== MONITORING & LOGGING (Optional: Prometheus + Grafana) =====
  prometheus:
    image: prom/prometheus:latest
    container_name: optima-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    networks:
      - optima-network
    restart: always

  grafana:
    image: grafana/grafana:latest
    container_name: optima-grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}
      GF_USERS_ALLOW_SIGN_UP: 'false'
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    networks:
      - optima-network
    restart: always

volumes:
  postgres_data:
    driver: local
  firecrawl_postgres_data:
    driver: local
  redis_data:
    driver: local
  n8n_data:
    driver: local
  prometheus_data:
    driver: local
  grafana_data:
    driver: local

networks:
  optima-network:
    driver: bridge
```

## 10.2 Environment File (.env)

File: `~/optima-scraper/.env`

```bash
# Database Credentials
POSTGRES_PASSWORD=OptimaSmartin123!@#
FIRECRAWL_DB_PASSWORD=FirecrawlPass123!@#

# n8n Configuration
N8N_PASSWORD=Optima2024!@#

# LLM Configuration (choose one)
# OpenAI
LLM_API_KEY=sk-proj-xxxxxxxxxxxxx
LLM_MODEL_NAME=gpt-4-turbo
LLM_PROVIDER=openai

# OR Ollama (local)
# LLM_PROVIDER=ollama
# OLLAMA_API_BASE=http://firecrawl-ollama:11434

# Monitoring
GRAFANA_PASSWORD=admin
PROMETHEUS_RETENTION=30d

# System
TZ=Asia/Jakarta
LOG_LEVEL=info
```

## 10.3 Backup & Restore Strategy

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups/optima-db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec optima-postgres pg_dump -U optima_user optima_erp | gzip > $BACKUP_DIR/optima_erp_$TIMESTAMP.sql.gz

# Backup n8n workflows
cp -r n8n_workflows/ $BACKUP_DIR/n8n_workflows_$TIMESTAMP/

# Backup docker-compose files
cp docker-compose*.yml $BACKUP_DIR/

# Keep only last 10 backups
find $BACKUP_DIR -name "optima_erp_*" -type f | sort -r | tail -n +11 | xargs rm -f

echo "Backup completed: $BACKUP_DIR"
```

## 10.4 Monitoring Dashboard (Prometheus Queries)

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'firecrawl'
    static_configs:
      - targets: ['firecrawl-api:3002']
      
  - job_name: 'postgres'
    static_configs:
      - targets: ['optima-postgres:5432']
      
  - job_name: 'n8n'
    static_configs:
      - targets: ['optima-n8n:5678']
```

## 10.5 Startup Script

File: `~/optima-scraper/start.sh`

```bash
#!/bin/bash
set -e

echo "🚀 Starting PT Optima Smartindo Scraping System..."

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✓ Loaded .env configuration"
fi

# Create necessary directories
mkdir -p n8n_workflows backups prometheus_data grafana_data

# Start services in order
echo "📦 Starting PostgreSQL..."
docker-compose -f docker-compose.postgres.yml up -d
sleep 10

echo "🕷️ Starting Firecrawl..."
cd firecrawl
docker-compose up -d
cd ..
sleep 15

echo "⚙️ Starting n8n..."
docker-compose -f docker-compose.n8n.yml up -d
sleep 20

# Health checks
echo "🏥 Running health checks..."
docker exec firecrawl-api curl -f http://localhost:3002/health || echo "⚠️  Firecrawl may still be starting..."
docker exec optima-postgres pg_isready -U optima_user || echo "⚠️  PostgreSQL check failed"

echo ""
echo "✨ System startup complete!"
echo ""
echo "📍 Access Points:"
echo "  • n8n:        http://localhost:5678  (admin/Optima2024!@#)"
echo "  • pgAdmin:    http://localhost:5050  (admin@optima.local/AdminOptima123!@#)"
echo "  • Firecrawl:  http://localhost:3002/health"
echo "  • Grafana:    http://localhost:3000  (admin/admin)"
echo ""
```

## 10.6 Shutdown Script

File: `~/optima-scraper/stop.sh`

```bash
#!/bin/bash

echo "🛑 Stopping all services..."

docker-compose -f docker-compose.postgres.yml down
cd firecrawl && docker-compose down && cd ..
docker-compose -f docker-compose.n8n.yml down

echo "✓ All services stopped"
echo "💾 Data persisted in Docker volumes"
```

---

# CHECKLIST SETUP LENGKAP

- [ ] Baca seluruh dokumentasi ini
- [ ] Siapkan PC dengan minimum 8GB RAM
- [ ] Install Docker & Docker Compose
- [ ] Prepare API Key (OpenAI / Ollama)
- [ ] Clone Firecrawl repository
- [ ] Create docker-compose.postgres.yml
- [ ] Create init_db.sql
- [ ] Start PostgreSQL & verify dengan pgAdmin
- [ ] Create docker-compose.yml di firecrawl/
- [ ] Configure LLM provider di Firecrawl env
- [ ] Start Firecrawl & test /health endpoint
- [ ] Create docker-compose.n8n.yml
- [ ] Start n8n & login
- [ ] Execute schema.sql untuk membuat tables
- [ ] Create workflow untuk Price Monitoring
- [ ] Create workflow untuk Lead Generation
- [ ] Test workflows dengan real URLs
- [ ] Setup automated schedules (cron/trigger)
- [ ] Configure monitoring & logging
- [ ] Create backup script & setup cron job
- [ ] Document workflow details
- [ ] Train tim untuk maintenance

---

# NEXT STEPS SETELAH SETUP SELESAI

1. **Day 1**: Setup infrastructure & verify semua service berjalan
2. **Day 2**: Create database schema & test connections
3. **Day 3**: Setup n8n workflows untuk price monitoring
4. **Day 4**: Setup n8n workflows untuk lead generation
5. **Day 5**: Testing end-to-end dengan real target websites
6. **Day 6**: Production hardening, backup, monitoring setup
7. **Day 7**: Training team & handoff dokumentasi

---

**Version**: 1.0  
**Last Updated**: April 2024  
**Maintainer**: AI Automation Expert  
**Support**: Refer to troubleshooting section or GitHub issues
