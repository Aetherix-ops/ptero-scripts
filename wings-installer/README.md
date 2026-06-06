# wings-installer

Auto-install Pterodactyl Wings daemon on a fresh Linux node.
Installs all dependencies, Docker, Wings binary, and sets up the systemd service.

---

## Supported OS

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12

---

## What Gets Installed

- curl, wget, git, and other dependencies
- Docker (latest stable via get.docker.com)
- Pterodactyl Wings (latest release)
- Wings systemd service (auto-start on boot)
- Swap space (optional, configurable)

---

## Configuration

Edit config.sh before running:

Option          | Description                    | Default
----------------|--------------------------------|----------------------------------
ARCH            | System architecture            | amd64
WINGS_DATA_DIR  | Wings data directory           | /var/lib/pterodactyl
SETUP_SWAP      | Setup swap space               | true
SWAP_SIZE       | Swap size in GB                | 2
LOG_FILE        | Log file path                  | /var/log/pterodactyl-wings-install.log

---

## Usage

    sudo bash wings-installer.sh

---

## After Installation

1. Go to Pterodactyl Admin Panel -> Nodes -> Create Node
2. Fill in node details (FQDN, ports, memory, disk)
3. On the Configuration tab, copy the config and paste into:

       nano /etc/pterodactyl/config.yml

4. Start Wings:

       systemctl start wings

5. Check status:

       systemctl status wings
       journalctl -u wings --follow
       
