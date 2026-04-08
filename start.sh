#!/bin/bash
set -e

# ============================================
# STARTUP SCRIPT
# PT Optima Smartindo - Web Scraping System
# ============================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_POSTGRES="docker-compose.postgres.yml"
DOCKER_COMPOSE_N8N="docker-compose.n8n.yml"
FIRECRAWL_DIR="firecrawl"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        echo "Install from: https://docs.docker.com/get-docker/"
        exit 1
    fi
    log_success "Docker found: $(docker --version)"
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        echo "Install from: https://docs.docker.com/compose/install/"
        exit 1
    fi
    log_success "Docker Compose found: $(docker-compose --version)"
    
    if [ ! -f ".env" ]; then
        log_warning ".env file not found"
        if [ -f ".env.example" ]; then
            log "Creating .env from .env.example..."
            cp .env.example .env
            log_success ".env created (please review and update if needed)"
        else
            log_error ".env.example not found"
            exit 1
        fi
    fi
}

# Create necessary directories
create_directories() {
    log "📁 Creating necessary directories..."
    
    mkdir -p n8n_workflows
    mkdir -p n8n_plugins
    mkdir -p backups
    mkdir -p prometheus_data
    mkdir -p grafana_data
    mkdir -p logs
    
    log_success "Directories created"
}

# Start PostgreSQL
start_postgresql() {
    log "🗄️  Starting PostgreSQL..."
    
    if docker-compose -f "$DOCKER_COMPOSE_POSTGRES" ps optima-postgres &>/dev/null; then
        log_warning "PostgreSQL is already running"
        return 0
    fi
    
    cd "$PROJECT_DIR"
    docker-compose -f "$DOCKER_COMPOSE_POSTGRES" up -d
    
    log "⏳ Waiting for PostgreSQL to be ready..."
    sleep 10
    
    # Health check
    if docker exec optima-postgres pg_isready -U optima_user &>/dev/null; then
        log_success "PostgreSQL is ready"
    else
        log_error "PostgreSQL health check failed"
        log "Retrying in 5 seconds..."
        sleep 5
        docker exec optima-postgres pg_isready -U optima_user
    fi
}

