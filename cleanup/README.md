# cleanup

Clean up old logs, temporary files, and cache from all Pterodactyl server volumes.
Supports dry run mode to preview what will be deleted before actually removing anything.

---

## Usage

    # Dry run - preview only, nothing deleted
    bash cleanup.sh

    # Actually delete files
    bash cleanup.sh --run

    # Clean a specific server
    bash cleanup.sh --run <server-uuid>

---

## What Gets Cleaned

- *.log and rotated log files (*.log.1, *.log.2, etc.)
- logs/ directory log files
- *.tmp and *.temp files
- cache/ and .cache directories
- tmp/ directories
- crash-reports/
- debug/ directories
- *.old and *.bak files

Only files older than LOG_AGE_DAYS (default: 7 days) are removed.

---

## Output Example

    [DRY RUN] No files will be deleted. Use --run to actually clean.

    [2026-06-06 10:00:01] Starting cleanup (dry_run=true, log_age=7d)
    [2026-06-06 10:00:02] [INFO] 1a2b3c4d... - 12 files, 45MB
    [2026-06-06 10:00:02] [INFO] 5e6f7a8b... - 3 files, 8MB

    Summary
      Servers cleaned : 2
      Files found     : 15
      Space to free   : 53MB

    Run with --run to apply cleanup.

---

## Configuration

Edit config.sh:

Option          | Description                              | Default
----------------|------------------------------------------|----------------------------------
PTERODACTYL_DIR | Path to Pterodactyl server volumes       | /var/lib/pterodactyl/volumes
LOG_AGE_DAYS    | Only delete files older than N days      | 7
LOG_FILE        | Path to log file                         | /var/log/pterodactyl-cleanup.log

---

## Cron Job

Run every Sunday at 3 AM:

    0 3 * * 0 /bin/bash /opt/ptero-scripts/cleanup/cleanup.sh --run >> /var/log/pterodactyl-cleanup.log 2>&1
