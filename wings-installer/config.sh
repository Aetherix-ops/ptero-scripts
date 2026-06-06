#!/bin/bash
# =============================================================
#  pterodactyl-scripts — wings-installer/config.sh
# =============================================================

# System architecture (amd64 or arm64)
ARCH="amd64"

# Wings data directory
WINGS_DATA_DIR="/var/lib/pterodactyl"

# Setup swap space? (true/false)
SETUP_SWAP=true

# Swap size in GB
SWAP_SIZE=2

# Log file
LOG_FILE="/var/log/pterodactyl-wings-install.log"
