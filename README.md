# ptero-scripts

A collection of shell scripts for managing and automating Pterodactyl Panel on Linux servers.
All scripts are designed to run directly on the host server via terminal or cron job.

This repository is separate from ptero-eggs (https://github.com/Aetherix-ops/ptero-eggs).
- ptero-eggs  : JSON egg configurations imported into Pterodactyl Panel
- ptero-scripts : Shell scripts run on the host server by the admin

---

## Script List

Category  | Script              | Description
----------|---------------------|-------------------------------------------
Backup    | backup/backup.sh    | Auto-backup all Pterodactyl server volumes

More scripts will be added over time.

---

## Requirements

- Linux server (Ubuntu 20.04 / 22.04 / 24.04 recommended)
- Pterodactyl Panel installed
- bash, tar, gzip, find (pre-installed on most systems)
- curl (required for Discord notifications)
- scp and ssh (required for remote backup)

---

## Installation

Clone this repository to your server:

    git clone https://github.com/Aetherix-ops/ptero-scripts.git
    cd ptero-scripts

Make scripts executable:

    chmod +x backup/backup.sh

---

## Scripts

### backup — Auto Backup Server Volumes

Automatically backs up all Pterodactyl server volumes to a local or remote destination.

Features:
- Backup all servers or a specific server by UUID
- Compress backups to .tar.gz
- Auto-delete old backups based on retention policy
- Send backups to a remote server via SCP
- Discord webhook notification after backup completes
- Detailed log file

Configuration:

    nano backup/config.sh

Usage:

    # Backup all servers
    bash backup/backup.sh

    # Backup a specific server
    bash backup/backup.sh <server-uuid>

Cron job example (every day at 2 AM):

    0 2 * * * /bin/bash /opt/ptero-scripts/backup/backup.sh >> /var/log/pterodactyl-backup.log 2>&1

Full documentation: backup/README.md

---

## File Structure

    ptero-scripts/
    |- backup/
    |   |- backup.sh       - Main backup script
    |   |- config.sh       - Backup configuration
    |   |- README.md       - Backup documentation
    |- README.md           - This file

---

## Changelog

v1.0.0 - 2026-06-06
- Added backup script with local and remote support

---

## Contributing

Pull requests are welcome. If you have a useful Pterodactyl script to share:

1. Fork this repo
2. Create a branch: git checkout -b add/script-name
3. Add your script in a new folder with its own README.md
4. Commit: git commit -m "add: script-name description"
5. Open a Pull Request

---

## Related Repositories

- ptero-eggs : https://github.com/Aetherix-ops/ptero-eggs
- novastar-theme : https://github.com/Aetherix-ops/novastar-theme

---

## License

MIT License - free to use, modify, and distribute.
Credit appreciated but not required.
