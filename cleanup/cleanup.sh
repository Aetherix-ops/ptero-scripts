#!/bin/bash
# =============================================================
#  pterodactyl-scripts — cleanup/cleanup.sh
#  Clean up old logs, temp files, and cache from server volumes
#
#  Usage:
#    bash cleanup.sh              - dry run (preview only)
#    bash cleanup.sh --run        - actually delete files
#    bash cleanup.sh --run <uuid> - clean specific server
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ── COLORS ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

# ── HELPERS ───────────────────────────────────────────────────
log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1073741824}")GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")KB"
    else
        echo "${bytes}B"
    fi
}

# ── CLEANUP ───────────────────────────────────────────────────
cleanup_server() {
    local server_path="$1"
    local dry_run="$2"
    local uuid
    uuid=$(basename "$server_path")
    local freed=0
    local count=0

    # Patterns to clean
    local patterns=(
        "*.log"
        "*.log.*"
        "logs/*.log"
        "logs/*.log.*"
        "*.tmp"
        "*.temp"
        ".cache"
        "cache/*"
        "tmp/*"
        "crash-reports/*"
        "debug/*"
        "*.old"
        "*.bak"
    )

    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d '' file; do
            local size
            size=$(stat -c%s "$file" 2>/dev/null || echo 0)
            freed=$((freed + size))
            count=$((count + 1))

            if [ "$dry_run" = false ]; then
                rm -f "$file" 2>/dev/null
            fi
        done < <(find "$server_path" -name "$pattern" -type f -mtime +$LOG_AGE_DAYS -print0 2>/dev/null)
    done

    # Clean empty directories (not dry run only)
    if [ "$dry_run" = false ]; then
        find "$server_path" -type d -empty -not -path "$server_path" -delete 2>/dev/null
    fi

    echo "$count|$freed"
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    local dry_run=true
    local target_server=""

    # Parse args
    for arg in "$@"; do
        case $arg in
            --run) dry_run=false ;;
            --*) ;;
            *) target_server="$arg" ;;
        esac
    done

    if [ ! -d "$PTERODACTYL_DIR" ]; then
        log "${RED}[ERR] Pterodactyl volumes directory not found: $PTERODACTYL_DIR${RESET}"
        exit 1
    fi

    mkdir -p "$(dirname "$LOG_FILE")"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Cleanup                               ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY RUN] No files will be deleted. Use --run to actually clean.${RESET}"
        echo ""
    fi

    log "Starting cleanup (dry_run=$dry_run, log_age=${LOG_AGE_DAYS}d)"

    local total_count=0
    local total_freed=0
    local servers_cleaned=0

    if [ -n "$target_server" ]; then
        local server_path="$PTERODACTYL_DIR/$target_server"
        if [ ! -d "$server_path" ]; then
            log "${RED}[ERR] Server not found: $target_server${RESET}"
            exit 1
        fi
        local result
        result=$(cleanup_server "$server_path" "$dry_run")
        IFS='|' read -r count freed <<< "$result"
        log "[INFO] $target_server — $count files, $(bytes_to_human $freed) freed"
        total_count=$count
        total_freed=$freed
        servers_cleaned=1
    else
        for server_dir in "$PTERODACTYL_DIR"/*/; do
            if [ -d "$server_dir" ]; then
                local uuid
                uuid=$(basename "$server_dir")
                local result
                result=$(cleanup_server "$server_dir" "$dry_run")
                IFS='|' read -r count freed <<< "$result"

                if [ "$count" -gt 0 ]; then
                    log "[INFO] $uuid — $count files, $(bytes_to_human $freed)"
                    servers_cleaned=$((servers_cleaned + 1))
                fi

                total_count=$((total_count + count))
                total_freed=$((total_freed + freed))
            fi
        done
    fi

    echo ""
    echo -e "${WHITE}Summary${RESET}"
    echo -e "  Servers cleaned : ${CYAN}$servers_cleaned${RESET}"
    echo -e "  Files found     : ${YELLOW}$total_count${RESET}"

    if [ "$dry_run" = true ]; then
        echo -e "  Space to free   : ${YELLOW}$(bytes_to_human $total_freed)${RESET}"
        echo ""
        echo -e "${YELLOW}Run with --run to apply cleanup.${RESET}"
    else
        echo -e "  Space freed     : ${GREEN}$(bytes_to_human $total_freed)${RESET}"
        log "Cleanup complete — $total_count files removed, $(bytes_to_human $total_freed) freed"
    fi
    echo ""
}

main "$@"
