#!/bin/bash
# =============================================================
#  pterodactyl-scripts — ssl-renew/config.sh
# =============================================================

# Web server to stop/start during renewal
# Options: nginx, apache, standalone, none
WEBSERVER="nginx"

# Restart Wings after successful renewal? (true/false)
RESTART_WINGS=true

# Log file path
LOG_FILE="/var/log/pterodactyl-ssl-renew.log"

# ── NOTIFICATIONS ─────────────────────────────────────────────
NOTIFY_ENABLED=false
DISCORD_WEBHOOK_URL=""
