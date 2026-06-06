#!/bin/bash
# =============================================================
#  pterodactyl-scripts — node-setup/node-setup.sh
#  Full setup for a new Pterodactyl Wings node from scratch
#  Includes: dependencies, Docker, UFW, Wings, swap
#
#  Usage:
#    bash node-setup.sh
#
#  Supported OS:
#    Ubuntu 20.04, 22.04, 24.04
#    Debian 11, 12
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'

log()     { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
success() { log "${GREEN}[OK] $1${RESET}"; }
warn()    { log "${YELLOW}[WARN] $1${RESET}"; }
error()   { log "${RED}[ERR] $1${RESET}"; exit 1; }
step()    { echo -e "\n${CYAN}══ $1 ════════════════════════════════════${RESET}\n"; }

check_root() {
    [ "$EUID" -ne 0 ] && error "This script must be run as root."
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID; OS_VERSION=$VERSION_ID
    else
        error "Cannot detect OS."
    fi
    case "$OS" in
        ubuntu)
            case "$OS_VERSION" in
                20.04|22.04|24.04) success "OS: Ubuntu $OS_VERSION" ;;
                *) warn "Ubuntu $OS_VERSION not officially tested." ;;
            esac ;;
        debian)
            case "$OS_VERSION" in
                11|12) success "OS: Debian $OS_VERSION" ;;
                *) warn "Debian $OS_VERSION not officially tested." ;;
            esac ;;
        *) error "Unsupported OS: $OS" ;;
    esac
}

# ── STEP 1: System update ──────────────────────────────────────
system_update() {
    step "Step 1/7 — System Update"
    apt update -qq && apt upgrade -y -qq
    success "System updated"
}

# ── STEP 2: Dependencies ───────────────────────────────────────
install_dependencies() {
    step "Step 2/7 — Installing Dependencies"
    apt install -y \
        curl wget tar unzip git htop \
        ca-certificates gnupg lsb-release \
        apt-transport-https software-properties-common \
        fail2ban ufw
    success "Dependencies installed"
}

# ── STEP 3: Docker ─────────────────────────────────────────────
install_docker() {
    step "Step 3/7 — Installing Docker"
    if command -v docker &> /dev/null; then
        warn "Docker already installed: $(docker --version)"
    else
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
        success "Docker installed: $(docker --version)"
    fi
}

# ── STEP 4: UFW Firewall ───────────────────────────────────────
setup_firewall() {
    step "Step 4/7 — Configuring Firewall (UFW)"

    ufw --force reset > /dev/null 2>&1
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1

    ufw allow "$SSH_PORT/tcp" comment "SSH" > /dev/null 2>&1
    ufw allow 80/tcp comment "HTTP" > /dev/null 2>&1
    ufw allow 443/tcp comment "HTTPS" > /dev/null 2>&1
    ufw allow "$WINGS_PORT/tcp" comment "Wings" > /dev/null 2>&1
    ufw allow "$SFTP_PORT/tcp" comment "SFTP" > /dev/null 2>&1
    ufw allow "$GAME_PORT_START:$GAME_PORT_END/tcp" comment "Game TCP" > /dev/null 2>&1
    ufw allow "$GAME_PORT_START:$GAME_PORT_END/udp" comment "Game UDP" > /dev/null 2>&1

    ufw --force enable > /dev/null 2>&1
    success "Firewall configured"
    log "  Allowed: SSH($SSH_PORT), HTTP(80), HTTPS(443), Wings($WINGS_PORT), SFTP($SFTP_PORT), Games($GAME_PORT_START-$GAME_PORT_END)"
}

# ── STEP 5: Wings ─────────────────────────────────────────────
install_wings() {
    step "Step 5/7 — Installing Pterodactyl Wings"

    mkdir -p /etc/pterodactyl /var/lib/pterodactyl/volumes

    curl -L -o /usr/local/bin/wings \
        "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
    chmod +x /usr/local/bin/wings

    cat > /etc/systemd/system/wings.service << 'SVCEOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service network.target
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable wings
    success "Wings installed and service created"
}

# ── STEP 6: Swap ──────────────────────────────────────────────
configure_swap() {
    step "Step 6/7 — Configuring Swap"

    if [ "$SETUP_SWAP" != true ]; then
        warn "Swap setup skipped (SETUP_SWAP=false)"
        return
    fi

    if swapon --show | grep -q "/swapfile"; then
        warn "Swap already configured."
        return
    fi

    fallocate -l "${SWAP_SIZE}G" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile > /dev/null
    swapon /swapfile
    echo "/swapfile none swap sw 0 0" >> /etc/fstab

    # Tune swappiness
    sysctl vm.swappiness=10 > /dev/null
    echo "vm.swappiness=10" >> /etc/sysctl.conf

    success "Swap configured: ${SWAP_SIZE}GB (swappiness=10)"
}

# ── STEP 7: Fail2ban ──────────────────────────────────────────
setup_fail2ban() {
    step "Step 7/7 — Configuring Fail2ban"

    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port    = $SSH_PORT
EOF

    systemctl enable --now fail2ban > /dev/null 2>&1
    success "Fail2ban configured (SSH brute-force protection)"
}

# ── SUMMARY ───────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Node Setup Complete!                              ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${WHITE}What was installed:${RESET}"
    echo -e "  ${GREEN}✔${RESET} System updated"
    echo -e "  ${GREEN}✔${RESET} Docker $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
    echo -e "  ${GREEN}✔${RESET} Pterodactyl Wings (latest)"
    echo -e "  ${GREEN}✔${RESET} UFW firewall rules"
    echo -e "  ${GREEN}✔${RESET} Fail2ban (SSH protection)"
    [ "$SETUP_SWAP" = true ] && echo -e "  ${GREEN}✔${RESET} Swap ${SWAP_SIZE}GB"
    echo ""
    echo -e "${WHITE}Next steps:${RESET}"
    echo -e "  1. Pterodactyl Admin Panel -> Nodes -> Create Node"
    echo -e "  2. Copy config to: ${CYAN}nano /etc/pterodactyl/config.yml${RESET}"
    echo -e "  3. Start Wings: ${CYAN}systemctl start wings${RESET}"
    echo -e "  4. Verify: ${CYAN}systemctl status wings${RESET}"
    echo ""
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Node Setup                            ║${RESET}"
    echo -e "${CYAN}║        Full installation from scratch                    ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    check_root
    check_os
    system_update
    install_dependencies
    install_docker
    setup_firewall
    install_wings
    configure_swap
    setup_fail2ban

    log "Node setup complete"
    print_summary
}

main "$@"
