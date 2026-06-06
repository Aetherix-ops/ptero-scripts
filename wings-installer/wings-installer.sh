#!/bin/bash
# =============================================================
#  pterodactyl-scripts — wings-installer/wings-installer.sh
#  Auto-install Pterodactyl Wings on a new node
#
#  Usage:
#    bash wings-installer.sh
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
step()    { echo -e "\n${CYAN}── $1 ────────────────────────────────────${RESET}"; }

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
                *) warn "Ubuntu $OS_VERSION is not officially tested." ;;
            esac ;;
        debian)
            case "$OS_VERSION" in
                11|12) success "OS: Debian $OS_VERSION" ;;
                *) warn "Debian $OS_VERSION is not officially tested." ;;
            esac ;;
        *) error "Unsupported OS: $OS. Only Ubuntu and Debian supported." ;;
    esac
}

install_dependencies() {
    step "Installing dependencies"
    apt update -qq
    apt install -y curl wget tar unzip git ca-certificates gnupg \
        lsb-release apt-transport-https software-properties-common
    success "Dependencies installed"
}

install_docker() {
    step "Installing Docker"
    if command -v docker &> /dev/null; then
        warn "Docker already installed: $(docker --version)"
        return
    fi
    curl -fsSL https://get.docker.com | bash
    systemctl enable --now docker
    success "Docker installed: $(docker --version)"
}

install_wings() {
    step "Installing Pterodactyl Wings"
    mkdir -p /etc/pterodactyl "$WINGS_DATA_DIR"
    curl -L -o /usr/local/bin/wings \
        "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
    chmod +x /usr/local/bin/wings
    success "Wings binary installed"
}

create_service() {
    step "Creating Wings systemd service"
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
    success "Wings service created and enabled"
}

configure_swap() {
    [ "$SETUP_SWAP" != true ] && return
    step "Configuring swap"
    if swapon --show | grep -q "/swapfile"; then
        warn "Swap already configured."; return
    fi
    fallocate -l "${SWAP_SIZE}G" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    success "Swap configured: ${SWAP_SIZE}GB"
}

print_next_steps() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Wings Installation Complete!                      ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${WHITE}Next steps:${RESET}"
    echo -e "  1. Go to Pterodactyl Admin Panel -> Nodes -> Create Node"
    echo -e "  2. On Configuration tab, copy config to:"
    echo -e "     ${CYAN}nano /etc/pterodactyl/config.yml${RESET}"
    echo -e "  3. Start Wings:"
    echo -e "     ${CYAN}systemctl start wings${RESET}"
    echo -e "  4. Check status:"
    echo -e "     ${CYAN}systemctl status wings${RESET}"
    echo ""
}

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Wings Installer                       ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    check_root
    check_os
    install_dependencies
    install_docker
    install_wings
    create_service
    configure_swap
    log "Wings installation complete"
    print_next_steps
}

main "$@"
