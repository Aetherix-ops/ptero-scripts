# monitor

Monitor the status and disk usage of all Pterodactyl server volumes directly from the terminal.

---

## Usage

    # Show all servers
    bash monitor.sh

    # Sort by disk usage (largest first)
    bash monitor.sh --sort

    # Output as JSON
    bash monitor.sh --json

---

## Output Example

    SERVER UUID                              STATUS      DISK       FILES
    ────────────────────────────────────────────────────────────────
    1a2b3c4d...ef12                          running     245MB      1024
    5e6f7a8b...cd34                          stopped     88MB       312

    Summary
      Total servers  : 2
      Running        : 1
      Stopped        : 1
      Total disk     : 333MB

    System
      CPU load       : 0.45
      RAM usage      : 3.2GB / 8.0GB (40%)

---

## Configuration

Edit config.sh to set the correct path:

    PTERODACTYL_DIR="/var/lib/pterodactyl/volumes"
