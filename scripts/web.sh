#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack - Web UI Mode Launcher
# Starts the Docker-based web interface
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
DRY_RUN=false
LEAN_MODE=false
SHOW_LOGS=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    cat << EOF
${BOLD}AI-Stack - Web UI Launcher${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -l, --lean     Use lightweight compose file
    -d, --dry-run  Show what would be done
    -f, --follow   Show logs after starting
    -h, --help     Show this help

${BOLD}EXAMPLES:${NC}
    $0                  # Start full WebUI
    $0 -l               # Start lean WebUI
    $0 -f               # Start with logs visible
    $0 -d               # Dry run

EOF
    exit 0
}

log_info() { echo -e "${CYAN}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--lean) LEAN_MODE=true; shift ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        -f|--follow) SHOW_LOGS=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Check Docker
check_docker() {
    if ! command -v docker &> /dev/null && ! command -v orb &> /dev/null; then
        log_error "Docker or OrbStack is required"
        echo "Install OrbStack: https://orbstack.dev"
        exit 1
    fi
    
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running"
        echo "Start Docker or OrbStack and try again"
        exit 1
    fi
}

# Check port availability
check_port() {
    local port=$1
    if lsof -i:"$port" > /dev/null 2>&1; then
        log_warning "Port $port is already in use"
        return 1
    fi
    return 0
}

# Start services
start_webui() {
    cd "$AI_STACK_DIR"
    
    # Select compose file
    local compose_file="docker-compose.yml"
    if [[ "$LEAN_MODE" == true ]]; then
        compose_file="docker-compose.lean.yml"
        log_info "Using lean configuration"
    fi
    
    if [[ ! -f "$compose_file" ]]; then
        log_error "Compose file not found: $compose_file"
        exit 1
    fi
    
    # Check ports
    check_port 3000 || {
        log_warning "Open WebUI port (3000) is in use"
    }
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would start Docker Compose with: $compose_file"
        log_info "Would open: http://localhost:3000"
        return 0
    fi
    
    # Stop existing
    docker compose -f "$compose_file" down > /dev/null 2>&1 || true
    
    # Start
    echo ""
    log_info "Starting WebUI..."
    
    if [[ "$SHOW_LOGS" == true ]]; then
        docker compose -f "$compose_file" up
    else
        docker compose -f "$compose_file" up -d
        
        # Wait for ready
        echo -n "  "
        for i in {1..30}; do
            if curl -sf http://localhost:3000 > /dev/null 2>&1; then
                echo ""
                log_success "WebUI is ready!"
                break
            fi
            echo -n "."
            sleep 1
        done
        
        echo ""
        log_success "Open WebUI at: http://localhost:3000"
    fi
}

# Main
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}AI-Stack - Web UI Mode${NC}                               ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

check_docker

if [[ "$SHOW_LOGS" == true ]] || [[ "$DRY_RUN" == false ]]; then
    echo ""
fi

start_webui

if [[ "$DRY_RUN" == false ]] && [[ "$SHOW_LOGS" == false ]]; then
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
fi
