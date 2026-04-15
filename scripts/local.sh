#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack - Local Terminal Mode
# Optimized for 8GB systems with minimal RAM usage
# ═══════════════════════════════════════════════════════════════════════════════
# Requirements: Ollama (brew install ollama), aichat (brew install aichat)
# RAM usage: ~50MB (aichat) + ~4GB (Ollama model)
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
DEFAULT_MODEL="${DEFAULT_MODEL:-llama3.2:3b}"
DRY_RUN=false

usage() {
    cat << EOF
${BOLD}AI-Stack - Local Terminal Mode${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS] [MODEL]

${BOLD}OPTIONS:${NC}
    MODEL          Model to use (default: $DEFAULT_MODEL)
    -d, --dry-run  Show what would be done
    -l, --list     List available models
    -h, --help     Show this help

${BOLD}EXAMPLES:${NC}
    $0                  # Start with default model
    $0 llama3.2:3b       # Use specific model
    $0 qwen3:1b          # Use lightweight model
    $0 -l                # List available models

EOF
    exit 0
}

log_info() { echo -e "${CYAN}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

# Check Ollama is installed
check_ollama() {
    if ! command -v ollama &> /dev/null; then
        log_error "Ollama is not installed"
        echo ""
        echo "Install Ollama:"
        echo "  brew install ollama"
        echo ""
        exit 1
    fi
}

# Check Ollama is running
check_ollama_running() {
    if ! pgrep -x "ollama" > /dev/null 2>&1; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "Would start Ollama daemon"
            return 0
        fi
        
        log_info "Starting Ollama daemon..."
        ollama serve > /dev/null 2>&1 &
        sleep 3
        
        if ! pgrep -x "ollama" > /dev/null 2>&1; then
            log_error "Failed to start Ollama daemon"
            exit 1
        fi
    fi
}

# List available models
list_models() {
    echo ""
    echo -e "${BOLD}Available Models:${NC}"
    echo ""
    
    if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
        log_error "Ollama is not running"
        echo "Run 'ollama serve' first"
        exit 1
    fi
    
    ollama list 2>/dev/null || echo "No models installed"
    echo ""
    echo "Recommended for 8GB RAM:"
    echo "  llama3.2:3b   - General chat (~2GB)"
    echo "  qwen3:1b      - Quick tasks (~1.2GB)"
    echo "  phi3:3.8b-mini - Better quality (~2.4GB)"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true; shift ;;
        -l|--list) list_models; exit 0 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *) MODEL="$1"; shift ;;
    esac
done

MODEL="${MODEL:-$DEFAULT_MODEL}"

# Banner
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Lean AI Stack - Local Terminal Mode${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  Optimized for 8GB Mac                                  ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

# Run checks
check_ollama
check_ollama_running

echo -e "${GREEN}✓${NC} Ollama running at http://localhost:11434"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}→${NC} Would start chat with model: $MODEL"
    echo -e "${CYAN}→${NC} Would run: ollama run $MODEL"
    exit 0
fi

echo ""
echo -e "${YELLOW}Tip: Use /set parameters to configure, /exit to quit${NC}"
echo ""

# Launch Ollama chat
ollama run "$MODEL"
