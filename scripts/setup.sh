#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack Setup Script
# A powerful, containerized AI interface infrastructure
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_STACK_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}${CYAN}🚀 AI-Stack Setup${NC}                                          ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${PURPLE}Containerized AI Interface Infrastructure${NC}                  ${PURPLE}║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Check Prerequisites ──────────────────────────────────────────────────────
echo -e "${BOLD}📋 Checking prerequisites...${NC}"

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}⚠️  Warning: This script is optimized for macOS${NC}"
fi

# Check for OrbStack or Docker
check_docker() {
    if command -v orb &> /dev/null; then
        echo -e "  ${GREEN}✅${NC} OrbStack"
        return 0
    elif command -v docker &> /dev/null; then
        echo -e "  ${GREEN}✅${NC} Docker"
        return 0
    else
        echo -e "  ${RED}❌${NC} Neither OrbStack nor Docker found"
        return 1
    fi
}

if ! check_docker; then
    echo ""
    echo -e "${RED}❌ Error: Docker or OrbStack is required${NC}"
    echo ""
    echo "Install OrbStack (recommended for macOS):"
    echo "  → https://orbstack.dev/download"
    echo ""
    echo "Or install Docker Desktop:"
    echo "  → https://docs.docker.com/desktop/install/mac-install/"
    echo ""
    exit 1
fi

# Check for Ollama
if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✅${NC} Ollama ($OLLAMA_VERSION)"
else
    echo -e "  ${YELLOW}⚠️${NC} Ollama not found (optional - for local models)"
    echo -e "      Install: ${CYAN}brew install ollama${NC}"
fi

echo ""

# ── Create .env file ────────────────────────────────────────────────────────
echo -e "${BOLD}⚙️  Configuring environment...${NC}"

if [[ ! -f "$AI_STACK_DIR/.env" ]]; then
    cat > "$AI_STACK_DIR/.env" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# AI-Stack Environment Configuration
# ═══════════════════════════════════════════════════════════════

# OpenRouter API Key (for cloud models like Claude, GPT-4)
# Get yours at: https://openrouter.ai/keys
OPENROUTER_API_KEY=your-api-key-here

# ── Authentication ─────────────────────────────────────────
# Set to true to enable authentication
WEBUI_AUTH=true

# Admin credentials
ADMIN_EMAIL=admin@localhost
ADMIN_PASSWORD=changeme123

# ── Models ────────────────────────────────────────────────
# Default model to use
DEFAULT_MODEL=llama3.2

# ── ChromaDB ──────────────────────────────────────────────
# Telemetry (set to false for privacy)
CHROMA_TELEMETRY=false

# Allowed origins (comma-separated)
CHROMA_ORIGINS=http://localhost:3000

# ── WebUI ────────────────────────────────────────────────
# Name of your AI-Stack
WEBUI_NAME=AI-Stack
EOF
    echo -e "  ${GREEN}✅${NC} Created .env file"
else
    echo -e "  ${YELLOW}⏭️${NC} .env already exists"
fi

# ── Pull Docker Images ────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}📦 Pulling Docker images...${NC}"

pull_image() {
    local image=$1
    local desc=$2
    echo -e "  ${CYAN}→${NC} Pulling $desc..."
    docker pull $image > /dev/null 2>&1 && echo -e "  ${GREEN}✅${NC} $desc" || echo -e "  ${YELLOW}⚠️${NC} $desc (may already exist)"
}

pull_image "ghcr.io/open-webui/open-webui:main" "Open WebUI"
pull_image "ghcr.io/chroma-core/chroma:latest" "ChromaDB"

# ── Start Services ───────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}🚀 Starting services...${NC}"

cd "$AI_STACK_DIR"

# Stop existing containers
docker compose down > /dev/null 2>&1 || true

# Start services
docker compose up -d

echo -e "  ${GREEN}✅${NC} Services started"

# ── Wait for services ───────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}⏳ Waiting for services to be ready...${NC}"

wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "  ${CYAN}→${NC} Checking $name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✅${NC} $name is ready"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo -e "  ${YELLOW}⚠️${NC} $name took too long (may still be starting)"
    return 1
}

wait_for_service "http://localhost:3000" "Open WebUI"
wait_for_service "http://localhost:8000/api/v1/heartbeat" "ChromaDB"

# ── Start Ollama (if available) ─────────────────────────────────────────────
echo ""
if command -v ollama &> /dev/null; then
    echo -e "${BOLD}🧠 Starting Ollama...${NC}"
    
    # Check if Ollama is running
    if ! curl -s http://localhost:11434 > /dev/null 2>&1; then
        echo -e "  ${CYAN}→${NC} Starting Ollama daemon..."
        pgrep -x ollama > /dev/null || ollama serve &
        sleep 2
    fi
    
    echo -e "  ${GREEN}✅${NC} Ollama ready"
    echo -e "  ${CYAN}   Run ${BOLD}ollama pull llama3.2${NC} to download models"
else
    echo -e "${YELLOW}⚠️  Ollama not installed - local models won't be available${NC}"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
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

# ── Next Steps ──────────────────────────────────────────────────────────────
echo -e "${BOLD}📋 Next Steps:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Open browser: ${BOLD}open http://localhost:3000${NC}"
echo -e "  ${CYAN}2.${NC} Login with:"
echo -e "      ${YELLOW}   Email:${NC}    admin@localhost"
echo -e "      ${YELLOW}   Password:${NC} changeme123"
echo -e "      ${GRAY}   (Change these in .env file)${NC}"
echo ""

# Check if .env needs API key
if grep -q "your-api-key-here" "$AI_STACK_DIR/.env" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠️${NC} Add your OpenRouter API key to ${BOLD}.env${NC} for cloud models"
fi

echo ""

# ── Useful Commands ─────────────────────────────────────────────────────────
echo -e "${BOLD}⌨️  Useful Commands:${NC}"
echo ""
echo -e "  ${CYAN}docker compose logs -f${NC}     View logs"
echo -e "  ${CYAN}docker compose restart${NC}       Restart services"
echo -e "  ${CYAN}docker compose down${NC}          Stop services"
echo -e "  ${CYAN}ollama pull llama3.2${NC}         Download model"
echo ""

echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}Happy AI hacking! 🚀${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
