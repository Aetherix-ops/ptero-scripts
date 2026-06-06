#!/bin/bash
# =============================================================
#  pterodactyl-scripts — mass-restart/config.sh
# =============================================================

# Your Pterodactyl panel URL (no trailing slash)
PANEL_URL="https://panel.yourdomain.com"

# Pterodactyl API key (Admin API key from panel settings)
API_KEY="your_api_key_here"

# Delay in seconds between each server restart
# Recommended: 5-10 to avoid overloading the node
RESTART_DELAY=5

# Log file path
LOG_FILE="/var/log/pterodactyl-mass-restart.log"
