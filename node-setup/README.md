# node-setup

Full automated setup for a new Pterodactyl Wings node from scratch.
Handles everything in one script: system update, Docker, firewall, Wings, swap, and fail2ban.

---

## Supported OS

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12

---

## What Gets Installed

Step  | What
------|----------------------------------------------
1/7   | System update (apt update + upgrade)
2/7   | Dependencies (curl, wget, git, htop, etc.)
3/7   | Docker (latest stable)
4/7   | UFW firewall (pre-configured for Pterodactyl)
5/7   | Pterodactyl Wings (latest release)
6/7   | Swap space (configurable)
7/7   | Fail2ban (SSH brute-force protection)

---

## Configuration

Edit config.sh before running:

Option          | Description                    | Default
----------------|--------------------------------|----------
ARCH            | System architecture            | amd64
SSH_PORT        | SSH port                       | 22
WINGS_PORT      | Wings daemon port              | 8080
SFTP_PORT       | Pterodactyl SFTP port          | 2022
GAME_PORT_START | Start of game port range       | 25500
GAME_PORT_END   | End of game port range         | 25600
SETUP_SWAP      | Setup swap space               | true
SWAP_SIZE       | Swap size in GB                | 2
LOG_FILE        | Log file path                  | /var/log/pterodactyl-node-setup.log

---

## Usage

    sudo bash node-setup.sh

---

## After Installation

1. Go to Pterodactyl Admin Panel -> Nodes -> Create Node
2. Fill in node FQDN, ports, memory, and disk limits
3. On the Configuration tab, copy the config and paste into:

       nano /etc/pterodactyl/config.yml

4. Start Wings:

       systemctl start wings

5. Verify node is connected:

       systemctl status wings
       journalctl -u wings --follow

---

## Difference vs wings-installer

Script           | What it does
-----------------|------------------------------------------
wings-installer  | Installs Wings only (minimal)
node-setup       | Full node setup (Wings + Docker + UFW + Fail2ban + Swap)

Use node-setup for a brand new VPS.
Use wings-installer if you already have Docker and firewall configured.
