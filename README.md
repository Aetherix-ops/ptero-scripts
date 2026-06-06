```
██████╗ ████████╗███████╗██████╗  ██████╗      ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗███████╗
██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗     ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝
██████╔╝   ██║   █████╗  ██████╔╝██║   ██║     ███████╗██║     ██████╔╝██║██████╔╝   ██║   ███████╗
██╔═══╝    ██║   ██╔══╝  ██╔══██╗██║   ██║     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ╚════██║
██║        ██║   ███████╗██║  ██║╚██████╔╝     ███████║╚██████╗██║  ██║██║██║        ██║   ███████║
╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝      ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝
```

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-00d2ff?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-orange?style=flat-square)
![Shell](https://img.shields.io/badge/shell-bash-89e051?style=flat-square)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Compatible-00d2ff?style=flat-square)

**A collection of shell scripts for automating and managing Pterodactyl Panel on Linux servers.**

[Scripts](#scripts) · [Installation](#installation) · [Contributing](#contributing) · [License](#license)

</div>

---

## About

ptero-scripts is a growing collection of battle-tested bash scripts designed to make managing Pterodactyl Panel easier. All scripts run directly on the host server — no extra software required.

> This repository is separate from [ptero-eggs](https://github.com/Aetherix-ops/ptero-eggs).
> - **ptero-eggs** — JSON egg configurations imported into Pterodactyl Panel
> - **ptero-scripts** — Shell scripts run on the host server by the admin

---

## Scripts

### Maintenance

<table>
<tr>
<td width="50%">

**monitor**

Monitor status and disk usage of all Pterodactyl server volumes directly from the terminal. Color-coded output with system RAM and CPU info.

```
bash monitor/monitor.sh
bash monitor/monitor.sh --sort
bash monitor/monitor.sh --json
```

</td>
<td width="50%">

**cleanup**

Clean up old logs, temp files, and cache from all server volumes. Dry run mode to preview before deleting anything.

```
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

**mass-restart**

Restart all Pterodactyl servers at once via the API. Configurable delay between restarts to avoid overloading the node.

```
bash mass-restart/mass-restart.sh
bash mass-restart/mass-restart.sh --dry-run
bash mass-restart/mass-restart.sh --delay 10
```

</td>
<td width="50%">

**disk-usage**

Disk usage report for all server volumes, sorted from largest to smallest. Color-coded with configurable warning and critical thresholds.

```
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

**firewall**

Setup UFW firewall rules specifically for Pterodactyl Panel and Wings. Automatically configures all required ports.

```
sudo bash firewall/firewall-setup.sh
sudo bash firewall/firewall-setup.sh --status
sudo bash firewall/firewall-setup.sh --reset
```

</td>
<td width="50%">

**ssl-renew**

Auto-renew SSL certificates via Certbot. Stops and restarts your web server during renewal, and optionally restarts Wings.

```
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

**wings-installer**

Auto-install Pterodactyl Wings on a fresh node. Installs Docker, Wings binary, and creates the systemd service.

```
sudo bash wings-installer/wings-installer.sh
```

Best for nodes where Docker is already set up.

</td>
<td width="50%">

**node-setup**

Full node setup from scratch in one command. Handles system update, Docker, UFW, Wings, swap, and fail2ban.

```
sudo bash node-setup/node-setup.sh
```

Best for brand new VPS with nothing installed.

</td>
</tr>
</table>

---

## Script Summary

| Script | Category | Root Required | API Key Required |
|---|---|---|---|
| monitor | Maintenance | No | No |
| cleanup | Maintenance | No | No |
| mass-restart | Management | No | Yes |
| disk-usage | Management | No | No |
| firewall | Security | Yes | No |
| ssl-renew | Security | Yes | No |
| wings-installer | Installer | Yes | No |
| node-setup | Installer | Yes | No |

---

## Installation

Clone this repository to your server:

    git clone https://github.com/Aetherix-ops/ptero-scripts.git
    cd ptero-scripts

Make all scripts executable:

    chmod +x */*.sh

Edit the config.sh file inside each script folder before running.

---

## Requirements

| Requirement | Used by |
|---|---|
| bash | All scripts |
| curl, wget | wings-installer, node-setup, mass-restart, ssl-renew |
| jq | mass-restart |
| Docker | wings-installer, node-setup |
| UFW | firewall, node-setup |
| Certbot | ssl-renew |
| Pterodactyl API key | mass-restart |

---

## File Structure

    ptero-scripts/
    |- backup/
    |   |- backup.sh
    |   |- config.sh
    |   |- README.md
    |- monitor/
    |   |- monitor.sh
    |   |- config.sh
    |   |- README.md
    |- cleanup/
    |   |- cleanup.sh
    |   |- config.sh
    |   |- README.md
    |- mass-restart/
    |   |- mass-restart.sh
    |   |- config.sh
    |   |- README.md
    |- disk-usage/
    |   |- disk-usage.sh
    |   |- config.sh
    |   |- README.md
    |- firewall/
    |   |- firewall-setup.sh
    |   |- config.sh
    |   |- README.md
    |- ssl-renew/
    |   |- ssl-renew.sh
    |   |- config.sh
    |   |- README.md
    |- wings-installer/
    |   |- wings-installer.sh
    |   |- config.sh
    |   |- README.md
    |- node-setup/
    |   |- node-setup.sh
    |   |- config.sh
    |   |- README.md
    |- README.md

---

## Changelog

### v1.0.0 — 2026-06-06

- Added backup script (local + remote + Discord notify)
- Added monitor script (status + disk + system info)
- Added cleanup script (logs + temp + cache)
- Added mass-restart script (Pterodactyl API)
- Added disk-usage script (sorted + color-coded)
- Added firewall script (UFW for Pterodactyl)
- Added ssl-renew script (Certbot auto-renew)
- Added wings-installer script
- Added node-setup script (full from scratch)

---

## Contributing

Pull requests are welcome. If you have a useful Pterodactyl script to share:

1. Fork this repo
2. Create a branch: `git checkout -b add/script-name`
3. Add your script in a new folder with its own `README.md` and `config.sh`
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
If this helped you, consider giving it a star!
</div>
