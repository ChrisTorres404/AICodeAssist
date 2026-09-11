#!/usr/bin/env bash
# WO-50000: Sample server-side metrics during a load run. Run alongside k6.
# Usage: ./capture-server-metrics.sh <run-id> <duration-seconds>
set -euo pipefail
RUN_ID="${1:?run-id}"; DUR="${2:-600}"
DB_HOST="${DB_HOST:-localhost}"; DB_PORT="${DB_PORT:-4232}"
DB_USER="${DB_USER:-{{PROJECT_SLUG}}}"; DB_NAME="${DB_NAME:-{{DB_NAME}}}"
export PGPASSWORD="${DB_PASS:-password}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/results/$RUN_ID"; mkdir -p "$OUT"
CSV="$OUT/server-metrics.csv"
echo "ts,active_conns,idle_conns,api_cpu_pct,api_mem,db_cpu_pct,db_mem" > "$CSV"

end=$(( $(date +%s) + DUR ))
while [ "$(date +%s)" -lt "$end" ]; do
  ts=$(date +%s)
  active=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c \
    "SELECT count(*) FROM pg_stat_activity WHERE datname='$DB_NAME' AND state='active';" 2>/dev/null || echo NA)
  idle=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c \
    "SELECT count(*) FROM pg_stat_activity WHERE datname='$DB_NAME' AND state='idle';" 2>/dev/null || echo NA)
  stats=$(docker stats --no-stream --format '{{.Name}} {{.CPUPerc}} {{.MemUsage}}' 2>/dev/null || true)
  api=$(echo "$stats" | grep {{PROJECT_SLUG}}_api || echo "x 0% 0")
  db=$(echo "$stats" | grep {{DB_NAME}} || echo "x 0% 0")
  echo "$ts,$active,$idle,$(echo "$api"|awk '{print $2}'),$(echo "$api"|awk '{print $3}'),$(echo "$db"|awk '{print $2}'),$(echo "$db"|awk '{print $3}')" >> "$CSV"
  sleep 5
done
echo "[metrics] wrote $CSV"
