#!/bin/bash
# ============================================================
# dev-toggle.sh — Toggle between LOCAL and PRODUCTION modes
# ============================================================
#
# LOCAL mode:  /etc/hosts points *.{{PROJECT_DOMAIN}} → 127.0.0.1
#              Caddy reverse proxy active on port 80
#              Browser hits local dev servers
#
# PROD mode:   /etc/hosts entries commented out
#              Caddy stopped
#              Browser hits real DNS → EC2 (${PROD_IP:?set PROD_IP})
#
# Usage:
#   sudo ./scripts/dev-toggle.sh local    # Switch to local dev
#   sudo ./scripts/dev-toggle.sh prod     # Switch to production
#   sudo ./scripts/dev-toggle.sh status   # Show current mode
#
# ============================================================

set -euo pipefail

HOSTS_FILE="/etc/hosts"
RESOLVER_FILE="/etc/resolver/{{PROJECT_DOMAIN}}"
RESOLVER_BACKUP="/etc/resolver/{{PROJECT_DOMAIN}}.bak"
CADDY_CONFIG="{{PROJECT_ROOT}}/Caddyfile.local"
MARKER_START="# >>> {{PROJECT_NAME}}-LOCAL-DEV-START"
MARKER_END="# >>> {{PROJECT_NAME}}-LOCAL-DEV-END"

# The full block of hosts entries for local dev
HOSTS_BLOCK="$MARKER_START
# {{PROJECT_NAME}} Local Development
127.0.0.1 {{PROJECT_DOMAIN}}
# Subdomains come from DEV_SUBDOMAINS in pipeline.config.sh
$MARKER_END"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run with sudo${NC}"
        echo "  sudo $0 $*"
        exit 1
    fi
}

has_active_block() {
    grep -q "$MARKER_START" "$HOSTS_FILE" 2>/dev/null
}

is_caddy_running() {
    pgrep -f "caddy run.*Caddyfile.local" >/dev/null 2>&1
}

flush_dns() {
    dscacheutil -flushcache 2>/dev/null || true
    killall -HUP mDNSResponder 2>/dev/null || true
}

remove_old_entries() {
    # Remove old-style entries (without markers) — the messy ones currently in hosts
    local tmpfile
    tmpfile=$(mktemp)
    awk '
        /{{PROJECT_DOMAIN_RE}}/ { next }
        /{{PROJECT_NAME}} Local Development/ { next }
        { print }
    ' "$HOSTS_FILE" > "$tmpfile"
    cp "$tmpfile" "$HOSTS_FILE"
    rm -f "$tmpfile"
}

remove_marked_block() {
    local tmpfile
    tmpfile=$(mktemp)
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
        $0 == start { skip=1; next }
        $0 == end { skip=0; next }
        !skip { print }
    ' "$HOSTS_FILE" > "$tmpfile"
    cp "$tmpfile" "$HOSTS_FILE"
    rm -f "$tmpfile"
}

show_status() {
    echo ""
    echo -e "${CYAN}=== {{PROJECT_NAME}} Dev Toggle Status ===${NC}"
    echo ""

    # Check hosts
    if has_active_block; then
        echo -e "  /etc/hosts:  ${GREEN}LOCAL${NC} (*.{{PROJECT_DOMAIN}} → 127.0.0.1)"
    elif grep -q "{{PROJECT_DOMAIN}}" "$HOSTS_FILE" 2>/dev/null; then
        echo -e "  /etc/hosts:  ${YELLOW}LEGACY${NC} (old-style entries, run 'local' or 'prod' to clean up)"
    else
        echo -e "  /etc/hosts:  ${RED}PROD${NC} (*.{{PROJECT_DOMAIN}} → DNS → ${PROD_IP:?set PROD_IP})"
    fi

    # Check resolver
    if [[ -f "$RESOLVER_FILE" ]]; then
        echo -e "  Resolver:    ${GREEN}LOCAL${NC} (/etc/resolver/{{PROJECT_DOMAIN}} → 127.0.0.1)"
    else
        echo -e "  Resolver:    ${CYAN}PROD${NC} (/etc/resolver/{{PROJECT_DOMAIN}} removed → real DNS)"
    fi

    # Check Caddy
    if is_caddy_running; then
        echo -e "  Caddy:       ${GREEN}RUNNING${NC} (reverse proxy active on port 80)"
    else
        echo -e "  Caddy:       ${RED}STOPPED${NC}"
    fi

    # Quick DNS check
    local resolved
    resolved=$(dscacheutil -q host -a name api.{{PROJECT_DOMAIN}} 2>/dev/null | grep "ip_address" | head -1 | awk '{print $2}')
    if [[ "$resolved" == "127.0.0.1" ]]; then
        echo -e "  DNS resolves: ${GREEN}127.0.0.1${NC} (local)"
    elif [[ -n "$resolved" ]]; then
        echo -e "  DNS resolves: ${CYAN}$resolved${NC} (production)"
    else
        echo -e "  DNS resolves: ${YELLOW}unknown${NC} (try: dig api.{{PROJECT_DOMAIN}})"
    fi
    echo ""
}

