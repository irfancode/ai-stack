#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack Setup Script
# A powerful, containerized AI interface infrastructure
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ── Colors ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Script Configuration ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_DIR="$(dirname "$SCRIPT_DIR")"
DRY_RUN=false
SKIP_MODELS=false
FORCE=false

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
    cat << EOF
${BOLD}AI-Stack Setup${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -d, --dry-run       Show what would be done without doing it
    -f, --force         Skip confirmation prompts
    -s, --skip-models   Don't pull default models
    -h, --help          Show this help

${BOLD}EXAMPLES:${NC}
    $0                  # Full setup
    $0 -d               # Dry run
    $0 -f -s            # Skip models, no prompts

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true; shift ;;
        -f|--force) FORCE=true; shift ;;
        -s|--skip-models) SKIP_MODELS=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ── Logging Functions ─────────────────────────────────────────────────────────
log_info() { echo -e "${CYAN}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

# ── Port Checking ─────────────────────────────────────────────────────────────
check_port() {
    local port=$1
    local name=$2
    if lsof -i:"$port" > /dev/null 2>&1; then
        log_error "Port $port ($name) is already in use"
        log_info "Stop the existing service or use a different port"
        return 1
    fi
    return 0
}

check_all_ports() {
    log_info "Checking port availability..."
    
    local ports=("3000:Open WebUI" "8000:ChromaDB")
    for entry in "${ports[@]}"; do
        local port="${entry%%:*}"
        local name="${entry##*:}"
        if ! check_port "$port" "$name"; then
            return 1
        fi
    done
    
    log_success "All ports available"
    return 0
}

# ── Prerequisites ─────────────────────────────────────────────────────────────
check_prerequisites() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}${CYAN}🚀 AI-Stack Setup${NC}                                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${PURPLE}Containerized AI Interface Infrastructure${NC}                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}📋 Checking prerequisites...${NC}"
    
    # Check for macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "This script is optimized for macOS"
    fi
    
    # Check for OrbStack or Docker
    check_docker() {
        if command -v orb &> /dev/null; then
            log_success "OrbStack found"
            return 0
        elif command -v docker &> /dev/null; then
            log_success "Docker found"
            return 0
        else
            log_error "Neither OrbStack nor Docker found"
            echo ""
            echo "Install OrbStack (recommended for macOS):"
            echo "  → https://orbstack.dev/download"
            echo ""
            echo "Or install Docker Desktop:"
            echo "  → https://docs.docker.com/desktop/install/mac-install/"
            echo ""
            return 1
        fi
    }
    
    if ! check_docker; then
        exit 1
    fi
    
    # Check for Ollama
    if command -v ollama &> /dev/null; then
        local version=$(ollama --version 2>/dev/null || echo "unknown")
        log_success "Ollama installed ($version)"
    else
        log_warning "Ollama not found (optional - for local models)"
        echo -e "      Install: ${CYAN}brew install ollama${NC}"
    fi
    
    echo ""
}

# ── Environment Configuration ─────────────────────────────────────────────────
configure_environment() {
    echo -e "${BOLD}⚙️  Configuring environment...${NC}"
    
    if [[ -f "$AI_STACK_DIR/.env" ]]; then
        log_success ".env already exists"
    else
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would create .env from template"
            return 0
        fi
        
        if [[ -f "$AI_STACK_DIR/.env.example" ]]; then
            cp "$AI_STACK_DIR/.env.example" "$AI_STACK_DIR/.env"
        else
            # Generate secure password
            local secure_password=$(openssl rand -base64 24 2>/dev/null || echo "changeme123")
            
            cat > "$AI_STACK_DIR/.env" << EOF
# ═══════════════════════════════════════════════════════════════
# AI-Stack Environment Configuration
# ═══════════════════════════════════════════════════════════════

# OpenRouter API Key (for cloud models like Claude, GPT-4)
# Get yours at: https://openrouter.ai/keys
OPENROUTER_API_KEY=your-api-key-here

# ── Authentication ─────────────────────────────────────────
WEBUI_AUTH=true
ADMIN_EMAIL=admin@localhost
ADMIN_PASSWORD=${secure_password}

# ── Models ────────────────────────────────────────────────
DEFAULT_MODEL=llama3.2

# ── ChromaDB ────────────────────────────────────────────────
CHROMA_TELEMETRY=false
CHROMA_ORIGINS=http://localhost:3000

# ── WebUI ───────────────────────────────────────────────────
WEBUI_NAME=AI-Stack
EOF
        fi
        log_success "Created .env file"
        
        if [[ "$SECURE_PASSWORD" != "" ]]; then
            echo ""
            log_warning "Generated secure password: $SECURE_PASSWORD"
            log_warning "Save this password! It will not be shown again."
        fi
    fi
}

# ── Pull Docker Images ─────────────────────────────────────────────────────────
pull_docker_images() {
    echo ""
    echo -e "${BOLD}📦 Pulling Docker images...${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would pull:"
        log_info "  - ghcr.io/open-webui/open-webui:main"
        log_info "  - ghcr.io/chroma-core/chroma:latest"
        return 0
    fi
    
    pull_image() {
        local image=$1
        local desc=$2
        echo -e "  ${CYAN}→${NC} Pulling $desc..."
        if docker pull "$image" > /dev/null 2>&1; then
            log_success "$desc"
        else
            log_warning "$desc (may already exist)"
        fi
    }
    
    pull_image "ghcr.io/open-webui/open-webui:main" "Open WebUI"
    pull_image "ghcr.io/chroma-core/chroma:latest" "ChromaDB"
}

