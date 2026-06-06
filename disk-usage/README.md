# disk-usage

Show a disk usage report for all Pterodactyl server volumes, sorted from largest to smallest.
Color-coded output with configurable warning and critical thresholds.

---

## Usage

    # Show all servers sorted by disk usage
    bash disk-usage.sh

    # Show only top 10 largest servers
    bash disk-usage.sh --top 10

    # Show only servers above warning threshold
    bash disk-usage.sh --warn

    # Output as JSON
    bash disk-usage.sh --json

---

## Output Example

    SERVER UUID                              DISK USAGE     FILES
    ──────────────────────────────────────────────────────
    1a2b3c4d-xxxx-xxxx-xxxx-xxxxxxxxxxxx     12.50GB        8420
    5e6f7a8b-xxxx-xxxx-xxxx-xxxxxxxxxxxx     4.20GB         1205
    9c0d1e2f-xxxx-xxxx-xxxx-xxxxxxxxxxxx     320.00MB       88
    ──────────────────────────────────────────────────────

    Summary
      Servers shown  : 3
      Total (volumes): 17.02GB

    Host Disk
      Total          : 200.00GB
      Used           : 85.10GB (43%)
      Free           : 114.90GB

    Legend: Normal | Warning (>5GB) | Critical (>10GB)

---

## Configuration

Edit config.sh:

Option              | Description                        | Default
--------------------|------------------------------------|--------
PTERODACTYL_DIR     | Path to Pterodactyl server volumes | /var/lib/pterodactyl/volumes
WARN_THRESHOLD_GB   | Warning threshold in GB (yellow)   | 5
CRIT_THRESHOLD_GB   | Critical threshold in GB (red)     | 10
