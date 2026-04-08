#!/bin/bash

# ============================================
# SHUTDOWN SCRIPT
# PT Optima Smartindo - Web Scraping System
# ============================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  PT Optima Smartindo - System Shutdown         ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

read -p "Stop all services? Data will be preserved. (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}🛑 Stopping all services...${NC}"
docker compose down

echo ""
echo -e "${GREEN}✓ All services stopped.${NC}"
echo ""
echo "💾 Your data is safe in Docker volumes."
echo "   To restart: bash start.sh"
echo "   To delete ALL data: docker compose down -v"
echo ""