# ── Start Services ─────────────────────────────────────────────────────────────
start_services() {
    echo ""
    echo -e "${BOLD}🚀 Starting services...${NC}"
    
    cd "$AI_STACK_DIR"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would start Docker Compose services"
        log_info "Would stop existing containers first"
        return 0
    fi
    
    # Stop existing containers
    docker compose down > /dev/null 2>&1 || true
    
    # Start services
    if ! docker compose up -d; then
        log_error "Failed to start services"
        exit 1
    fi
    
    log_success "Services started"
}

# ── Wait for Services ──────────────────────────────────────────────────────────
wait_for_services() {
    echo ""
    echo -e "${BOLD}⏳ Waiting for services to be ready...${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would wait for:"
        log_info "  - Open WebUI at http://localhost:3000"
        log_info "  - ChromaDB at http://localhost:8000/api/v1/heartbeat"
        return 0
    fi
    
    wait_for_service() {
        local url=$1
        local name=$2
        local max_attempts=30
        local attempt=1
        
        echo -e "  ${CYAN}→${NC} Checking $name..."
        
        while [[ $attempt -le $max_attempts ]]; do
            if curl -sf --max-time 2 "$url" > /dev/null 2>&1; then
                log_success "$name is ready"
                return 0
            fi
            sleep 1
            ((attempt++)) || true
        done
        
        log_warning "$name took too long (may still be starting)"
        return 1
    }
    
    wait_for_service "http://localhost:3000" "Open WebUI"
    wait_for_service "http://localhost:8000/api/v1/heartbeat" "ChromaDB"
}

# ── Start Ollama ───────────────────────────────────────────────────────────────
start_ollama() {
    echo ""
    
    if ! command -v ollama &> /dev/null; then
        log_warning "Ollama not installed - local models won't be available"
        return 0
    fi
    
    echo -e "${BOLD}🧠 Checking Ollama...${NC}"
    
    # Check if Ollama is running
    if curl -sf --max-time 2 http://localhost:11434 > /dev/null 2>&1; then
        log_success "Ollama daemon is running"
    else
        echo -e "  ${CYAN}→${NC} Starting Ollama daemon..."
        if pgrep -x ollama > /dev/null 2>&1; then
            log_success "Ollama daemon started"
        else
            ollama serve > /dev/null 2>&1 &
            sleep 2
            if pgrep -x ollama > /dev/null 2>&1; then
                log_success "Ollama daemon started"
            else
                log_warning "Failed to start Ollama daemon"
            fi
        fi
    fi
    
    if [[ "$SKIP_MODELS" == false ]]; then
        echo -e "  ${CYAN}→${NC} Run ${BOLD}ollama pull llama3.2${NC} to download models"
    fi
}

# ── Summary ─────────────────────────────────────────────────────────────────────
show_summary() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}${GREEN}✅ Setup Complete!${NC}                                            ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}🌐 Open WebUI:${NC}    http://localhost:3000                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}📚 ChromaDB:${NC}      http://localhost:8000                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}🧠 Ollama:${NC}        http://localhost:11434                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi
    
    # Show password if we generated it
    if [[ -n "$SECURE_PASSWORD" ]]; then
        echo -e "${BOLD}📋 Next Steps:${NC}"
        echo ""
        echo -e "  ${CYAN}1.${NC} Open browser: ${BOLD}open http://localhost:3000${NC}"
        echo -e "  ${CYAN}2.${NC} Login with:"
        echo -e "      ${YELLOW}   Email:${NC}    admin@localhost"
        echo -e "      ${YELLOW}   Password:${NC} $SECURE_PASSWORD"
    else
        echo -e "${BOLD}📋 Next Steps:${NC}"
        echo ""
        echo -e "  ${CYAN}1.${NC} Open browser: ${BOLD}open http://localhost:3000${NC}"
        echo -e "  ${CYAN}2.${NC} Login with credentials from .env file"
    fi
    echo ""
    
    # Check if API key needs setting
    if grep -q "your-api-key-here" "$AI_STACK_DIR/.env" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC} Add your OpenRouter API key to ${BOLD}.env${NC} for cloud models"
    fi
    
    echo ""
    echo -e "${BOLD}⌨️  Useful Commands:${NC}"
    echo ""
    echo -e "  ${CYAN}./scripts/validate.sh${NC}    Validate configuration"
    echo -e "  ${CYAN}./scripts/health.sh${NC}      Check service health"
    echo -e "  ${CYAN}./scripts/backup.sh${NC}      Backup data"
    echo -e "  ${CYAN}docker compose logs -f${NC}   View logs"
    echo -e "  ${CYAN}docker compose down${NC}      Stop services"
    echo ""
    
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}Happy AI hacking! 🚀${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ── Main ────────────────────────────────────────────────────────────────────────
main() {
    check_prerequisites
    
    if ! check_all_ports; then
        if [[ "$FORCE" != true ]]; then
            echo ""
            read -p "Ports are in use. Continue anyway? (y/N) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Setup cancelled"
                exit 1
            fi
        fi
    fi
    
    configure_environment
    pull_docker_images
    start_services
    wait_for_services
    start_ollama
    show_summary
}

main
