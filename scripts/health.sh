#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack Health Monitor
# Monitors all services and reports their status
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_DIR="$(dirname "$SCRIPT_DIR")"

DRY_RUN=false
WATCH_MODE=false
CHECK_INTERVAL=5

usage() {
    cat << EOF
${BOLD}AI-Stack Health Monitor${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -w, --watch         Continuous monitoring mode
    -i, --interval SEC  Check interval in seconds (default: 5)
    -d, --dry-run       Show what would be checked without checking
    -h, --help          Show this help message

${BOLD}EXAMPLES:${NC}
    $0                  # Single health check
    $0 -w               # Continuous monitoring
    $0 -w -i 10         # Monitor every 10 seconds
    $0 -d               # Dry run mode

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--watch) WATCH_MODE=true; shift ;;
        -i|--interval) CHECK_INTERVAL="$2"; shift 2 ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

check_service() {
    local name=$1
    local url=$2
    local port=$3
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}→${NC} Would check $name at $url"
        return 0
    fi
    
    if curl -sf --max-time 5 "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $name is running"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name is not responding"
        return 1
    fi
}

check_docker_service() {
    local name=$1
    local container=$2
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}→${NC} Would check Docker container $container"
        return 0
    fi
    
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        echo -e "  ${GREEN}✓${NC} $name container is $status"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name container is not running"
        return 1
    fi
}

get_system_info() {
    echo ""
    echo -e "${BOLD}System Information:${NC}"
    
    # Memory info
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local mem=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.1f GB", $1/1024/1024/1024}')
        local used_mem=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        echo -e "  ${CYAN}RAM:${NC} $mem total"
    else
        echo -e "  ${CYAN}RAM:${NC} $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 'unknown')"
    fi
    
    # Disk info
    local disk=$(df -h "$AI_STACK_DIR" 2>/dev/null | awk 'NR==2 {print $2, $5}')
    if [[ -n "$disk" ]]; then
        echo -e "  ${CYAN}Disk:${NC} $disk used"
    fi
}

health_check() {
    echo ""
    echo -e "${BOLD}🔍 AI-Stack Health Check${NC}"
    echo -e "${CYAN}$(printf '═%.0s' {1..50})${NC}"
    
    local exit_code=0
    local services_up=0
    local services_down=0
    
    # Check Ollama
    echo -e "\n${BOLD}Local Services:${NC}"
    if check_service "Ollama" "http://localhost:11434/api/version" "11434"; then
        ((services_up++)) || true
    else
        ((services_down++)) || true
        exit_code=1
    fi
    
    # Check Docker services
    echo -e "\n${BOLD}Docker Services:${NC}"
    
    if docker info > /dev/null 2>&1; then
        if check_docker_service "Open WebUI" "openwebui"; then
            ((services_up++)) || true
        else
            ((services_down++)) || true
            exit_code=1
        fi
        
        if check_docker_service "ChromaDB" "chroma"; then
            ((services_up++)) || true
        else
            ((services_down++)) || true
            exit_code=1
        fi
        
        # Check Docker resources
        if [[ "$DRY_RUN" == false ]]; then
            echo -e "\n${BOLD}Docker Resource Usage:${NC}"
            local docker_mem=$(docker stats --no-stream --format "{{.MemUsage}}" 2>/dev/null | head -1 || echo "N/A")
            echo -e "  ${CYAN}Container Memory:${NC} $docker_mem"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Docker is not running"
        ((services_down+=2)) || true
        exit_code=1
    fi
    
    # System info
    get_system_info
    
    # Summary
    echo ""
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  ${GREEN}✓ Online:${NC} $services_up"
    echo -e "  ${RED}✗ Offline:${NC} $services_down"
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\n${GREEN}✓ All services are healthy!${NC}"
    else
        echo -e "\n${RED}✗ Some services are not responding${NC}"
        echo -e "  ${CYAN}Tip:${NC} Run './scripts/setup.sh' to start services"
    fi
    
    return $exit_code
}

if [[ "$WATCH_MODE" == true ]]; then
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  AI-Stack Health Monitor - Continuous Mode                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "Monitoring every ${CHECK_INTERVAL} seconds. Press Ctrl+C to stop.\n"
    
    while true; do
        health_check
        echo ""
        echo -e "${CYAN}Waiting ${CHECK_INTERVAL} seconds...${NC}"
        sleep "$CHECK_INTERVAL"
    done
else
    health_check
fi
