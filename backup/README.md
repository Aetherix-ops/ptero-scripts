# backup

Auto-backup script for Pterodactyl Panel server volumes.
Supports local backup, remote transfer via SCP, retention policy, logging, and Discord notifications.

---

## Requirements

- bash, tar, gzip, find
- scp and ssh (remote backup only)
- curl (Discord notification only)

---

## Configuration

Edit config.sh before running:

    nano config.sh

Option              | Description                              | Default
--------------------|------------------------------------------|----------------------------------
PTERODACTYL_DIR     | Path to Pterodactyl server volumes       | /var/lib/pterodactyl/volumes
BACKUP_DIR          | Where backups are saved                  | /var/backups/pterodactyl
RETENTION_DAYS      | Days to keep backups before deleting     | 7
COMPRESS            | Compress backups to .tar.gz              | true
LOG_FILE            | Path to log file                         | /var/log/pterodactyl-backup.log
REMOTE_ENABLED      | Enable remote backup via SCP             | false
REMOTE_HOST         | Remote server hostname or IP             | (empty)
REMOTE_USER         | Remote SSH username                      | root
REMOTE_PORT         | Remote SSH port                          | 22
REMOTE_DIR          | Remote path to save backups              | /var/backups/pterodactyl
REMOTE_SSH_KEY      | Path to SSH private key (optional)       | (empty)
NOTIFY_ENABLED      | Enable Discord webhook notification      | false
DISCORD_WEBHOOK_URL | Discord webhook URL                      | (empty)

---

## Usage

    # Backup all servers
    bash backup.sh

    # Backup a specific server by UUID
    bash backup.sh 1a2b3c4d-xxxx-xxxx-xxxx-xxxxxxxxxxxx

---

## Cron Job

Run every day at 2 AM:

    crontab -e

Add:

    0 2 * * * /bin/bash /opt/ptero-scripts/backup/backup.sh >> /var/log/pterodactyl-backup.log 2>&1

---

## Log Output Example

    [2026-06-06 02:00:01] Starting Pterodactyl backup
    [2026-06-06 02:00:01] Source : /var/lib/pterodactyl/volumes
    [2026-06-06 02:00:01] Destination : /var/backups/pterodactyl
    [2026-06-06 02:00:03] [OK] Backup created: server_abc123_20260606_020001.tar.gz (45M)
    [2026-06-06 02:00:05] [OK] Backup created: server_def456_20260606_020003.tar.gz (120M)
    [2026-06-06 02:00:05] Backup complete - Total: 2 | OK: 2 | Failed: 0
    [2026-06-06 02:00:05] [INFO] No old backups to delete

---

## Backup File Naming

    server_<uuid>_<YYYYMMDD>_<HHMMSS>.tar.gz

Example:

    server_1a2b3c4d-xxxx-xxxx-xxxx-xxxxxxxxxxxx_20260606_020001.tar.gz
    