switch_local() {
    echo -e "${GREEN}Switching to LOCAL mode...${NC}"

    # Clean up any existing entries (old or new style)
    remove_old_entries
    if has_active_block; then
        remove_marked_block
    fi

    # Add the clean marked block
    echo "" >> "$HOSTS_FILE"
    echo "$HOSTS_BLOCK" >> "$HOSTS_FILE"

    # Restore /etc/resolver/{{PROJECT_DOMAIN}} for wildcard subdomain resolution
    if [[ ! -f "$RESOLVER_FILE" ]]; then
        echo "nameserver 127.0.0.1" > "$RESOLVER_FILE"
        echo -e "  ${GREEN}✓${NC} /etc/resolver/{{PROJECT_DOMAIN}} restored (wildcard subdomain resolution)"
    else
        echo -e "  ${GREEN}✓${NC} /etc/resolver/{{PROJECT_DOMAIN}} already present"
    fi

    flush_dns
    echo -e "  ${GREEN}✓${NC} /etc/hosts updated (*.{{PROJECT_DOMAIN}} → 127.0.0.1)"

    # Start Caddy if not running
    if ! is_caddy_running; then
        echo "  Starting Caddy..."
        caddy start --config "$CADDY_CONFIG" 2>/dev/null
        sleep 1
        if is_caddy_running; then
            echo -e "  ${GREEN}✓${NC} Caddy started on port 80"
        else
            echo -e "  ${YELLOW}!${NC} Caddy may not have started — try: sudo caddy run --config $CADDY_CONFIG"
        fi
    else
        echo -e "  ${GREEN}✓${NC} Caddy already running"
    fi

    echo ""
    echo -e "${GREEN}LOCAL mode active.${NC} Browser → localhost via Caddy."
    show_status
}

switch_prod() {
    echo -e "${CYAN}Switching to PROD mode...${NC}"

    # Remove all {{PROJECT_DOMAIN}} entries
    remove_old_entries
    if has_active_block; then
        remove_marked_block
    fi

    # Remove /etc/resolver/{{PROJECT_DOMAIN}} so macOS uses real DNS
    if [[ -f "$RESOLVER_FILE" ]]; then
        cp "$RESOLVER_FILE" "$RESOLVER_BACKUP" 2>/dev/null || true
        rm -f "$RESOLVER_FILE"
        echo -e "  ${GREEN}✓${NC} /etc/resolver/{{PROJECT_DOMAIN}} removed (backed up to .bak)"
    else
        echo -e "  ${GREEN}✓${NC} /etc/resolver/{{PROJECT_DOMAIN}} already absent"
    fi

    flush_dns
    echo -e "  ${GREEN}✓${NC} /etc/hosts cleaned (*.{{PROJECT_DOMAIN}} → DNS → production)"

    # Stop Caddy if running
    if is_caddy_running; then
        caddy stop 2>/dev/null || pkill -f "caddy run.*Caddyfile" 2>/dev/null || true
        sleep 1
        echo -e "  ${GREEN}✓${NC} Caddy stopped"
    else
        echo -e "  ${GREEN}✓${NC} Caddy already stopped"
    fi

    echo ""
    echo -e "${CYAN}PROD mode active.${NC} Browser → ${PROD_IP:?set PROD_IP} (EC2)."
    show_status
}

# ============================================================
# Main
# ============================================================

case "${1:-status}" in
    local|l)
        check_root "$@"
        switch_local
        ;;
    prod|p)
        check_root "$@"
        switch_prod
        ;;
    status|s)
        show_status
        ;;
    *)
        echo "Usage: sudo $0 {local|prod|status}"
        echo ""
        echo "  local   Switch to local dev (hosts → 127.0.0.1, start Caddy)"
        echo "  prod    Switch to production (hosts cleaned, stop Caddy)"
        echo "  status  Show current mode (no sudo needed)"
        exit 1
        ;;
esac