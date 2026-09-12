#!/usr/bin/env bash
# kill-ports.sh — free local development ports before starting servers.
#
#   bin/dev/kill-ports.sh 3000 3001          ports as arguments
#   DEV_PORTS="3000 3001" bin/dev/kill-ports.sh
#
# Kills the listener on each port and anything still connected to it. Stale
# dev servers that survive a restart are the most common cause of "my change
# is not showing up"; run this before you ask anyone to test in a browser.
set -euo pipefail
PORTS=("$@")
[ ${#PORTS[@]} -gt 0 ] || read -r -a PORTS <<< "${DEV_PORTS:-}"
[ ${#PORTS[@]} -gt 0 ] || { echo "usage: $0 <port>... (or set DEV_PORTS)" >&2; exit 1; }
for port in "${PORTS[@]}"; do
  if lsof -i :"$port" >/dev/null 2>&1; then
    echo "  port $port: killing listeners and connected sockets"
    lsof -ti tcp:"$port" | xargs kill -9 2>/dev/null || true
    lsof -ti tcp:"$port" -sTCP:ESTABLISHED | xargs kill -9 2>/dev/null || true
  else
    echo "  port $port: already clear"
  fi
done
echo "ports freed: ${PORTS[*]}"
