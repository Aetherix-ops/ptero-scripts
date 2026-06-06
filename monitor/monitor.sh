#!/bin/bash
# =============================================================
#  pterodactyl-scripts — monitor/monitor.sh
#  Monitor status of all Pterodactyl server volumes
#
#  Usage:
#    bash monitor.sh           - show all servers
#    bash monitor.sh --sort    - sort by RAM usage
#    bash monitor.sh --json    - output as JSON
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ── COLORS ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

# ── HELPERS ───────────────────────────────────────────────────
bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1073741824}")GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")KB"
    else
        echo "${bytes}B"
    fi
}

get_dir_size() {
    du -sb "$1" 2>/dev/null | cut -f1
}

check_server_process() {
    local server_id="$1"
    if pgrep -f "$server_id" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}

# ── DISPLAY ───────────────────────────────────────────────────
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Server Monitor                        ║${RESET}"
    echo -e "${CYAN}║        $(date '+%Y-%m-%d %H:%M:%S')                             ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    printf "${WHITE}%-40s %-10s %-10s %-10s${RESET}\n" "SERVER UUID" "STATUS" "DISK" "FILES"
    echo -e "${DIM}──────────────────────────────────────────────────────────────${RESET}"
}

print_server() {
    local uuid="$1"
    local status="$2"
    local disk="$3"
    local files="$4"

    local short_uuid="${uuid:0:8}...${uuid: -4}"

    if [ "$status" = "running" ]; then
        local status_colored="${GREEN}● running${RESET}"
    else
        local status_colored="${RED}○ stopped${RESET}"
    fi

    printf "%-40s %-20b %-10s %-10s\n" "$short_uuid" "$status_colored" "$disk" "$files"
}

print_summary() {
    local total=$1
    local running=$2
    local stopped=$3
    local total_disk=$4

    echo -e "${DIM}──────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${WHITE}Summary${RESET}"
    echo -e "  Total servers  : ${WHITE}$total${RESET}"
    echo -e "  Running        : ${GREEN}$running${RESET}"
    echo -e "  Stopped        : ${RED}$stopped${RESET}"
    echo -e "  Total disk     : ${CYAN}$(bytes_to_human $total_disk)${RESET}"
    echo ""

    # System info
    local mem_total mem_used mem_pct
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_used=$(grep -E "^MemTotal|^MemFree|^Buffers|^Cached|^Slab" /proc/meminfo | \
        awk 'NR==1{t=$2} NR>1{u+=$2} END{print t-u}')
    mem_pct=$(awk "BEGIN {printf \"%.0f\", ($mem_used/$mem_total)*100}")

    local cpu_load
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

    echo -e "${WHITE}System${RESET}"
    echo -e "  CPU load       : ${YELLOW}$cpu_load${RESET}"
    echo -e "  RAM usage      : ${YELLOW}$(bytes_to_human $((mem_used*1024))) / $(bytes_to_human $((mem_total*1024))) (${mem_pct}%)${RESET}"
    echo ""
}

# ── JSON OUTPUT ───────────────────────────────────────────────
output_json() {
    local servers=()
    local total=0 running=0 stopped=0

    echo "{"
    echo "  \"timestamp\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
    echo "  \"servers\": ["

    local first=true
    for server_dir in "$PTERODACTYL_DIR"/*/; do
        if [ -d "$server_dir" ]; then
            local uuid
            uuid=$(basename "$server_dir")
            local status
            status=$(check_server_process "$uuid")
            local disk
            disk=$(get_dir_size "$server_dir")
            local files
            files=$(find "$server_dir" -type f 2>/dev/null | wc -l)

            total=$((total + 1))
            [ "$status" = "running" ] && running=$((running + 1)) || stopped=$((stopped + 1))

            [ "$first" = false ] && echo "    ,"
            echo "    {"
            echo "      \"uuid\": \"$uuid\","
            echo "      \"status\": \"$status\","
            echo "      \"disk_bytes\": $disk,"
            echo "      \"file_count\": $files"
            echo -n "    }"
            first=false
        fi
    done

    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total\": $total,"
    echo "    \"running\": $running,"
    echo "    \"stopped\": $stopped"
    echo "  }"
    echo "}"
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    if [ ! -d "$PTERODACTYL_DIR" ]; then
        echo -e "${RED}[ERR] Pterodactyl volumes directory not found: $PTERODACTYL_DIR${RESET}"
        exit 1
    fi

    # JSON mode
    if [ "$1" = "--json" ]; then
        output_json
        exit 0
    fi

    local servers=()
    local total=0 running=0 stopped=0 total_disk=0

    for server_dir in "$PTERODACTYL_DIR"/*/; do
        if [ -d "$server_dir" ]; then
            local uuid status disk files
            uuid=$(basename "$server_dir")
            status=$(check_server_process "$uuid")
            disk=$(get_dir_size "$server_dir")
            files=$(find "$server_dir" -type f 2>/dev/null | wc -l)

            servers+=("$uuid|$status|$disk|$files")
            total=$((total + 1))
            [ "$status" = "running" ] && running=$((running + 1)) || stopped=$((stopped + 1))
            total_disk=$((total_disk + disk))
        fi
    done

    # Sort by disk usage if --sort flag
    if [ "$1" = "--sort" ]; then
        IFS=$'\n' servers=($(printf '%s\n' "${servers[@]}" | sort -t'|' -k3 -rn))
    fi

    print_header

    for entry in "${servers[@]}"; do
        IFS='|' read -r uuid status disk files <<< "$entry"
        print_server "$uuid" "$status" "$(bytes_to_human $disk)" "$files"
    done

    print_summary "$total" "$running" "$stopped" "$total_disk"
}

main "$@"
