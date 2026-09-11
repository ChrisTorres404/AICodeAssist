#!/usr/bin/env bash
set -euo pipefail

PORTS=(5050 7070)

echo "🔪 Nuking dev ports: ${PORTS[*]}"
for port in "${PORTS[@]}"; do
  if lsof -i :"${port}" >/dev/null 2>&1; then
    echo "  Port ${port}: killing listeners and child sockets"
    # Kill direct listeners first
    lsof -ti tcp:"${port}" | xargs -r kill -9 || true
    # Kill anything still connected to that listener
    lsof -ti tcp:"${port}" -sTCP:ESTABLISHED | xargs -r kill -9 || true
  else
    echo "  Port ${port}: already clear"
  fi
done

echo "✅ Ports freed"
