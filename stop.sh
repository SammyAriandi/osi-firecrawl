#!/bin/bash
set -e

# ============================================
# SHUTDOWN SCRIPT
# PT Optima Smartindo - Web Scraping System
# ============================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Stop services
stop_services() {
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    log "🛑 Stopping all services..."
    log ""
    
    # Stop n8n
    if docker-compose -f "$PROJECT_DIR/docker-compose.n8n.yml" ps optima-n8n 2>/dev/null | grep -q "Up"; then
        log "Stopping n8n..."
        docker-compose -f "$PROJECT_DIR/docker-compose.n8n.yml" down
        log_success "n8n stopped"
    fi
    
    # Stop Firecrawl
    if [ -d "$PROJECT_DIR/firecrawl" ]; then
        if docker-compose -f "$PROJECT_DIR/firecrawl/docker-compose.yml" ps firecrawl-api 2>/dev/null | grep -q "Up"; then
            log "Stopping Firecrawl..."
            cd "$PROJECT_DIR/firecrawl"
            docker-compose down
            cd "$PROJECT_DIR"
            log_success "Firecrawl stopped"
        fi
    fi
    
    # Stop PostgreSQL
    if docker-compose -f "$PROJECT_DIR/docker-compose.postgres.yml" ps optima-postgres 2>/dev/null | grep -q "Up"; then
        log "Stopping PostgreSQL..."
        docker-compose -f "$PROJECT_DIR/docker-compose.postgres.yml" down
        log_success "PostgreSQL stopped"
    fi
    
    log ""
    log_success "All services stopped"
    log ""
    log "💾 Data persisted in Docker volumes:"
    docker volume ls | grep optima
    log ""
}

# Main
main() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║  PT Optima Smartindo - Web Scraping System Shutdown  ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo ""
    
    # Ask for confirmation
    read -p "Are you sure you want to stop all services? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Shutdown cancelled"
        exit 0
    fi
    
    stop_services
    
    echo "ℹ️  To restart services, run: bash start.sh"
    echo ""
}

main
