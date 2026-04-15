#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack - Lean Setup Script
# Optimized for 8GB systems with model downloads
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_DIR="$(dirname "$SCRIPT_DIR")"
DRY_RUN=false

usage() {
    cat << EOF
${BOLD}AI-Stack Lean Setup${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -d, --dry-run       Show what would be done
    -m, --model MODEL   Specific model to download
    -h, --help          Show this help

${BOLD}EXAMPLES:${NC}
    $0                  # Full lean setup
    $0 -d               # Dry run
    $0 -m qwen3:1b      # Download specific model

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true; shift ;;
        -m|--model) MODEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

log_info() { echo -e "${CYAN}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }

# Banner
echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}${CYAN}🚀 AI-Stack Lean Setup${NC}                                     ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${PURPLE}Optimized for 8GB Systems${NC}                                 ${PURPLE}║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"

# Check Ollama
echo ""
echo -e "${BOLD}📋 Prerequisites Check${NC}"

if ! command -v ollama &> /dev/null; then
    log_warning "Ollama not installed"
    echo ""
    echo "Install Ollama:"
    echo "  brew install ollama"
    echo ""
    exit 1
fi

log_success "Ollama installed"

# Start Ollama if not running
if ! pgrep -x ollama > /dev/null 2>&1; then
    echo -e "  ${CYAN}→${NC} Starting Ollama daemon..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

log_success "Ollama running"

# Model selection
echo ""
echo -e "${BOLD}📦 Recommended Models for 8GB RAM${NC}"
echo ""
echo "  ┌─────────────────┬────────┬──────────────────┬──────────┐"
echo "  │ Model           │ Size   │ Best For         │ Speed    │"
echo "  ├─────────────────┼────────┼──────────────────┼──────────┤"
echo "  │ llama3.2:3b     │ ~2GB   │ General chat     │ ~30 t/s  │"
echo "  │ qwen3:1b        │ ~1.2GB │ Quick tasks      │ ~50 t/s  │"
echo "  │ phi3:3.8b-mini  │ ~2.4GB │ Better quality   │ ~25 t/s  │"
echo "  └─────────────────┴────────┴──────────────────┴──────────┘"
echo ""

if [[ -n "$MODEL" ]]; then
    SELECTED_MODEL="$MODEL"
    echo -e "Selected: ${CYAN}$MODEL${NC}"
else
    echo -e "${YELLOW}No model specified. Available options:${NC}"
    echo ""
    echo "  1) llama3.2:3b     - General chat (recommended)"
    echo "  2) qwen3:1b        - Quick tasks, scripts"
    echo "  3) phi3:3.8b-mini  - Better quality"
    echo "  4) All of the above"
    echo "  5) Skip model download"
    echo ""
    read -p "Select option (1-5): " choice
    
    case $choice in
        1) SELECTED_MODEL="llama3.2:3b" ;;
        2) SELECTED_MODEL="qwen3:1b" ;;
        3) SELECTED_MODEL="phi3:3.8b-mini" ;;
        4) SELECTED_MODELS=("llama3.2:3b" "qwen3:1b" "phi3:3.8b-mini") ;;
        5) SELECTED_MODELS=() ;;
        *) SELECTED_MODEL="llama3.2:3b" ;;
    esac
fi

# Pull models
pull_model() {
    local model=$1
    echo ""
    echo -e "${BOLD}📥 Downloading model: $model${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would pull: $model"
        return 0
    fi
    
    if ollama list 2>/dev/null | grep -q "^$model "; then
        log_success "$model already downloaded"
        return 0
    fi
    
    if ollama pull "$model"; then
        log_success "Downloaded $model"
    else
        log_warning "Failed to download $model"
    fi
}

if [[ -n "$SELECTED_MODEL" ]]; then
    pull_model "$SELECTED_MODEL"
elif [[ ${#SELECTED_MODELS[@]} -gt 0 ]]; then
    for model in "${SELECTED_MODELS[@]}"; do
        pull_model "$model"
    done
fi

# Environment optimization
echo ""
echo -e "${BOLD}⚙️  Environment Optimizations${NC}"

if [[ "$DRY_RUN" == true ]]; then
    log_info "Would add Ollama optimizations to ~/.zshrc"
else
    add_ollama_env() {
        local env_var="$1"
        local value="$2"
        
        if ! grep -q "$env_var" ~/.zshrc 2>/dev/null; then
            echo "export $env_var=$value" >> ~/.zshrc
            log_success "Added $env_var to ~/.zshrc"
        else
            log_info "$env_var already configured"
        fi
    }
    
    add_ollama_env "OLLAMA_MAX_LOADED_MODELS" "1"
    add_ollama_env "OLLAMA_NUM_PARALLEL" "1"
    add_ollama_env "OLLAMA_CTX_SIZE" "2048"
    add_ollama_env "OLLAMA_KEEP_ALIVE" "15m"
    add_ollama_env "OLLAMA_FLASH_ATTENTION" "1"
    
    echo ""
    echo -e "${YELLOW}Run 'source ~/.zshrc' or restart terminal to apply changes${NC}"
fi

# Summary
echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}${GREEN}✅ Lean Setup Complete!${NC}                                      ${PURPLE}║${NC}"
echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}                                                                  ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}Next Steps:${NC}                                                   ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                                  ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${CYAN}1.${NC} ./scripts/setup.sh        - Start full Docker setup        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${CYAN}2.${NC} ./scripts/local.sh        - Terminal chat mode              ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${CYAN}3.${NC} ./scripts/web-simple.sh   - Simple web UI (no Docker)       ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                                  ${PURPLE}║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
