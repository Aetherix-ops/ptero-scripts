```
██████╗ ████████╗███████╗██████╗  ██████╗     ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗███████╗
██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝
██████╔╝   ██║   █████╗  ██████╔╝██║   ██║    ███████╗██║     ██████╔╝██║██████╔╝   ██║   ███████╗
██╔═══╝    ██║   ██╔══╝  ██╔══██╗██║   ██║    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ╚════██║
██║        ██║   ███████╗██║  ██║╚██████╔╝    ███████║╚██████╗██║  ██║██║██║        ██║   ███████║
╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝
```

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-00d2ff?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-orange?style=flat-square)
![Bash](https://img.shields.io/badge/Bash-5.0+-89e051?style=flat-square&logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat-square&logo=python&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-18+-339933?style=flat-square&logo=nodedotjs&logoColor=white)
![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat-square&logo=go&logoColor=white)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Compatible-00d2ff?style=flat-square)

**A collection of shell scripts for automating and managing Pterodactyl Panel on Linux servers.**

[Scripts](#scripts) · [Installation](#installation) · [Languages](#languages) · [Contributing](#contributing)

</div>

---

## About

ptero-scripts is a growing collection of battle-tested scripts designed to make managing Pterodactyl Panel easier. Scripts are written in multiple languages — each chosen for what it does best.

> This repository is separate from [ptero-eggs](https://github.com/Aetherix-ops/ptero-eggs).
> - **ptero-eggs** — JSON egg configurations imported into Pterodactyl Panel
> - **ptero-scripts** — Scripts run on the host server by the admin

---

## Scripts

### Maintenance

<table>
<tr>
<td width="50%">

**monitor** `bash`

Monitor status and disk usage of all server volumes from the terminal. Color-coded output with RAM and CPU info.

```bash
bash monitor/monitor.sh
bash monitor/monitor.sh --sort
bash monitor/monitor.sh --json
```

</td>
<td width="50%">

**cleanup** `bash`

Clean up old logs, temp files, and cache from all server volumes. Dry run mode to preview before deleting.

```bash
bash cleanup/cleanup.sh
bash cleanup/cleanup.sh --run
bash cleanup/cleanup.sh --run <uuid>
```

</td>
</tr>
</table>

---

### Management

<table>
<tr>
<td width="50%">

**mass-restart** `bash`

Restart all servers at once via the Pterodactyl API. Configurable delay between restarts.

```bash
bash mass-restart/mass-restart.sh
bash mass-restart/mass-restart.sh --dry-run
bash mass-restart/mass-restart.sh --delay 10
```

</td>
<td width="50%">

**disk-usage** `bash`

Disk usage report for all server volumes, sorted largest to smallest. Color-coded thresholds.

```bash
bash disk-usage/disk-usage.sh
bash disk-usage/disk-usage.sh --top 10
bash disk-usage/disk-usage.sh --warn
bash disk-usage/disk-usage.sh --json
```

</td>
</tr>
</table>

---

### Security

<table>
<tr>
<td width="50%">

**firewall** `bash`

Setup UFW firewall rules for Pterodactyl Panel and Wings. Configures all required ports automatically.

```bash
sudo bash firewall/firewall-setup.sh
sudo bash firewall/firewall-setup.sh --status
sudo bash firewall/firewall-setup.sh --reset
```

</td>
<td width="50%">

**ssl-renew** `bash`

Auto-renew SSL certificates via Certbot. Stops and restarts your web server and Wings automatically.

```bash
sudo bash ssl-renew/ssl-renew.sh
sudo bash ssl-renew/ssl-renew.sh --status
sudo bash ssl-renew/ssl-renew.sh --force
```

</td>
</tr>
</table>

---

### Installer

<table>
<tr>
<td width="50%">

**wings-installer** `bash`

Auto-install Pterodactyl Wings on a fresh node. Installs Docker, Wings binary, and systemd service.

```bash
sudo bash wings-installer/wings-installer.sh
```

Best for nodes where Docker is already configured.

</td>
<td width="50%">

**node-setup** `bash`

Full node setup from scratch in one command. Docker + UFW + Wings + Swap + Fail2ban.

```bash
sudo bash node-setup/node-setup.sh
```

Best for a brand new VPS with nothing installed.

</td>
</tr>
</table>

---

### API Scripts

<table>
<tr>
<td width="50%">

**stats-reporter** `python`

Fetch server stats and send a formatted report to Discord. Shows RAM, CPU, disk, and status for all servers.

```bash
python3 stats-reporter/stats_reporter.py
python3 stats-reporter/stats_reporter.py --test
python3 stats-reporter/stats_reporter.py --console
```

</td>
<td width="50%">

**power-scheduler** `node.js`

Auto start, stop, or restart servers based on a schedule. Runs as a persistent process checking every minute.

```bash
node power-scheduler/scheduler.js
node power-scheduler/scheduler.js --list
node power-scheduler/scheduler.js --test
```

</td>
</tr>
</table>

---

### Realtime

<table>
<tr>
<td width="50%">

**node-monitor** `go`

Realtime terminal dashboard. Refreshes every 3 seconds, fetches all servers in parallel, color-coded bars.

```bash
go run node-monitor/monitor.go

# or build binary
go build -o node-monitor node-monitor/monitor.go
./node-monitor
```

</td>
<td width="50%">

**backup** `bash`

Auto-backup all server volumes to local or remote destination. Retention policy, compression, Discord notify.

```bash
bash backup/backup.sh
bash backup/backup.sh <server-uuid>
```

</td>
</tr>
</table>

---

## Script Summary

| Script | Language | Category | Root | API Key |
|---|---|---|---|---|
| backup | Bash | Maintenance | No | No |
| monitor | Bash | Maintenance | No | No |
| cleanup | Bash | Maintenance | No | No |
| mass-restart | Bash | Management | No | Yes |
| disk-usage | Bash | Management | No | No |
| firewall | Bash | Security | Yes | No |
| ssl-renew | Bash | Security | Yes | No |
| wings-installer | Bash | Installer | Yes | No |
| node-setup | Bash | Installer | Yes | No |
| stats-reporter | Python | API | No | Yes |
| power-scheduler | Node.js | API | No | Yes |
| node-monitor | Go | Realtime | No | Yes |

---

## Languages

| Language | Used for | Why |
|---|---|---|
| Bash | System tasks | Native on Linux, no runtime needed |
| Python | API + reporting | Clean data processing, no dependencies |
| Node.js | Scheduler | Event-driven, great for timers |
| Go | Realtime monitor | Fast, concurrent, single binary |

---

## Installation

Clone this repository:

    git clone https://github.com/Aetherix-ops/ptero-scripts.git
    cd ptero-scripts

Make bash scripts executable:

    chmod +x */*.sh

Each script has its own config file. Edit before running:

    nano <script-folder>/config.sh     # bash scripts
    nano <script-folder>/config.py     # python scripts
    nano <script-folder>/config.js     # node.js scripts
    nano <script-folder>/config.env    # go scripts

---

## File Structure

    ptero-scripts/
    |- backup/
    |- monitor/
    |- cleanup/
    |- mass-restart/
    |- disk-usage/
    |- firewall/
    |- ssl-renew/
    |- wings-installer/
    |- node-setup/
    |- stats-reporter/
    |- power-scheduler/
    |- node-monitor/
    |- README.md

Each folder contains:
- Main script file
- config file
- README.md with full documentation

---

## Changelog

### v2.0.0 — 2026-06-06
- Added stats-reporter (Python) — Discord server stats report
- Added power-scheduler (Node.js) — scheduled server start/stop
- Added node-monitor (Go) — realtime terminal dashboard

### v1.0.0 — 2026-06-06
- Added backup, monitor, cleanup scripts
- Added mass-restart, disk-usage scripts
- Added firewall, ssl-renew scripts
- Added wings-installer, node-setup scripts

---

## Contributing

Pull requests are welcome. To add a new script:

1. Fork this repo
2. Create a branch: `git checkout -b add/script-name`
3. Add your script in a new folder with `README.md` and a config file
4. Commit: `git commit -m "add: script-name description"`
5. Open a Pull Request

---

## Related Repositories

| Repository | Description |
|---|---|
| [ptero-eggs](https://github.com/Aetherix-ops/ptero-eggs) | Updated Pterodactyl egg collection |
| [novastar-theme](https://github.com/Aetherix-ops/novastar-theme) | Dark futuristic Pterodactyl theme |

---

## License

MIT License — free to use, modify, and distribute.
Credit appreciated but not required.

---

<div align="center">
Made with care by <a href="https://github.com/Aetherix-ops">Aetherix-ops</a>
<br><br>
If this helped you, consider giving it a 
</div>
