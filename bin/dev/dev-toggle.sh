#!/bin/bash
# ============================================================
# dev-toggle.sh — Toggle between LOCAL and PRODUCTION modes
# ============================================================
#
# macOS ONLY. This is the one script in the pipeline that is not portable:
# it writes /etc/resolver/<domain> and flushes the resolver cache with
# dscacheutil and mDNSResponder, neither of which exists on Linux. On Linux,
# edit /etc/hosts (or your resolver of choice) and start the proxy by hand.
# Everything else under bin/, core/hooks/, and harness/ runs on both.
#
# Why this exists: browsers treat `localhost` as a public suffix, so cookies
# cannot be shared across subdomains of it. Real subdomains of your own domain
# pointed at 127.0.0.1, fronted by a local reverse proxy, make cross-subdomain
# sessions, OAuth callbacks, and tenant subdomains testable locally.
#
# LOCAL mode:  /etc/hosts points {{PROJECT_DOMAIN}} and DEV_SUBDOMAINS → 127.0.0.1
#              the local reverse proxy is started (Caddy by default)
#              the browser hits your local dev servers
#
# PROD mode:   the hosts entries are removed, the proxy stopped
#              the browser hits real DNS → production (PROD_IP, informational)
#
# Configuration (pipeline.config.sh or env):
#   PROJECT_DOMAIN, DEV_SUBDOMAINS, PROD_IP
#   PROXY_CONFIG   reverse-proxy config file   (default: <project root>/Caddyfile.local,
#                  where the project root is resolved at run time, not at install time)
#   PROXY_START / PROXY_STOP / PROXY_CHECK   commands to override the Caddy defaults
#
# Usage (macOS; the resolver step is macOS-specific):
#   sudo bin/dev/dev-toggle.sh local    # switch to local dev
#   sudo bin/dev/dev-toggle.sh prod     # switch to production
#   bin/dev/dev-toggle.sh status        # show current mode
#
# ============================================================

set -euo pipefail

HOSTS_FILE="/etc/hosts"
RESOLVER_FILE="/etc/resolver/{{PROJECT_DOMAIN}}"
RESOLVER_BACKUP="/etc/resolver/{{PROJECT_DOMAIN}}.bak"
# The project root is worked out when the script runs. Rendering an absolute
# path in here at install time would bake one developer's home directory into
# every clone of the repository — wrong for their teammates, and a personal path
# that the pipeline's own linter then rejects.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# git first; failing that, this script lives at <pipeline>/bin/dev/ and the
# pipeline is installed inside the project, so three levels up is the project.
PROJECT_ROOT="${PROJECT_ROOT:-$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../../.." && pwd))}"
PROXY_CONFIG="${PROXY_CONFIG:-$PROJECT_ROOT/Caddyfile.local}"
PROXY_START="${PROXY_START:-caddy start --config $PROXY_CONFIG}"
PROXY_STOP="${PROXY_STOP:-caddy stop}"
PROXY_CHECK="${PROXY_CHECK:-pgrep -f caddy}"
DEV_SUBDOMAINS="${DEV_SUBDOMAINS:-{{DEV_SUBDOMAINS}}}"
PROD_IP="${PROD_IP:-{{PROD_IP}}}"
MARKER_START="# >>> {{PROJECT_NAME}}-LOCAL-DEV-START"
MARKER_END="# >>> {{PROJECT_NAME}}-LOCAL-DEV-END"

# The full block of hosts entries for local dev
HOSTS_BLOCK="$MARKER_START
# {{PROJECT_NAME}} Local Development
127.0.0.1 {{PROJECT_DOMAIN}}"
for sub in $DEV_SUBDOMAINS; do HOSTS_BLOCK="$HOSTS_BLOCK
127.0.0.1 $sub.{{PROJECT_DOMAIN}}"; done
HOSTS_BLOCK="$HOSTS_BLOCK
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

is_proxy_running() {
    eval "$PROXY_CHECK" >/dev/null 2>&1
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
        echo -e "  /etc/hosts:  ${RED}PROD${NC} (*.{{PROJECT_DOMAIN}} → DNS${PROD_IP:+ → $PROD_IP})"
    fi

    # Check resolver
    if [[ -f "$RESOLVER_FILE" ]]; then
        echo -e "  Resolver:    ${GREEN}LOCAL${NC} (/etc/resolver/{{PROJECT_DOMAIN}} → 127.0.0.1)"
    else
        echo -e "  Resolver:    ${CYAN}PROD${NC} (/etc/resolver/{{PROJECT_DOMAIN}} removed → real DNS)"
    fi

    # Check the reverse proxy
    if is_proxy_running; then
        echo -e "  Proxy:       ${GREEN}RUNNING${NC}"
    else
        echo -e "  Proxy:       ${RED}STOPPED${NC}"
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

    # Start the reverse proxy if not running
    if ! is_proxy_running; then
        echo "  Starting the reverse proxy..."
        eval "$PROXY_START" 2>/dev/null || true
        sleep 1
        if is_proxy_running; then
            echo -e "  ${GREEN}✓${NC} proxy started"
        else
            echo -e "  ${YELLOW}!${NC} proxy did not start — try by hand: $PROXY_START"
        fi
    else
        echo -e "  ${GREEN}✓${NC} proxy already running"
    fi

    echo ""
    echo -e "${GREEN}LOCAL mode active.${NC} Browser → local servers via the reverse proxy."
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

    # Stop the reverse proxy if running
    if is_proxy_running; then
        eval "$PROXY_STOP" 2>/dev/null || true
        sleep 1
        echo -e "  ${GREEN}✓${NC} proxy stopped"
    else
        echo -e "  ${GREEN}✓${NC} proxy already stopped"
    fi

    echo ""
    echo -e "${CYAN}PROD mode active.${NC} Browser → real DNS${PROD_IP:+ ($PROD_IP)}."
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
        echo "  local   Switch to local dev (hosts → 127.0.0.1, start the proxy)"
        echo "  prod    Switch to production (hosts cleaned, stop the proxy)"
        echo "  status  Show current mode (no sudo needed)"
        exit 1
        ;;
esac