# power-scheduler

Auto start, stop, or restart Pterodactyl servers based on a configurable schedule.
Runs as a persistent Node.js process, checking schedules every minute.

---

## Requirements

- Node.js 18+
- No external npm packages required
- Pterodactyl Client API key

---

## Configuration

Edit config.js:

    nano config.js

Option              | Description                              | Default
--------------------|------------------------------------------|---------------------------
PANEL_URL           | Pterodactyl panel URL                    | https://panel.yourdomain.com
API_KEY             | Client API key from account settings     | (empty)
NOTIFY_DISCORD      | Send Discord notification on action      | false
DISCORD_WEBHOOK_URL | Discord webhook URL                      | (empty)
SCHEDULES           | Array of schedule objects                | (see examples)

Schedule object fields:

Field       | Description                                      | Example
------------|--------------------------------------------------|------------------
identifier  | Server identifier from panel URL                 | "abc12345"
name        | Server name (use instead of identifier)          | "TelisSMP"
action      | Power action to perform                          | "start"
time        | Time in 24-hour format HH:MM                     | "08:00"
days        | Days to run (0=Sun ... 6=Sat), [] = every day    | [1,2,3,4,5]

Action options: start, stop, restart, kill

---

## Usage

    # Start the scheduler (runs continuously)
    node scheduler.js

    # List all configured schedules
    node scheduler.js --list

    # Test API connection
    node scheduler.js --test

    # Using npm scripts
    npm start
    npm run list
    npm run test

---

## Schedule Examples

    // Start server every day at 08:00
    { identifier: "abc12345", action: "start", time: "08:00", days: [] }

    // Stop server every day at 23:00
    { identifier: "abc12345", action: "stop", time: "23:00", days: [] }

    // Restart server every Monday at 04:00
    { name: "Lunexia Bot", action: "restart", time: "04:00", days: [1] }

    // Start server on weekdays at 09:00
    { name: "Dev API", action: "start", time: "09:00", days: [1,2,3,4,5] }

---

## Running as a Service (systemd)

Create a service file:

    nano /etc/systemd/system/power-scheduler.service

Paste:

    [Unit]
    Description=Pterodactyl Power Scheduler
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/ptero-scripts/power-scheduler
    ExecStart=/usr/bin/node scheduler.js
    Restart=on-failure
    RestartSec=10s

    [Install]
    WantedBy=multi-user.target

Enable and start:

    systemctl daemon-reload
    systemctl enable --now power-scheduler
    systemctl status power-scheduler

---

## How It Finds Your Server

Server can be matched by identifier or name:
- identifier: the short ID shown in the panel URL (e.g. abc12345)
- name: the server name (case-insensitive match)

If the server is already in the desired state, the action is skipped automatically.
