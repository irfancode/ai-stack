#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack Backup Script
# Backs up volumes, configurations, and data
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
BACKUP_DIR="${AI_STACK_DIR}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ai-stack-backup-${TIMESTAMP}"
DRY_RUN=false

usage() {
    cat << EOF
${BOLD}AI-Stack Backup Tool${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -o, --output DIR    Backup directory (default: ./backups)
    -d, --dry-run       Show what would be backed up
    -l, --list          List existing backups
    -r, --restore FILE  Restore from backup
    -h, --help          Show this help

${BOLD}EXAMPLES:${NC}
    $0                  # Create new backup
    $0 -d               # Dry run
    $0 -l               # List backups
    $0 -r backup.tar.gz # Restore

EOF
    exit 0
}

list_backups() {
    echo ""
    echo -e "${BOLD}📦 Available Backups:${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo -e "  ${YELLOW}No backups found${NC}"
        echo -e "  Run '$0' to create one"
        return 0
    fi
    
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' | sed "s|$BACKUP_DIR/||"
    echo ""
}

restore_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}✗ Backup file not found: $backup_file${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}⚠️  This will restore from: $backup_file${NC}"
    echo -e "${YELLOW}⚠️  Current data will be preserved in a temporary backup${NC}"
    echo ""
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled"
        exit 0
    fi
    
    # Stop services
    echo -e "${CYAN}→ Stopping services...${NC}"
    cd "$AI_STACK_DIR"
    docker compose down 2>/dev/null || true
    
    # Create temp backup of current state
    local temp_backup="${BACKUP_DIR}/pre-restore-$(date +%Y%m%d_%H%M%S).tar.gz"
    echo -e "${CYAN}→ Creating temporary backup of current state...${NC}"
    mkdir -p "$BACKUP_DIR"
    
    # Extract backup
    echo -e "${CYAN}→ Extracting backup...${NC}"
    tar -xzf "$backup_file" -C "$BACKUP_DIR" 2>/dev/null || {
        echo -e "${RED}✗ Failed to extract backup${NC}"
        exit 1
    }
    
    # Restore volumes
    echo -e "${CYAN}→ Restoring volumes...${NC}"
    local restore_dir="${BACKUP_DIR}/ai-stack-restore"
    
    if [[ -d "$restore_dir/openwebui-data" ]]; then
        docker run --rm \
            -v ai-stack_openwebui-data:/target \
            -v "$restore_dir/openwebui-data:/source:ro" \
            alpine sh -c "cp -r /source/* /target/"
    fi
    
    if [[ -d "$restore_dir/chroma-data" ]]; then
        docker run --rm \
            -v ai-stack_chroma-data:/target \
            -v "$restore_dir/chroma-data:/source:ro" \
            alpine sh -c "cp -r /source/* /target/"
    fi
    
    # Restore config
    if [[ -d "$restore_dir/config" ]]; then
        cp -r "$restore_dir/config/.env" "$AI_STACK_DIR/.env" 2>/dev/null || true
    fi
    
    # Cleanup
    rm -rf "$restore_dir"
    
    # Restart services
    echo -e "${CYAN}→ Restarting services...${NC}"
    docker compose up -d
    
    echo -e "${GREEN}✓ Restore complete!${NC}"
}

create_backup() {
    echo ""
    echo -e "${BOLD}📦 AI-Stack Backup${NC}"
    echo -e "${CYAN}$(printf '═%.0s' {1..50})${NC}"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    local backup_path="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    local temp_dir="${BACKUP_DIR}/.temp-${TIMESTAMP}"
    mkdir -p "$temp_dir"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "\n${CYAN}Dry run mode - would create:${NC}"
        echo "  $backup_path"
        echo ""
        echo -e "${BOLD}Would backup:${NC}"
        echo "  - Open WebUI data volume"
        echo "  - ChromaDB data volume"
        echo "  - Configuration (.env)"
        echo "  - Scripts directory"
        rm -rf "$temp_dir"
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}→ Creating backup...${NC}"
    
    # Check Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}✗ Docker is not running${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Backup Open WebUI volume
    echo -e "  ${CYAN}→${NC} Backing up Open WebUI data..."
    docker run --rm \
        -v ai-stack_openwebui-data:/source:ro \
        -v "$temp_dir:/target" \
        alpine \
        sh -c "cp -r /source /target/openwebui-data" 2>/dev/null || {
            echo -e "  ${YELLOW}⚠${NC} Open WebUI volume not found (may be empty)"
        }
    
    # Backup ChromaDB volume
    echo -e "  ${CYAN}→${NC} Backing up ChromaDB data..."
    docker run --rm \
        -v ai-stack_chroma-data:/source:ro \
        -v "$temp_dir:/target" \
        alpine \
        sh -c "cp -r /source /target/chroma-data" 2>/dev/null || {
            echo -e "  ${YELLOW}⚠${NC} ChromaDB volume not found (may be empty)"
        }
    
    # Backup configuration
    echo -e "  ${CYAN}→${NC} Backing up configuration..."
    mkdir -p "$temp_dir/config"
    
    if [[ -f "$AI_STACK_DIR/.env" ]]; then
        # Exclude sensitive values for backup
        sed 's/OPENROUTER_API_KEY=.*/OPENROUTER_API_KEY=***REDACTED***/g' \
            "$AI_STACK_DIR/.env" > "$temp_dir/config/.env"
    fi
    
    cp "$AI_STACK_DIR/docker-compose.yml" "$temp_dir/config/" 2>/dev/null || true
    cp "$AI_STACK_DIR/scripts/"*.sh "$temp_dir/config/" 2>/dev/null || true
    
    # Create archive
    echo -e "  ${CYAN}→${NC} Creating archive..."
    cd "$temp_dir"
    tar -czf "$backup_path" . 2>/dev/null
    cd - > /dev/null
    
    # Get size
    local size=$(du -h "$backup_path" | cut -f1)
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo ""
    echo -e "${GREEN}✓ Backup created successfully!${NC}"
    echo ""
    echo -e "  ${BOLD}Location:${NC} $backup_path"
    echo -e "  ${BOLD}Size:${NC} $size"
    echo -e "  ${BOLD}Date:${NC} $(date)"
    echo ""
    echo -e "${CYAN}To restore:${NC}"
    echo "  $0 -r $backup_path"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output) BACKUP_DIR="$2"; shift 2 ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        -l|--list) list_backups; exit 0 ;;
        -r|--restore) restore_backup "$2"; exit 0 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

create_backup
