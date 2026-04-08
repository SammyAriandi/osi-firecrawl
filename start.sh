#!/bin/bash
set -e

# ============================================
# STARTUP SCRIPT
# PT Optima Smartindo - Web Scraping System
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

log()         { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}  ✓${NC} $1"; }
log_error()   { echo -e "${RED}  ✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}  ⚠${NC} $1"; }

# ── Step 1: Check prerequisites ──────────────────────────
log "🔍 Checking prerequisites..."

if ! command -v docker &>/dev/null; then
    log_error "Docker is not installed. Download from https://www.docker.com/products/docker-desktop"
    exit 1
fi
log_success "Docker found: $(docker --version 2>&1 | head -1)"

# Check if Docker daemon is running
if ! docker info &>/dev/null; then
    log_error "Docker Desktop is not running. Please start Docker Desktop first!"
    exit 1
fi
log_success "Docker Desktop is running"

# Check .env
if [ ! -f ".env" ]; then
    log_warning ".env not found, creating from defaults..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
    fi
    log_success ".env created — please review and edit if needed"
fi

# Check required files
for f in docker-compose.yml init_db.sql schema.sql; do
    if [ ! -f "$f" ]; then
        log_error "Missing required file: $f"
        exit 1
    fi
done
log_success "All required files present"

# ── Step 2: Create directories ───────────────────────────
mkdir -p n8n_workflows backups logs
log_success "Directories ready"

# ── Step 3: Start all services ───────────────────────────
log ""
log "🚀 Starting all services..."
log ""

docker compose up -d 2>&1 | while IFS= read -r line; do
    echo "   $line"
done

# ── Step 4: Wait for PostgreSQL ──────────────────────────
log ""
log "⏳ Waiting for PostgreSQL to be ready..."
for i in $(seq 1 30); do
    if docker exec optima-postgres pg_isready -U optima_user -d optima_erp &>/dev/null; then
        log_success "PostgreSQL is ready"
        break
    fi
    if [ "$i" -eq 30 ]; then
        log_error "PostgreSQL did not start within 60 seconds"
        log "   Check logs: docker logs optima-postgres"
        exit 1
    fi
    sleep 2
done

# ── Step 5: Verify database tables ──────────────────────
TABLE_COUNT=$(docker exec optima-postgres psql -U optima_user -d optima_erp -t -A -c \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('scraping','erp');" 2>/dev/null || echo "0")
TABLE_COUNT=$(echo "$TABLE_COUNT" | tr -d '[:space:]')

if [ "$TABLE_COUNT" -ge 9 ]; then
    log_success "Database schema OK ($TABLE_COUNT tables)"
else
    log_warning "Found $TABLE_COUNT tables (expected 9). Schema may still be initializing..."
    log "   This is normal on first run. Wait 10 seconds and re-check."
    sleep 10
    TABLE_COUNT=$(docker exec optima-postgres psql -U optima_user -d optima_erp -t -A -c \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('scraping','erp');" 2>/dev/null || echo "0")
    TABLE_COUNT=$(echo "$TABLE_COUNT" | tr -d '[:space:]')
    log_success "Database now has $TABLE_COUNT tables"
fi

# ── Step 6: Wait for n8n ────────────────────────────────
log "⏳ Waiting for n8n to be ready..."
for i in $(seq 1 20); do
    if curl -sf http://localhost:5678/healthz &>/dev/null; then
        log_success "n8n is ready"
        break
    fi
    if [ "$i" -eq 20 ]; then
        log_warning "n8n is still starting up — this is normal on first launch"
        log "   Monitor with: docker logs -f optima-n8n"
    fi
    sleep 3
done

# ── Step 7: Display info ────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║       ✨ System Startup Complete! ✨          ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║                                               ║"
echo "║  📊 n8n Workflows                             ║"
echo "║     http://localhost:5678                      ║"
echo "║     User: admin / Password: Optima2024         ║"
echo "║                                               ║"
echo "║  🗄️  pgAdmin Database UI                       ║"
echo "║     http://localhost:5050                      ║"
echo "║     Email: admin@optima.local                  ║"
echo "║     Password: AdminOptima123                   ║"
echo "║                                               ║"
echo "║  💾 PostgreSQL Direct                          ║"
echo "║     Host: localhost:5432                       ║"
echo "║     User: optima_user                          ║"
echo "║     DB: optima_erp                             ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "📋 Useful commands:"
echo "   docker compose ps          — View container status"
echo "   docker compose logs -f     — Follow all logs"
echo "   bash stop.sh               — Stop all services"
echo ""
