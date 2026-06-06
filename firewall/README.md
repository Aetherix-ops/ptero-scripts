# firewall

Setup UFW firewall rules specifically for Pterodactyl Panel and Wings.
Automatically configures all required ports with sensible defaults.

---

## Requirements

- Root access
- Ubuntu / Debian based system
- UFW (auto-installed if not present)

---

## What Gets Configured

Rule                  | Port(s)            | Protocol
----------------------|--------------------|----------
SSH                   | 22 (configurable)  | TCP
HTTP                  | 80                 | TCP
HTTPS                 | 443                | TCP
Pterodactyl Panel     | 443 (configurable) | TCP
Pterodactyl Wings     | 8080               | TCP
Pterodactyl SFTP      | 2022               | TCP
Game Servers          | 25500-25600        | TCP + UDP
Extra ports           | (configurable)     | any

---

## Configuration

Edit config.sh before running:

    nano config.sh

Option              | Description                              | Default
--------------------|------------------------------------------|----------
SSH_PORT            | SSH port                                 | 22
PANEL_ON_THIS_NODE  | Is panel installed on this node          | true
PANEL_PORT          | Panel port                               | 443
WINGS_PORT          | Wings daemon port                        | 8080
SFTP_PORT           | Pterodactyl SFTP port                    | 2022
GAME_PORT_START     | Start of game server port range          | 25500
GAME_PORT_END       | End of game server port range            | 25600
EXTRA_PORTS         | Additional ports to allow (space sep)    | (empty)

---

## Usage

    # Setup firewall rules
    sudo bash firewall-setup.sh

    # Show current rules
    sudo bash firewall-setup.sh --status

    # Reset all rules
    sudo bash firewall-setup.sh --reset

---

## Warning

Always make sure SSH_PORT is correct before running.
If you lock yourself out, you will need console access to fix it.
