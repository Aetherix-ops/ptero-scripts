#!/bin/bash
# =============================================================
#  pterodactyl-scripts — firewall/firewall-setup.sh
#  Setup UFW firewall rules for Pterodactyl Panel + Wings
#
#  Usage:
#    bash firewall-setup.sh           - setup firewall rules
#    bash firewall-setup.sh --status  - show current rules
#    bash firewall-setup.sh --reset   - reset all rules
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

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERR] This script must be run as root.${RESET}"
        exit 1
    fi
}

check_ufw() {
    if ! command -v ufw &> /dev/null; then
        log "${YELLOW}[INFO] UFW not found. Installing...${RESET}"
        apt update -qq && apt install -y ufw
    fi
}

# ── STATUS ────────────────────────────────────────────────────
show_status() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        UFW Firewall Status                               ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    ufw status verbose
    echo ""
}

# ── RESET ─────────────────────────────────────────────────────
reset_rules() {
    echo ""
    echo -e "${YELLOW}[WARN] This will reset ALL firewall rules.${RESET}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        ufw --force reset
        log "${GREEN}[OK] Firewall rules reset${RESET}"
    else
        echo "Cancelled."
    fi
}

# ── SETUP ─────────────────────────────────────────────────────
setup_firewall() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Firewall Setup                        ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    log "Setting up UFW firewall rules for Pterodactyl"

    # Reset existing rules
    ufw --force reset > /dev/null 2>&1

    # Default policies
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    log "${GREEN}[OK] Default policies set (deny incoming, allow outgoing)${RESET}"

    # SSH
    ufw allow "$SSH_PORT/tcp" comment "SSH" > /dev/null 2>&1
    log "${GREEN}[OK] SSH allowed on port $SSH_PORT${RESET}"

    # HTTP & HTTPS
    ufw allow 80/tcp comment "HTTP" > /dev/null 2>&1
    ufw allow 443/tcp comment "HTTPS" > /dev/null 2>&1
    log "${GREEN}[OK] HTTP/HTTPS allowed (80, 443)${RESET}"

    # Pterodactyl Panel (if on same node)
    if [ "$PANEL_ON_THIS_NODE" = true ]; then
        ufw allow "$PANEL_PORT/tcp" comment "Pterodactyl Panel" > /dev/null 2>&1
        log "${GREEN}[OK] Panel port allowed: $PANEL_PORT${RESET}"
    fi

    # Wings daemon
    ufw allow "$WINGS_PORT/tcp" comment "Pterodactyl Wings" > /dev/null 2>&1
    log "${GREEN}[OK] Wings port allowed: $WINGS_PORT${RESET}"

    # SFTP
    ufw allow "$SFTP_PORT/tcp" comment "Pterodactyl SFTP" > /dev/null 2>&1
    log "${GREEN}[OK] SFTP port allowed: $SFTP_PORT${RESET}"

    # Game server port range
    ufw allow "$GAME_PORT_START:$GAME_PORT_END/tcp" comment "Game Servers TCP" > /dev/null 2>&1
    ufw allow "$GAME_PORT_START:$GAME_PORT_END/udp" comment "Game Servers UDP" > /dev/null 2>&1
    log "${GREEN}[OK] Game server ports allowed: $GAME_PORT_START-$GAME_PORT_END (TCP+UDP)${RESET}"

    # Extra ports from config
    if [ -n "$EXTRA_PORTS" ]; then
        for port in $EXTRA_PORTS; do
            ufw allow "$port" comment "Custom" > /dev/null 2>&1
            log "${GREEN}[OK] Extra port allowed: $port${RESET}"
        done
    fi

    # Enable UFW
    ufw --force enable > /dev/null 2>&1
    log "${GREEN}[OK] UFW enabled${RESET}"

    echo ""
    echo -e "${GREEN}Firewall setup complete!${RESET}"
    echo ""
    ufw status numbered
    echo ""
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    check_root
    check_ufw
    mkdir -p "$(dirname "$LOG_FILE")"

    case "$1" in
        --status) show_status ;;
        --reset)  reset_rules ;;
        *)        setup_firewall ;;
    esac
}

main "$@"
