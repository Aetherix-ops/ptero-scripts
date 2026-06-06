#!/bin/bash
# =============================================================
#  pterodactyl-backup — config.sh
#  Edit this file before running backup.sh
# =============================================================

# Path to Pterodactyl server volumes
PTERODACTYL_DIR="/var/lib/pterodactyl/volumes"

# Path where backups will be saved
BACKUP_DIR="/var/backups/pterodactyl"

# How many days to keep backups (older ones will be deleted)
RETENTION_DAYS=7

# Compress backups using gzip (true/false)
COMPRESS=true

# Log file path
LOG_FILE="/var/log/pterodactyl-backup.log"

# ── REMOTE BACKUP (optional) ──────────────────────────────────
# Set REMOTE_ENABLED=true to also send backups to a remote server
REMOTE_ENABLED=false
REMOTE_USER="root"
REMOTE_HOST="your.remote.server"
REMOTE_PORT="22"
REMOTE_DIR="/var/backups/pterodactyl"
# SSH key path (leave empty to use password)
REMOTE_SSH_KEY=""

# ── NOTIFICATIONS (optional) ─────────────────────────────────
# Set NOTIFY_ENABLED=true to send a Discord webhook notification
NOTIFY_ENABLED=false
DISCORD_WEBHOOK_URL=""
