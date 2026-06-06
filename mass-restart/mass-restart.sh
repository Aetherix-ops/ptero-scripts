#!/bin/bash
# =============================================================
#  pterodactyl-scripts — mass-restart/mass-restart.sh
#  Restart all or filtered Pterodactyl servers via API
#
#  Usage:
#    bash mass-restart.sh              - restart all servers
#    bash mass-restart.sh --dry-run    - preview only
#    bash mass-restart.sh --delay 10   - 10s delay between restarts
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

check_requirements() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            log "${RED}[ERR] Required command not found: $cmd${RESET}"
            exit 1
        fi
    done

    if [ -z "$PANEL_URL" ] || [ -z "$API_KEY" ]; then
        log "${RED}[ERR] PANEL_URL and API_KEY must be set in config.sh${RESET}"
        exit 1
    fi
}

# ── API CALLS ─────────────────────────────────────────────────
api_get() {
    local endpoint="$1"
    curl -s -X GET \
        "$PANEL_URL/api/application/$endpoint" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json"
}

api_post_client() {
    local endpoint="$1"
    local data="$2"
    curl -s -X POST \
        "$PANEL_URL/api/client/$endpoint" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$data"
}

get_all_servers() {
    local response
    response=$(api_get "servers?per_page=100")
    echo "$response" | jq -r '.data[].attributes | "\(.identifier)|\(.name)|\(.status)"' 2>/dev/null
}

restart_server() {
    local identifier="$1"
    local name="$2"

    local response
    response=$(api_post_client "servers/$identifier/power" '{"signal":"restart"}')

    if echo "$response" | grep -q "error" 2>/dev/null; then
        log "${RED}[ERR] Failed to restart: $name ($identifier)${RESET}"
        return 1
    else
        log "${GREEN}[OK] Restarted: $name ($identifier)${RESET}"
        return 0
    fi
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    local dry_run=false
    local delay=$RESTART_DELAY

    for arg in "$@"; do
        case $arg in
            --dry-run) dry_run=true ;;
            --delay) shift; delay="$1" ;;
        esac
    done

    check_requirements
    mkdir -p "$(dirname "$LOG_FILE")"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Mass Restart                          ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY RUN] No servers will be restarted. Use without --dry-run to apply.${RESET}"
        echo ""
    fi

    log "Fetching server list from $PANEL_URL"

    local servers
    servers=$(get_all_servers)

    if [ -z "$servers" ]; then
        log "${RED}[ERR] No servers found or API call failed. Check PANEL_URL and API_KEY.${RESET}"
        exit 1
    fi

    local total=0 success=0 failed=0

    while IFS='|' read -r identifier name status; do
        total=$((total + 1))

        if [ "$dry_run" = true ]; then
            echo -e "  ${DIM}[DRY RUN]${RESET} Would restart: ${WHITE}$name${RESET} ($identifier)"
        else
            if restart_server "$identifier" "$name"; then
                success=$((success + 1))
            else
                failed=$((failed + 1))
            fi

            if [ "$delay" -gt 0 ] && [ "$total" -lt "$(echo "$servers" | wc -l)" ]; then
                log "${DIM}Waiting ${delay}s before next restart...${RESET}"
                sleep "$delay"
            fi
        fi
    done <<< "$servers"

    echo ""
    echo -e "${WHITE}Summary${RESET}"
    echo -e "  Total   : ${WHITE}$total${RESET}"

    if [ "$dry_run" = false ]; then
        echo -e "  Success : ${GREEN}$success${RESET}"
        echo -e "  Failed  : ${RED}$failed${RESET}"
        log "Mass restart complete — Total: $total | OK: $success | Failed: $failed"
    fi
    echo ""
}

main "$@"
