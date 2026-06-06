#!/bin/bash
# =============================================================
#  pterodactyl-scripts — cleanup/config.sh
# =============================================================

# Path to Pterodactyl server volumes
PTERODACTYL_DIR="/var/lib/pterodactyl/volumes"

# Delete log/temp files older than this many days
LOG_AGE_DAYS=7

# Log file path
LOG_FILE="/var/log/pterodactyl-cleanup.log"
