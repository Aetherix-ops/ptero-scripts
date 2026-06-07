#!/usr/bin/env python3
# =============================================================
#  pterodactyl-scripts — stats-reporter/stats_reporter.py
#  Fetch Pterodactyl server stats and send to Discord webhook
#
#  Usage:
#    python3 stats_reporter.py           - send stats report
#    python3 stats_reporter.py --test    - test Discord webhook
#    python3 stats_reporter.py --console - print to console only
# =============================================================

import sys
import json
import urllib.request
import urllib.error
from datetime import datetime
from config import (
    PANEL_URL, API_KEY, DISCORD_WEBHOOK_URL,
    REPORT_TITLE, SHOW_OFFLINE_SERVERS,
    RAM_WARN_PERCENT, CPU_WARN_PERCENT
)

# ── COLORS (console) ──────────────────────────────────────────
class C:
    RED    = '\033[0;31m'
    GREEN  = '\033[0;32m'
    YELLOW = '\033[1;33m'
    CYAN   = '\033[0;36m'
    WHITE  = '\033[1;37m'
    RESET  = '\033[0m'

def log(msg):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}")

# ── API ───────────────────────────────────────────────────────
def api_request(endpoint, client=False):
    base = "client" if client else "application"
    url = f"{PANEL_URL}/api/{base}/{endpoint}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Accept": "application/json",
            "Content-Type": "application/json"
        }
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            return json.loads(res.read().decode())
    except urllib.error.HTTPError as e:
        log(f"[ERR] API error {e.code}: {endpoint}")
        return None
    except Exception as e:
        log(f"[ERR] Request failed: {e}")
        return None

def get_servers():
    data = api_request("servers?per_page=100")
    if not data:
        return []
    return data.get("data", [])

def get_server_resources(identifier):
    data = api_request(f"servers/{identifier}/resources", client=True)
    if not data:
        return None
    return data.get("attributes", {})

# ── FORMATTING ────────────────────────────────────────────────
def bytes_to_human(b):
    if b >= 1073741824:
        return f"{b/1073741824:.1f}GB"
    elif b >= 1048576:
        return f"{b/1048576:.1f}MB"
    elif b >= 1024:
        return f"{b/1024:.1f}KB"
    return f"{b}B"

def bar(percent, width=10):
    filled = int(width * percent / 100)
    return "█" * filled + "░" * (width - filled)

def status_emoji(state):
    return {
        "running": "🟢",
        "offline": "🔴",
        "starting": "🟡",
        "stopping": "🟠"
    }.get(state, "⚪")

# ── BUILD DISCORD EMBED ───────────────────────────────────────
def build_embed(servers_data):
    now = datetime.now().strftime("%d %b %Y — %H:%M")
    total = len(servers_data)
    online = sum(1 for s in servers_data if s["state"] == "running")
    offline = total - online

    fields = []

    for s in servers_data:
        if not SHOW_OFFLINE_SERVERS and s["state"] != "running":
            continue

        emoji = status_emoji(s["state"])
        name = s["name"][:20]

        if s["state"] == "running" and s["resources"]:
            r = s["resources"]
            ram_used = r.get("memory_bytes", 0)
            ram_limit = s["limits"]["memory"] * 1048576 if s["limits"]["memory"] > 0 else 0
            cpu = r.get("cpu_absolute", 0)
            disk = r.get("disk_bytes", 0)

            ram_pct = (ram_used / ram_limit * 100) if ram_limit > 0 else 0
            ram_warn = "⚠️ " if ram_pct >= RAM_WARN_PERCENT else ""
            cpu_warn = "⚠️ " if cpu >= CPU_WARN_PERCENT else ""

            ram_str = f"{bytes_to_human(ram_used)} / {bytes_to_human(ram_limit)}" if ram_limit > 0 else bytes_to_human(ram_used)

            value = (
                f"**RAM** {ram_warn}`{bar(ram_pct)}` {ram_str}\n"
                f"**CPU** {cpu_warn}`{bar(cpu)}` {cpu:.1f}%\n"
                f"**Disk** `{bytes_to_human(disk)}`\n"
                f"**Node** `{s['node']}`"
            )
        else:
            value = f"**Status** `{s['state']}`"

        fields.append({
            "name": f"{emoji} {name}",
            "value": value,
            "inline": True
        })

    # Summary field
    fields.append({
        "name": "━━━━━━━━━━━━━━━━━━━━━━",
        "value": (
            f"**Total** `{total}` servers\n"
            f"🟢 Online: `{online}` | 🔴 Offline: `{offline}`"
        ),
        "inline": False
    })

    embed = {
        "title": f"📊 {REPORT_TITLE}",
        "description": f"*Generated at {now}*",
        "color": 0x00d2ff,
        "fields": fields,
        "footer": {
            "text": "ptero-scripts • stats-reporter"
        },
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
    }

    return embed

