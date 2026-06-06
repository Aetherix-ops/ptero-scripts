#!/bin/bash
# =============================================================
#  pterodactyl-backup — backup.sh
#  Auto-backup script for Pterodactyl Panel server volumes
#
#  Usage:
#    bash backup.sh              - backup all servers
#    bash backup.sh <server-id>  - backup a specific server
#
#  Cron example (every day at 2 AM):
#    0 2 * * * /bin/bash /opt/pterodactyl-backup/backup.sh >> /var/log/pterodactyl-backup.log 2>&1
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ── HELPERS ───────────────────────────────────────────────────

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

notify_discord() {
    local message="$1"
    if [ "$NOTIFY_ENABLED" = true ] && [ -n "$DISCORD_WEBHOOK_URL" ]; then
        curl -s -X POST "$DISCORD_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" > /dev/null 2>&1
    fi
}

check_requirements() {
    for cmd in tar gzip find; do
        if ! command -v "$cmd" &> /dev/null; then
            log "[ERR] Required command not found: $cmd"
            exit 1
        fi
    done

    if [ ! -d "$PTERODACTYL_DIR" ]; then
        log "[ERR] Pterodactyl volumes directory not found: $PTERODACTYL_DIR"
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# ── BACKUP ────────────────────────────────────────────────────

backup_server() {
    local server_id="$1"
    local server_path="$PTERODACTYL_DIR/$server_id"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="server_${server_id}_${timestamp}"

    if [ ! -d "$server_path" ]; then
        log "[WARN] Server directory not found: $server_path"
        return 1
    fi

    log "[INFO] Backing up server: $server_id"

    if [ "$COMPRESS" = true ]; then
        local output_file="$BACKUP_DIR/${backup_name}.tar.gz"
        tar -czf "$output_file" -C "$PTERODACTYL_DIR" "$server_id" 2>/dev/null
    else
        local output_file="$BACKUP_DIR/${backup_name}.tar"
        tar -cf "$output_file" -C "$PTERODACTYL_DIR" "$server_id" 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        local size
        size=$(du -sh "$output_file" | cut -f1)
        log "[OK] Backup created: $(basename $output_file) ($size)"
        echo "$output_file"
        return 0
    else
        log "[ERR] Failed to backup server: $server_id"
        return 1
    fi
}

backup_all() {
    local success=0
    local failed=0
    local total=0

    log "──────────────────────────────────────────"
    log "Starting Pterodactyl backup"
    log "Source : $PTERODACTYL_DIR"
    log "Destination : $BACKUP_DIR"
    log "Retention : $RETENTION_DAYS days"
    log "──────────────────────────────────────────"

    for server_dir in "$PTERODACTYL_DIR"/*/; do
        if [ -d "$server_dir" ]; then
            local server_id
            server_id=$(basename "$server_dir")
            total=$((total + 1))

            if backup_server "$server_id" > /dev/null; then
                success=$((success + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done

    log "──────────────────────────────────────────"
    log "Backup complete — Total: $total | OK: $success | Failed: $failed"
    log "──────────────────────────────────────────"

    notify_discord "[pterodactyl-backup] Backup complete. Total: $total | OK: $success | Failed: $failed | $(date '+%Y-%m-%d %H:%M')"
}

# ── REMOTE TRANSFER ───────────────────────────────────────────

send_remote() {
    local file="$1"
    if [ "$REMOTE_ENABLED" = true ]; then
        log "[INFO] Sending to remote: $REMOTE_HOST"

        local ssh_opts="-p $REMOTE_PORT -o StrictHostKeyChecking=no"
        [ -n "$REMOTE_SSH_KEY" ] && ssh_opts="$ssh_opts -i $REMOTE_SSH_KEY"

        ssh $ssh_opts "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR" 2>/dev/null
        scp $ssh_opts "$file" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" 2>/dev/null

        if [ $? -eq 0 ]; then
            log "[OK] Sent to remote: $(basename $file)"
        else
            log "[ERR] Failed to send to remote: $(basename $file)"
        fi
    fi
}

# ── CLEANUP ───────────────────────────────────────────────────

cleanup_old_backups() {
    log "[INFO] Cleaning up backups older than $RETENTION_DAYS days"
    local count
    count=$(find "$BACKUP_DIR" -name "*.tar.gz" -o -name "*.tar" | xargs -I {} find {} -mtime +$RETENTION_DAYS 2>/dev/null | wc -l)

    find "$BACKUP_DIR" \( -name "*.tar.gz" -o -name "*.tar" \) -mtime +$RETENTION_DAYS -delete 2>/dev/null

    if [ "$count" -gt 0 ]; then
        log "[OK] Deleted $count old backup(s)"
    else
        log "[INFO] No old backups to delete"
    fi
}

# ── MAIN ──────────────────────────────────────────────────────

main() {
    check_requirements

    if [ -n "$1" ]; then
        # Backup specific server
        log "──────────────────────────────────────────"
        log "Backing up single server: $1"
        log "──────────────────────────────────────────"
        local output
        output=$(backup_server "$1")
        if [ $? -eq 0 ] && [ "$REMOTE_ENABLED" = true ]; then
            send_remote "$output"
        fi
    else
        # Backup all servers
        backup_all

        # Send all new backups to remote if enabled
        if [ "$REMOTE_ENABLED" = true ]; then
            local today
            today=$(date '+%Y%m%d')
            for f in "$BACKUP_DIR"/server_*_${today}*.tar*; do
                [ -f "$f" ] && send_remote "$f"
            done
        fi
    fi

    cleanup_old_backups
}

main "$@"
