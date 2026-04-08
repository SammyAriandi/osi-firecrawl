# 🔧 TROUBLESHOOTING & TESTING GUIDE

## Quick Diagnostics

### 1. Check if All Containers are Running
```bash
docker ps
```

Expected output (6 containers):
- optima-postgres ✅
- optima-pgadmin ✅
- firecrawl-api ✅
- firecrawl-postgres ✅
- firecrawl-redis ✅
- optima-n8n ✅

### 2. If a container is not running:
```bash
# View all containers (including stopped)
docker ps -a

# Check logs of failing container
docker logs optima-n8n          # for n8n
docker logs firecrawl-api       # for Firecrawl
docker logs optima-postgres     # for PostgreSQL

# Restart a specific container
docker restart optima-n8n
```

---

## Common Issues & Solutions

### ❌ Issue: "Port 5678 already in use"

**Error Message:**
```
Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:5678 -> 0.0.0.0:0
```

**Solution:**
```bash
# Find process using port 5678
lsof -i :5678

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.n8n.yml
# ports:
#   - "5679:5678"  # Use 5679 instead
```

---

### ❌ Issue: "PostgreSQL connection refused"

**Error Message:**
```
could not connect to server: Connection refused
    Is the server running on host "localhost" (127.0.0.1) and accepting
    TCP/IP connections on port 5432?
```

**Solution:**
```bash
# Check if PostgreSQL container is running
docker ps | grep optima-postgres

# If not running, start it
docker-compose -f docker-compose.postgres.yml up -d

# Wait 10 seconds and try connecting again
sleep 10
psql -h localhost -U optima_user -d optima_erp -c "SELECT 1;"
```

---

### ❌ Issue: "Firecrawl health check fails"

**Error Message:**
```
Failed to get response from health check
```

**Solution:**
```bash
# Check Firecrawl logs
docker logs firecrawl-api | tail -50

# Check if it's a build issue
cd firecrawl
docker-compose build --no-cache
docker-compose up -d
```

---

### ❌ Issue: "n8n not opening workflows"

**Error Message:**
```
Error loading workflows
```

**Solution:**
```bash
# Restart n8n
docker restart optima-n8n

# Wait for initialization
sleep 20

# Check logs
docker logs optima-n8n | grep "n8n ready"

# If still broken, remove volume and reinitialize
docker-compose -f docker-compose.n8n.yml down -v
docker-compose -f docker-compose.n8n.yml up -d
```

---

### ❌ Issue: "Out of memory errors"

**Error Message:**
```
FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed - JavaScript heap out of memory
```

**Solution:**
```bash
# Increase Node.js memory in docker-compose.n8n.yml:
environment:
  NODE_OPTIONS: '--max-old-space-size=4096'  # Increase from 2048

# Restart
docker-compose -f docker-compose.n8n.yml restart optima-n8n
```

---

## Testing Endpoints

### 1. Test Firecrawl API

```bash
# Health check
curl http://localhost:3002/health

# Expected response:
# {"status":"ok"}

# Test simple scrape
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.example.com",
    "formats": ["markdown"]
  }'

# Test with AI extraction (price monitoring)
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://tokopedia.com/search?q=lampu+led",
    "formats": ["extract"],
    "extractorOptions": {
      "mode": "llm-extraction",
      "extractionPrompt": "Extract product name and price. Return JSON array with fields: product_name, price_idr"
    }
  }' | jq .
```

### 2. Test PostgreSQL Connection

```bash
# Connect directly
psql -h localhost -U optima_user -d optima_erp

# Inside psql:
SELECT version();
SELECT COUNT(*) FROM scraping.job_history;
SELECT COUNT(*) FROM erp.competitor_products;
\dt  # List all tables
\q  # Quit
```

### 3. Test n8n API

```bash
# Health check
curl http://localhost:5678/healthz

# Get n8n version
curl -s http://localhost:5678/api/v1/me \
  -H "Authorization: Bearer YOUR_N8N_API_KEY" | jq .
```

### 4. Test pgAdmin

```
URL: http://localhost:5050
Email: admin@optima.local
Password: AdminOptima123!@#
```

---

## Performance Testing

### 1. Measure Firecrawl Response Time

```bash
# Simple timing
time curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com","formats":["markdown"]}'
```

### 2. Test Database Query Performance

```bash
# Connect to PostgreSQL
psql -h localhost -U optima_user -d optima_erp

-- Test query speed
EXPLAIN ANALYZE 
SELECT * FROM erp.competitor_products 
WHERE created_at >= NOW() - INTERVAL '7 days' 
ORDER BY price_idr 
LIMIT 100;

-- Check index usage
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'erp';
```

### 3. Monitor Docker Resources

```bash
# Real-time resource usage
docker stats

# Per container
docker stats optima-n8n firecrawl-api optima-postgres

# Save stats to file
docker stats --no-stream > docker-stats.txt
```

---

## Testing Workflows

### 1. Create Test Workflow in n8n

**Step 1: Open n8n**
- URL: http://localhost:5678
- Login: admin / Optima2024!@#

**Step 2: Create Simple Test**
1. Click "+ New" → Workflow
2. Name: "Test Firecrawl Connection"
3. Add "Manual Trigger" node
4. Add "HTTP Request" node:
   - Method: GET
   - URL: http://firecrawl-api:3002/health
5. Click Execute (play button)
6. Should see: `{"status":"ok"}`