# ── SEND TO DISCORD ───────────────────────────────────────────
def send_discord(embed):
    payload = json.dumps({"embeds": [embed]}).encode("utf-8")
    req = urllib.request.Request(
        DISCORD_WEBHOOK_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            if res.status in (200, 204):
                log(f"{C.GREEN}[OK] Report sent to Discord{C.RESET}")
                return True
    except urllib.error.HTTPError as e:
        log(f"{C.RED}[ERR] Discord webhook error: {e.code}{C.RESET}")
    except Exception as e:
        log(f"{C.RED}[ERR] Failed to send to Discord: {e}{C.RESET}")
    return False

# ── CONSOLE PRINT ─────────────────────────────────────────────
def print_console(servers_data):
    print(f"\n{C.CYAN}{'═'*60}{C.RESET}")
    print(f"{C.WHITE}  {REPORT_TITLE}{C.RESET}")
    print(f"{C.CYAN}{'═'*60}{C.RESET}\n")

    for s in servers_data:
        emoji = {"running": "[ON] ", "offline": "[OFF]"}.get(s["state"], "[???]")
        color = C.GREEN if s["state"] == "running" else C.RED
        print(f"  {color}{emoji}{C.RESET} {s['name'][:30]:<30}", end="")

        if s["state"] == "running" and s["resources"]:
            r = s["resources"]
            ram = bytes_to_human(r.get("memory_bytes", 0))
            cpu = r.get("cpu_absolute", 0)
            print(f" RAM: {ram:<10} CPU: {cpu:.1f}%")
        else:
            print(f" {s['state']}")

    total = len(servers_data)
    online = sum(1 for s in servers_data if s["state"] == "running")
    print(f"\n{C.CYAN}{'─'*60}{C.RESET}")
    print(f"  Total: {total} | Online: {C.GREEN}{online}{C.RESET} | Offline: {C.RED}{total-online}{C.RESET}\n")

# ── MAIN ──────────────────────────────────────────────────────
def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""

    # Test mode
    if mode == "--test":
        log("Sending test message to Discord...")
        test_embed = {
            "title": "Test — ptero-scripts stats-reporter",
            "description": "Webhook is working correctly!",
            "color": 0x00ff9d
        }
        send_discord(test_embed)
        return

    log("Fetching server list...")
    servers = get_servers()

    if not servers:
        log(f"{C.RED}[ERR] No servers found or API call failed.{C.RESET}")
        sys.exit(1)

    log(f"Found {len(servers)} servers. Fetching resources...")

    servers_data = []
    for s in servers:
        attr = s["attributes"]
        identifier = attr["identifier"]
        resources = get_server_resources(identifier)

        servers_data.append({
            "name": attr["name"],
            "identifier": identifier,
            "node": attr.get("node", "unknown"),
            "state": resources.get("current_state", "offline") if resources else "offline",
            "resources": resources.get("resources", {}) if resources else {},
            "limits": attr.get("limits", {})
        })

    # Console mode
    if mode == "--console":
        print_console(servers_data)
        return

    # Default: send to Discord
    print_console(servers_data)
    embed = build_embed(servers_data)
    send_discord(embed)

if __name__ == "__main__":
    main()
