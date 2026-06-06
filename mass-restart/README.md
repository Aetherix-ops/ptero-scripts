# mass-restart

Restart all Pterodactyl servers at once via the Pterodactyl API.
Supports dry run mode, configurable delay between restarts, and detailed logging.

---

## Requirements

- curl
- jq
- Pterodactyl Admin API key

---

## Configuration

Edit config.sh:

    nano config.sh

Option          | Description                              | Default
----------------|------------------------------------------|----------------------------------
PANEL_URL       | Your Pterodactyl panel URL               | https://panel.yourdomain.com
API_KEY         | Admin API key from panel settings        | (empty)
RESTART_DELAY   | Seconds to wait between each restart     | 5
LOG_FILE        | Path to log file                         | /var/log/pterodactyl-mass-restart.log

To get your API key:
1. Open Pterodactyl Admin Panel
2. Go to Settings -> API
3. Create a new Application API key

---

## Usage

    # Dry run - preview which servers will be restarted
    bash mass-restart.sh --dry-run

    # Restart all servers
    bash mass-restart.sh

    # Restart all servers with 10 second delay between each
    bash mass-restart.sh --delay 10

---

## Output Example

    [2026-06-06 10:00:01] Fetching server list from https://panel.yourdomain.com
    [2026-06-06 10:00:02] [OK] Restarted: TelisSMP (a1b2c3d4)
    [2026-06-06 10:00:07] [OK] Restarted: Lunexia Bot (e5f6g7h8)
    [2026-06-06 10:00:12] [OK] Restarted: Dev API (i9j0k1l2)

    Summary
      Total   : 3
      Success : 3
      Failed  : 0
