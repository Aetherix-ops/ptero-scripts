# stats-reporter

Fetch Pterodactyl server stats and send a formatted report to a Discord webhook.
Shows server status, RAM usage, CPU usage, and disk usage for all servers.

---

## Requirements

- Python 3.8+
- No external packages required (uses standard library only)
- Pterodactyl Client API key
- Discord webhook URL

---

## Configuration

Edit config.py:

Option              | Description                              | Default
--------------------|------------------------------------------|---------------------------
PANEL_URL           | Pterodactyl panel URL                    | https://panel.yourdomain.com
API_KEY             | Client API key from account settings     | (empty)
DISCORD_WEBHOOK_URL | Discord webhook URL                      | (empty)
REPORT_TITLE        | Title shown in Discord embed             | Pterodactyl Server Stats
SHOW_OFFLINE_SERVERS| Include offline servers in report        | True
RAM_WARN_PERCENT    | RAM warning threshold (shows warning)    | 85
CPU_WARN_PERCENT    | CPU warning threshold (shows warning)    | 80

To get your API key:
1. Open Pterodactyl Panel
2. Go to Account -> API Credentials
3. Create a new API key

---

## Usage

    # Send stats report to Discord
    python3 stats_reporter.py

    # Test Discord webhook connection
    python3 stats_reporter.py --test

    # Print stats to console only (no Discord)
    python3 stats_reporter.py --console

---

## Cron Job

Send report every hour:

    0 * * * * /usr/bin/python3 /opt/ptero-scripts/stats-reporter/stats_reporter.py >> /var/log/ptero-stats.log 2>&1

Send report every day at 8 AM:

    0 8 * * * /usr/bin/python3 /opt/ptero-scripts/stats-reporter/stats_reporter.py >> /var/log/ptero-stats.log 2>&1

---

## Discord Output

The report is sent as a Discord embed with:
- Server name and status icon
- RAM usage bar and amount
- CPU usage bar and percentage
- Disk usage
- Node name
- Warning icons when RAM or CPU exceeds threshold
- Summary (total, online, offline count)
