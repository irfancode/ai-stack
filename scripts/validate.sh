#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack Config Validator
# Validates .env configuration and prerequisites
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
ENV_FILE="${AI_STACK_DIR}/.env"

ERRORS=0
WARNINGS=0

print_header() {
    echo ""
    echo -e "${BOLD}🔍 AI-Stack Configuration Validator${NC}"
    echo -e "${CYAN}$(printf '═%.0s' {1..50})${NC}"
}

validate_env_file() {
    echo -e "\n${BOLD}📄 Environment File:${NC}"
    
    if [[ ! -f "$ENV_FILE" ]]; then
        echo -e "  ${YELLOW}⚠${NC} .env file not found"
        echo -e "  ${CYAN}→${NC} Copy .env.example to .env and configure"
        ((WARNINGS++)) || true
        return 1
    fi
    
    echo -e "  ${GREEN}✓${NC} .env file exists"
    
    # Source it for validation
    set -a
    source "$ENV_FILE"
    set +a
    
    return 0
}

validate_api_key() {
    echo -e "\n${BOLD}🔑 API Keys:${NC}"
    
    if [[ -z "$OPENROUTER_API_KEY" ]] || [[ "$OPENROUTER_API_KEY" == *"your-api-key-here"* ]]; then
        echo -e "  ${YELLOW}⚠${NC} OpenRouter API key not set or is placeholder"
        echo -e "      ${CYAN}→${NC} Get a key at https://openrouter.ai/keys"
        ((WARNINGS++)) || true
    else
        echo -e "  ${GREEN}✓${NC} OpenRouter API key configured"
    fi
}

