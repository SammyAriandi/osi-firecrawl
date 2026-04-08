#!/bin/bash

# ============================================
# HEALTH CHECK SCRIPT
# PT Optima Smartindo - Web Scraping System
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }

echo ""
echo "🏥 Health Check Report"
echo "═══════════════════════"
echo ""

# PostgreSQL
if docker exec optima-postgres pg_isready -U optima_user -d optima_erp &>/dev/null; then
    ok "PostgreSQL is running"
    TABLE_COUNT=$(docker exec optima-postgres psql -U optima_user -d optima_erp -t -A -c \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('scraping','erp');" 2>/dev/null || echo "0")
    ok "Database has $(echo $TABLE_COUNT | tr -d '[:space:]') tables"
else
    fail "PostgreSQL is NOT responding"
fi

# Redis
if docker exec optima-redis redis-cli ping 2>/dev/null | grep -q PONG; then
    ok "Redis is running"
else
    fail "Redis is NOT responding"
fi

# n8n
if curl -sf http://localhost:5678/healthz &>/dev/null; then
    ok "n8n is running (http://localhost:5678)"
else
    fail "n8n is NOT responding"
fi

# pgAdmin
if curl -sf http://localhost:5050 &>/dev/null; then
    ok "pgAdmin is running (http://localhost:5050)"
else
    fail "pgAdmin is NOT responding"
fi

echo ""
echo "📦 Container Status:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""