**Step 3: Test Database Connection**
1. Add "PostgreSQL" node
2. Credentials: Create new connection
   - Host: optima-postgres
   - Port: 5432
   - User: optima_user
   - Password: OptimaSmartin123!@#
   - Database: optima_erp
3. Query: `SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema IN ('scraping', 'erp')`
4. Execute
5. Should show count > 0

**Step 4: Test Data Insert**
1. Add another PostgreSQL node
2. Query:
   ```sql
   INSERT INTO scraping.logs (log_level, message) 
   VALUES ('INFO', 'Test log from n8n')
   RETURNING *
   ```
3. Execute
4. Should return inserted record

### 2. Monitor Workflow Execution

```bash
# View workflow logs in n8n
# Dashboard → Executions

# Or via database
psql -h localhost -U optima_user -d optima_erp
SELECT * FROM scraping.logs ORDER BY created_at DESC LIMIT 10;
```

---

## Database Validation

### 1. Verify Schema Created

```bash
psql -h localhost -U optima_user -d optima_erp

-- Check all tables
SELECT 
    table_schema,
    table_name 
FROM information_schema.tables 
WHERE table_schema IN ('scraping', 'erp') 
ORDER BY table_schema, table_name;

-- Expected output:
-- scraping | job_history
-- scraping | logs
-- scraping | price_monitoring_targets
-- scraping | lead_generation_targets
-- erp | competitor_products
-- erp | b2b_leads
-- erp | lead_deduplication
-- erp | data_sync_log
-- erp | lead_contact_history
```

### 2. Verify Sample Data Inserted

```bash
SELECT * FROM scraping.price_monitoring_targets;
SELECT * FROM scraping.lead_generation_targets;

-- Should show 3 rows each from schema.sql inserts
```

### 3. Check Indexes

```bash
-- List all indexes in erp schema
SELECT 
    schemaname,
    tablename,
    indexname 
FROM pg_indexes 
WHERE schemaname = 'erp' 
ORDER BY tablename, indexname;
```

---

## Cleanup Commands

### 1. Stop all containers (keep data)
```bash
bash stop.sh
```

### 2. Remove everything and start fresh
```bash
# CAUTION: This deletes all data!
docker-compose -f docker-compose.postgres.yml down -v
docker-compose -f docker-compose.n8n.yml down -v
cd firecrawl && docker-compose down -v && cd ..

# Then restart
bash start.sh
```

### 3. Clean unused Docker resources
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Show disk usage
docker system df
```

---

## Log Monitoring

### 1. Real-time Logs

```bash
# n8n logs
docker logs -f optima-n8n

# Firecrawl logs
docker logs -f firecrawl-api

# PostgreSQL logs
docker logs -f optima-postgres

# All logs
docker-compose logs -f
```

### 2. Export Logs

```bash
# Export to file
docker logs optima-n8n > logs/n8n.log
docker logs firecrawl-api > logs/firecrawl.log
docker logs optima-postgres > logs/postgres.log

# Analyze logs
grep ERROR logs/*.log
grep WARNING logs/*.log
```

---

## Performance Optimization

### 1. Database Connection Pooling

Update n8n credentials:
- Min Pool Size: 2
- Max Pool Size: 20
- Idle Timeout: 30000ms

### 2. Firecrawl Concurrency

In firecrawl docker-compose:
```yaml
MAX_CONCURRENT_JOBS: 10  # Increase for more parallel jobs
```

### 3. n8n Function Timeout

In docker-compose.n8n.yml:
```yaml
GENERIC_FUNCTION_TIMEOUT: 600  # seconds
EXECUTIONS_TIMEOUT: 3600  # seconds
```

---

## Backup & Recovery

### 1. Manual Backup

```bash
# Backup PostgreSQL
docker exec optima-postgres pg_dump -U optima_user optima_erp > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup n8n data
docker cp optima-n8n:/home/node/.n8n ./n8n_backup_$(date +%Y%m%d)

# Backup all volumes
tar -czf volumes_backup_$(date +%Y%m%d).tar.gz -C $(docker volume inspect --format='{{.Mountpoint}}' postgres_data)
```

### 2. Restore from Backup

```bash
# Restore PostgreSQL
docker exec -i optima-postgres psql -U optima_user optima_erp < backup_YYYYMMDD_HHMMSS.sql

# Restore n8n
docker cp ./n8n_backup_YYYYMMDD optima-n8n:/home/node/.n8n
docker restart optima-n8n
```

---

## Health Check Script

File: `health-check.sh`

```bash
#!/bin/bash

echo "🏥 Health Check Report"
echo "======================"

echo -n "PostgreSQL: "
docker exec optima-postgres pg_isready -U optima_user && echo "✅" || echo "❌"

echo -n "Firecrawl API: "
curl -s http://localhost:3002/health | grep -q "ok" && echo "✅" || echo "❌"

echo -n "n8n: "
curl -s http://localhost:5678/healthz > /dev/null 2>&1 && echo "✅" || echo "❌"

echo -n "Redis: "
docker exec firecrawl-redis redis-cli ping | grep -q PONG && echo "✅" || echo "❌"

echo ""
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Run: `bash health-check.sh`

---

## Support Resources

- **Firecrawl Docs**: https://docs.firecrawl.dev/
- **n8n Docs**: https://docs.n8n.io/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Docker Docs**: https://docs.docker.com/
