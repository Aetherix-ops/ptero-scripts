#!/bin/bash
# =============================================================
#  pterodactyl-scripts — firewall/config.sh
# =============================================================

# SSH port (default: 22)
SSH_PORT=22

# Is Pterodactyl Panel installed on this node? (true/false)
PANEL_ON_THIS_NODE=true

# Pterodactyl Panel port (default: 443 if using SSL)
PANEL_PORT=443

# Pterodactyl Wings port (default: 8080)
WINGS_PORT=8080

# Pterodactyl SFTP port (default: 2022)
SFTP_PORT=2022

# Game server port range
GAME_PORT_START=25500
GAME_PORT_END=25600

# Extra ports to allow (space separated, e.g. "3306 6379 27017")
EXTRA_PORTS=""

# Log file path
LOG_FILE="/var/log/pterodactyl-firewall.log"