validate_credentials() {
    echo -e "\n${BOLD}🔐 Authentication:${NC}"
    
    local needs_attention=false
    
    # Check auth setting
    if [[ "$WEBUI_AUTH" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Authentication is enabled"
        
        # Check for default password
        if [[ "$ADMIN_PASSWORD" == "changeme123" ]] || [[ "$ADMIN_PASSWORD" == "admin123" ]]; then
            echo -e "  ${RED}✗${NC} Using default password!"
            echo -e "      ${CYAN}→${NC} Generate secure password: openssl rand -base64 24"
            ((ERRORS++)) || true
            needs_attention=true
        elif [[ ${#ADMIN_PASSWORD} -lt 12 ]]; then
            echo -e "  ${YELLOW}⚠${NC} Password is too short (min 12 characters recommended)"
            ((WARNINGS++)) || true
        else
            echo -e "  ${GREEN}✓${NC} Password strength is acceptable"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Authentication is DISABLED"
        echo -e "      ${CYAN}→${NC} Enable WEBUI_AUTH=true for security"
        ((WARNINGS++)) || true
    fi
}

validate_ports() {
    echo -e "\n${BOLD}🔌 Port Availability:${NC}"
    
    local ports=("3000" "8000" "11434")
    local port_names=("Open WebUI" "ChromaDB" "Ollama")
    
    for i in "${!ports[@]}"; do
        local port="${ports[$i]}"
        local name="${port_names[$i]}"
        
        if lsof -i:"$port" > /dev/null 2>&1; then
            echo -e "  ${YELLOW}⚠${NC} Port $port ($name) is in use"
            ((WARNINGS++)) || true
        else
            echo -e "  ${GREEN}✓${NC} Port $port ($name) is available"
        fi
    done
}

validate_prerequisites() {
    echo -e "\n${BOLD}📋 Prerequisites:${NC}"
    
    # Docker
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} Docker is installed and running"
        else
            echo -e "  ${RED}✗${NC} Docker is installed but not running"
            ((ERRORS++)) || true
        fi
    elif command -v orb &> /dev/null; then
        if docker info &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} OrbStack is installed and running"
        else
            echo -e "  ${RED}✗${NC} OrbStack is installed but not running"
            ((ERRORS++)) || true
        fi
    else
        echo -e "  ${RED}✗${NC} Neither Docker nor OrbStack found"
        echo -e "      ${CYAN}→${NC} Install OrbStack: https://orbstack.dev"
        ((ERRORS++)) || true
    fi
    
    # Ollama
    if command -v ollama &> /dev/null; then
        local version=$(ollama --version 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC} Ollama is installed ($version)"
        
        # Check if running
        if pgrep -x ollama > /dev/null; then
            echo -e "  ${GREEN}✓${NC} Ollama daemon is running"
        else
            echo -e "  ${YELLOW}⚠${NC} Ollama daemon is not running"
            echo -e "      ${CYAN}→${NC} Run 'ollama serve' to start"
            ((WARNINGS++)) || true
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Ollama not installed (optional for local models)"
        echo -e "      ${CYAN}→${NC} Install: brew install ollama"
        ((WARNINGS++)) || true
    fi
}

validate_docker_config() {
    echo -e "\n${BOLD}🐳 Docker Configuration:${NC}"
    
    if [[ ! -f "${AI_STACK_DIR}/docker-compose.yml" ]]; then
        echo -e "  ${RED}✗${NC} docker-compose.yml not found"
        ((ERRORS++)) || true
        return
    fi
    
    echo -e "  ${GREEN}✓${NC} docker-compose.yml exists"
    
    # Validate compose file
    cd "$AI_STACK_DIR"
    if docker compose config > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Docker Compose configuration is valid"
    else
        echo -e "  ${RED}✗${NC} Docker Compose configuration has errors"
        docker compose config 2>&1 | head -5
        ((ERRORS++)) || true
    fi
}

validate_security() {
    echo -e "\n${BOLD}🛡️  Security Checks:${NC}"
    
    # Check if .env is in .gitignore
    if grep -q "^\.env$" "${AI_STACK_DIR}/.gitignore" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} .env is in .gitignore"
    else
        echo -e "  ${RED}✗${NC} .env is NOT in .gitignore!"
        ((ERRORS++)) || true
    fi
    
    # Check for exposed secrets in .env
    if grep -q "OPENROUTER_API_KEY=sk-or-v1-your" "$ENV_FILE" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} API key is still the placeholder!"
        ((ERRORS++)) || true
    fi
    
    # Check for SSL/HTTPS in production
    if [[ "$WEBUI_URL" == "http://"* ]] && [[ "$WEBUI_URL" != "localhost"* ]]; then
        echo -e "  ${YELLOW}⚠${NC} Non-localhost URL uses HTTP (consider HTTPS)"
        ((WARNINGS++)) || true
    fi
}

validate_system_resources() {
    echo -e "\n${BOLD}💻 System Resources:${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Check available RAM
        local mem_gb=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}')
        echo -e "  ${CYAN}Total RAM:${NC} ${mem_gb}GB"
        
        if [[ $mem_gb -lt 8 ]]; then
            echo -e "  ${YELLOW}⚠${NC} Less than 8GB RAM - use lightweight models"
            ((WARNINGS++)) || true
        else
            echo -e "  ${GREEN}✓${NC} Sufficient RAM for most models"
        fi
        
        # Check chip type
        local chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
        if [[ "$chip" == *"Apple"* ]]; then
            echo -e "  ${GREEN}✓${NC} Apple Silicon detected (optimized)"
        fi
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                      Validation Summary                        ${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo -e "  Your configuration looks good."
    elif [[ $ERRORS -eq 0 ]]; then
        echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
        echo -e "  Review the warnings above for best results."
    else
        echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
        echo -e "  Please fix the errors before continuing."
    fi
    
    echo ""
    
    if [[ $ERRORS -eq 0 ]]; then
        echo -e "${GREEN}✓ Ready to start!${NC}"
        echo -e "  Run: ${CYAN}./scripts/setup.sh${NC}"
    else
        echo -e "${RED}✗ Please fix errors before starting${NC}"
    fi
    
    echo ""
}

# Main
print_header
validate_env_file
validate_api_key
validate_credentials
validate_ports
validate_prerequisites
validate_docker_config
validate_security
validate_system_resources
print_summary

exit $ERRORS
