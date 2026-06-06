# ssl-renew

Auto-renew SSL certificates via Certbot for Pterodactyl Panel and Wings.
Automatically stops and restarts your web server during renewal, and optionally restarts Wings to pick up the new certificate.

---

## Requirements

- Root access
- Certbot (auto-installed if not present)
- Existing SSL certificates issued via Certbot

---

## Configuration

Edit config.sh:

Option              | Description                              | Default
--------------------|------------------------------------------|----------
WEBSERVER           | Web server to stop during renewal        | nginx
RESTART_WINGS       | Restart Wings after renewal              | true
LOG_FILE            | Path to log file                         | /var/log/pterodactyl-ssl-renew.log
NOTIFY_ENABLED      | Enable Discord webhook notification      | false
DISCORD_WEBHOOK_URL | Discord webhook URL                      | (empty)

WEBSERVER options: nginx, apache, standalone, none

---

## Usage

    # Renew certificates (only if expiring within 30 days)
    sudo bash ssl-renew.sh

    # Show certificate expiry status
    sudo bash ssl-renew.sh --status

    # Force renew all certificates
    sudo bash ssl-renew.sh --force

---

## Cron Job

Run every day at 4 AM:

    0 4 * * * /bin/bash /opt/ptero-scripts/ssl-renew/ssl-renew.sh >> /var/log/pterodactyl-ssl-renew.log 2>&1

Certbot will only actually renew if the certificate expires within 30 days, so running daily is safe.

---

## Output Example

    [2026-06-06 04:00:01] Starting SSL certificate renewal
    [2026-06-06 04:00:01] [INFO] Stopping nginx temporarily...
    [2026-06-06 04:00:04] Congratulations, all renewals succeeded
    [2026-06-06 04:00:04] [OK] nginx restarted
    [2026-06-06 04:00:05] [OK] Wings restarted
    [2026-06-06 04:00:05] [OK] SSL renewal complete
    
