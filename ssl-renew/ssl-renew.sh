#!/bin/bash
# =============================================================
#  pterodactyl-scripts — ssl-renew/ssl-renew.sh
#  Auto-renew SSL certificates via Certbot for Pterodactyl
#
#  Usage:
#    bash ssl-renew.sh           - renew all certs
#    bash ssl-renew.sh --status  - show cert expiry dates
#    bash ssl-renew.sh --force   - force renew even if not expiring
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

notify_discord() {
    local message="$1"
    if [ "$NOTIFY_ENABLED" = true ] && [ -n "$DISCORD_WEBHOOK_URL" ]; then
        curl -s -X POST "$DISCORD_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" > /dev/null 2>&1
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERR] This script must be run as root.${RESET}"
        exit 1
    fi
}

check_certbot() {
    if ! command -v certbot &> /dev/null; then
        log "${YELLOW}[INFO] Certbot not found. Installing...${RESET}"
        apt update -qq && apt install -y certbot
    fi
}

# ── STATUS ────────────────────────────────────────────────────
show_status() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        SSL Certificate Status                            ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    if [ -z "$(certbot certificates 2>/dev/null)" ]; then
        echo -e "${YELLOW}No certificates found.${RESET}"
        return
    fi

    certbot certificates 2>/dev/null | while IFS= read -r line; do
        if echo "$line" | grep -q "VALID\|INVALID\|EXPIRED"; then
            if echo "$line" | grep -q "INVALID\|EXPIRED"; then
                echo -e "${RED}$line${RESET}"
            elif echo "$line" | grep -q "VALID: [0-9] day"; then
                echo -e "${YELLOW}$line${RESET}"
            else
                echo -e "${GREEN}$line${RESET}"
            fi
        else
            echo "$line"
        fi
    done
    echo ""
}

# ── RENEW ─────────────────────────────────────────────────────
renew_certs() {
    local force="$1"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        SSL Certificate Renewal                           ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    log "Starting SSL certificate renewal"

    # Stop webserver temporarily if needed
    if [ "$WEBSERVER" = "nginx" ]; then
        log "${YELLOW}[INFO] Stopping nginx temporarily...${RESET}"
        systemctl stop nginx 2>/dev/null
    elif [ "$WEBSERVER" = "apache" ]; then
        log "${YELLOW}[INFO] Stopping apache2 temporarily...${RESET}"
        systemctl stop apache2 2>/dev/null
    fi

    # Run certbot renew
    local certbot_cmd="certbot renew"
    [ "$force" = true ] && certbot_cmd="$certbot_cmd --force-renewal"
    [ "$WEBSERVER" = "standalone" ] && certbot_cmd="$certbot_cmd --standalone"

    local output
    output=$($certbot_cmd 2>&1)
    local exit_code=$?

    log "$output"

    # Restart webserver
    if [ "$WEBSERVER" = "nginx" ]; then
        systemctl start nginx 2>/dev/null
        log "${GREEN}[OK] nginx restarted${RESET}"
    elif [ "$WEBSERVER" = "apache" ]; then
        systemctl start apache2 2>/dev/null
        log "${GREEN}[OK] apache2 restarted${RESET}"
    fi

    # Restart Wings to pick up new cert
    if [ "$RESTART_WINGS" = true ]; then
        systemctl restart wings 2>/dev/null
        log "${GREEN}[OK] Wings restarted${RESET}"
    fi

    if [ $exit_code -eq 0 ]; then
        log "${GREEN}[OK] SSL renewal complete${RESET}"
        notify_discord "[ssl-renew] SSL certificates renewed successfully on $(hostname) at $(date '+%Y-%m-%d %H:%M')"
    else
        log "${RED}[ERR] SSL renewal failed${RESET}"
        notify_discord "[ssl-renew] SSL renewal FAILED on $(hostname) at $(date '+%Y-%m-%d %H:%M'). Check logs: $LOG_FILE"
    fi
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    check_root
    check_certbot
    mkdir -p "$(dirname "$LOG_FILE")"

    case "$1" in
        --status) show_status ;;
        --force)  renew_certs true ;;
        *)        renew_certs false ;;
    esac
}

main "$@"