# Initialize database schema
init_database() {
    log "💾 Initializing database schema..."
    
    # Check if tables already exist
    TABLE_COUNT=$(docker exec optima-postgres psql -U optima_user -d optima_erp -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('scraping', 'erp');" 2>/dev/null || echo "0")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        log_success "Database schema already initialized ($TABLE_COUNT tables found)"
        return 0
    fi
    
    log "Executing schema.sql..."
    docker exec -i optima-postgres psql -U optima_user -d optima_erp < schema.sql
    
    if [ $? -eq 0 ]; then
        log_success "Database schema initialized"
    else
        log_error "Failed to initialize database schema"
        exit 1
    fi
}

# Start Firecrawl
start_firecrawl() {
    log "🕷️  Starting Firecrawl..."
    
    if [ ! -d "$FIRECRAWL_DIR" ]; then
        log_warning "Firecrawl directory not found"
        log "Cloning Firecrawl repository..."
        git clone https://github.com/firecrawl/firecrawl.git "$FIRECRAWL_DIR"
    fi
    
    cd "$PROJECT_DIR/$FIRECRAWL_DIR"
    
    if docker-compose ps firecrawl-api &>/dev/null 2>&1; then
        log_warning "Firecrawl is already running"
        cd "$PROJECT_DIR"
        return 0
    fi
    
    log "Building Firecrawl Docker image (this may take 5-10 minutes)..."
    docker-compose build 2>&1 | tail -n 20
    
    log "Starting Firecrawl services..."
    docker-compose up -d
    
    log "⏳ Waiting for Firecrawl to be ready..."
    sleep 15
    
    # Health check
    for i in {1..10}; do
        if curl -f http://localhost:3002/health &>/dev/null; then
            log_success "Firecrawl is ready"
            cd "$PROJECT_DIR"
            return 0
        fi
        log "Attempt $i/10: Waiting for Firecrawl..."
        sleep 5
    done
    
    log_error "Firecrawl health check failed after 50 seconds"
    log "Checking logs..."
    docker-compose logs firecrawl-api | tail -20
    cd "$PROJECT_DIR"
    exit 1
}

# Start n8n
start_n8n() {
    log "⚙️  Starting n8n..."
    
    cd "$PROJECT_DIR"
    
    if docker-compose -f "$DOCKER_COMPOSE_N8N" ps optima-n8n &>/dev/null 2>&1; then
        log_warning "n8n is already running"
        return 0
    fi
    
    docker-compose -f "$DOCKER_COMPOSE_N8N" up -d
    
    log "⏳ Waiting for n8n to be ready..."
    sleep 20
    
    # Health check
    if curl -f http://localhost:5678/healthz &>/dev/null; then
        log_success "n8n is ready"
    else
        log_warning "n8n may still be starting..."
        log "Complete startup may take 1-2 minutes"
        log "Monitor with: docker logs -f optima-n8n"
    fi
}

# Display access information
display_info() {
    log ""
    log "=========================================="
    log "✨ System Startup Complete!"
    log "=========================================="
    log ""
    log "📍 Access Points:"
    log ""
    log "  ${GREEN}n8n Workflow Orchestrator${NC}"
    log "    URL: http://localhost:5678"
    log "    User: admin"
    log "    Password: Optima2024!@#"
    log ""
    log "  ${GREEN}pgAdmin Database UI${NC}"
    log "    URL: http://localhost:5050"
    log "    Email: admin@optima.local"
    log "    Password: AdminOptima123!@#"
    log ""
    log "  ${GREEN}Firecrawl API${NC}"
    log "    URL: http://localhost:3002"
    log "    Health: http://localhost:3002/health"
    log ""
    log "  ${GREEN}PostgreSQL Database${NC}"
    log "    Host: localhost:5432"
    log "    User: optima_user"
    log "    Database: optima_erp"
    log ""
    log "=========================================="
    log ""
    log "📋 Next Steps:"
    log "  1. Open http://localhost:5678 in your browser"
    log "  2. Login with admin credentials above"
    log "  3. Create your first workflow"
    log "  4. Test with sample URLs"
    log ""
    log "🔍 Monitor Services:"
    log "  • Docker containers:"
    log "    ${YELLOW}docker ps${NC}"
    log "  • View logs:"
    log "    ${YELLOW}docker logs -f optima-n8n${NC}"
    log "    ${YELLOW}docker logs -f firecrawl-api${NC}"
    log ""
    log "⏹️  Stop All Services:"
    log "  ${YELLOW}bash stop.sh${NC}"
    log ""
}

# Test endpoints
test_endpoints() {
    log ""
    log "🧪 Testing endpoints..."
    log ""
    
    # Test Firecrawl
    if curl -s http://localhost:3002/health | grep -q "ok"; then
        log_success "Firecrawl API is responding"
    else
        log_warning "Firecrawl API may not be ready yet"
    fi
    
    # Test n8n
    if curl -s http://localhost:5678/healthz | grep -q "ok"; then
        log_success "n8n is responding"
    else
        log_warning "n8n may still be initializing"
    fi
    
    # Test PostgreSQL
    if docker exec optima-postgres pg_isready -U optima_user &>/dev/null; then
        log_success "PostgreSQL is responding"
    else
        log_error "PostgreSQL is not responding"
    fi
}

# Main execution
main() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  PT Optima Smartindo - Web Scraping System Startup  ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    create_directories
    start_postgresql
    init_database
    start_firecrawl
    start_n8n
    test_endpoints
    display_info
    
    log_success "All services started successfully!"
}

# Error handling
trap 'log_error "Setup failed"; exit 1' ERR

# Run main function
main
