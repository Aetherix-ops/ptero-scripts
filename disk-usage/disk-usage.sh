#!/bin/bash
# =============================================================
#  pterodactyl-scripts — disk-usage/disk-usage.sh
#  Show disk usage report for all Pterodactyl server volumes
#
#  Usage:
#    bash disk-usage.sh            - show all servers sorted by size
#    bash disk-usage.sh --top 10   - show top 10 largest servers
#    bash disk-usage.sh --json     - output as JSON
#    bash disk-usage.sh --warn     - show only servers above threshold
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
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}")GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}")MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}")KB"
    else
        echo "${bytes}B"
    fi
}

color_size() {
    local bytes=$1
    local warn_bytes=$((WARN_THRESHOLD_GB * 1073741824))
    local crit_bytes=$((CRIT_THRESHOLD_GB * 1073741824))

    if [ "$bytes" -ge "$crit_bytes" ]; then
        echo -e "${RED}$(bytes_to_human $bytes)${RESET}"
    elif [ "$bytes" -ge "$warn_bytes" ]; then
        echo -e "${YELLOW}$(bytes_to_human $bytes)${RESET}"
    else
        echo -e "${GREEN}$(bytes_to_human $bytes)${RESET}"
    fi
}

# ── JSON OUTPUT ───────────────────────────────────────────────
output_json() {
    local entries=()
    local total_bytes=0

    for server_dir in "$PTERODACTYL_DIR"/*/; do
        [ -d "$server_dir" ] || continue
        local uuid size files
        uuid=$(basename "$server_dir")
        size=$(du -sb "$server_dir" 2>/dev/null | cut -f1)
        files=$(find "$server_dir" -type f 2>/dev/null | wc -l)
        total_bytes=$((total_bytes + size))
        entries+=("$size|$uuid|$files")
    done

    IFS=$'\n' entries=($(printf '%s\n' "${entries[@]}" | sort -t'|' -k1 -rn))

    echo "{"
    echo "  \"generated_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
    echo "  \"total_bytes\": $total_bytes,"
    echo "  \"servers\": ["

    local first=true
    for entry in "${entries[@]}"; do
        IFS='|' read -r size uuid files <<< "$entry"
        [ "$first" = false ] && echo "    ,"
        echo "    { \"uuid\": \"$uuid\", \"bytes\": $size, \"files\": $files }"
        first=false
    done

    echo "  ]"
    echo "}"
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    local top=0
    local warn_only=false
    local json=false

    for arg in "$@"; do
        case $arg in
            --top) shift; top="$1" ;;
            --warn) warn_only=true ;;
            --json) json=true ;;
        esac
    done

    if [ ! -d "$PTERODACTYL_DIR" ]; then
        echo -e "${RED}[ERR] Directory not found: $PTERODACTYL_DIR${RESET}"
        exit 1
    fi

    if [ "$json" = true ]; then
        output_json
        exit 0
    fi

    local entries=()
    local total_bytes=0

    for server_dir in "$PTERODACTYL_DIR"/*/; do
        [ -d "$server_dir" ] || continue
        local uuid size files
        uuid=$(basename "$server_dir")
        size=$(du -sb "$server_dir" 2>/dev/null | cut -f1)
        files=$(find "$server_dir" -type f 2>/dev/null | wc -l)
        total_bytes=$((total_bytes + size))
        entries+=("$size|$uuid|$files")
    done

    IFS=$'\n' entries=($(printf '%s\n' "${entries[@]}" | sort -t'|' -k1 -rn))

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║        Pterodactyl Disk Usage Report                     ║${RESET}"
    echo -e "${CYAN}║        $(date '+%Y-%m-%d %H:%M:%S')                             ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    printf "${WHITE}%-40s %-14s %-10s${RESET}\n" "SERVER UUID" "DISK USAGE" "FILES"
    echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"

    local shown=0
    local warn_bytes=$((WARN_THRESHOLD_GB * 1073741824))

    for entry in "${entries[@]}"; do
        IFS='|' read -r size uuid files <<< "$entry"

        if [ "$warn_only" = true ] && [ "$size" -lt "$warn_bytes" ]; then
            continue
        fi

        local colored_size
        colored_size=$(color_size "$size")
        printf "%-40s %-24b %-10s\n" "$uuid" "$colored_size" "$files"

        shown=$((shown + 1))
        [ "$top" -gt 0 ] && [ "$shown" -ge "$top" ] && break
    done

    echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"
    echo ""

    # Disk info
    local disk_total disk_used disk_free disk_pct
    disk_total=$(df -B1 "$PTERODACTYL_DIR" | tail -1 | awk '{print $2}')
    disk_used=$(df -B1 "$PTERODACTYL_DIR" | tail -1 | awk '{print $3}')
    disk_free=$(df -B1 "$PTERODACTYL_DIR" | tail -1 | awk '{print $4}')
    disk_pct=$(df "$PTERODACTYL_DIR" | tail -1 | awk '{print $5}')

    echo -e "${WHITE}Summary${RESET}"
    echo -e "  Servers shown  : ${WHITE}$shown${RESET}"
    echo -e "  Total (volumes): ${CYAN}$(bytes_to_human $total_bytes)${RESET}"
    echo ""
    echo -e "${WHITE}Host Disk${RESET}"
    echo -e "  Total          : $(bytes_to_human $disk_total)"
    echo -e "  Used           : ${YELLOW}$(bytes_to_human $disk_used) ($disk_pct)${RESET}"
    echo -e "  Free           : ${GREEN}$(bytes_to_human $disk_free)${RESET}"
    echo ""
    echo -e "${DIM}Legend: ${GREEN}Normal${RESET}${DIM} | ${YELLOW}Warning (>${WARN_THRESHOLD_GB}GB)${RESET}${DIM} | ${RED}Critical (>${CRIT_THRESHOLD_GB}GB)${RESET}"
    echo ""
}

main "$@"
