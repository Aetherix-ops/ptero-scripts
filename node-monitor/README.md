# node-monitor

Realtime terminal dashboard for Pterodactyl servers.
Written in Go — fast, lightweight, single binary, no dependencies.

Refreshes every 3 seconds and shows RAM, CPU, and disk usage for all servers simultaneously.

---

## Requirements

- Go 1.21+ (to build from source)
- OR download the pre-built binary (no Go needed)
- Pterodactyl Client API key

---

## Configuration

Edit config.env:

    PANEL_URL=https://panel.yourdomain.com
    API_KEY=your_api_key_here

Or set as environment variables:

    export PANEL_URL=https://panel.yourdomain.com
    export API_KEY=your_api_key_here

---

## Usage

Run with Go:

    go run monitor.go

Build and run binary:

    go build -o node-monitor monitor.go
    ./node-monitor

---

## Dashboard Preview

    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║  PTERODACTYL NODE MONITOR                                                   ║
    ║  Updated: 2026-06-06 10:00:05              Refresh: 3s  Fetch: 142ms       ║
    ╚══════════════════════════════════════════════════════════════════════════════╝

    SERVER                   STATUS      RAM                    CPU                    DISK
    ────────────────────────────────────────────────────────────────────────────────────────────────
    TelisSMP                 ● ONLINE    ████░░░░ 2.1GB/4.0GB   ██░░░░░░ 28.4%         8.2GB
    Lunexia Bot              ● ONLINE    ████░░░░ 512MB/1.0GB   █░░░░░░░ 12.1%         1.1GB
    Dev API                  ◎ START     ─                      ─                      ─
    Backup Node              ○ OFFLINE   ─                      ─                      ─
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Servers: 4 total  2 online  2 offline

    Ctrl+C to exit

Color coding:
- Green bar  : usage below 60%
- Yellow bar : usage 60-85%
- Red bar    : usage above 85%

---

## Why Go?

- Single binary — build once, run anywhere, no runtime needed
- Fast concurrent API calls — fetches all servers in parallel
- Low memory footprint — uses under 10MB RAM
- No external dependencies — uses Go standard library only

---

## Building for Different Platforms

Linux (amd64):

    GOOS=linux GOARCH=amd64 go build -o node-monitor-linux monitor.go

Windows:

    GOOS=windows GOARCH=amd64 go build -o node-monitor.exe monitor.go

macOS:

    GOOS=darwin GOARCH=amd64 go build -o node-monitor-mac monitor.go
    
