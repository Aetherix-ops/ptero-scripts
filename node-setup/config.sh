#!/bin/bash
# =============================================================
#  pterodactyl-scripts — node-setup/config.sh
# =============================================================

# System architecture (amd64 or arm64)
ARCH="amd64"

# SSH port
SSH_PORT=22

# Pterodactyl Wings port
WINGS_PORT=8080

# Pterodactyl SFTP port
SFTP_PORT=2022

# Game server port range
GAME_PORT_START=25500
GAME_PORT_END=25600

# Setup swap space? (true/false)
SETUP_SWAP=true

# Swap size in GB
SWAP_SIZE=2

# Log file
LOG_FILE="/var/log/pterodactyl-node-setup.log"
