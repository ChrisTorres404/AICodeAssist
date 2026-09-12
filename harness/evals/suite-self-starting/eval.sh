#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null; cd p
port=$(( 21000 + RANDOM % 9000 ))
cat > server.js <<JS
import { createServer } from "node:http";
createServer((req, res) => {
  if (req.url === "/health") { res.writeHead(200, {"content-type":"application/json"}); res.end('{"status":"ok"}'); return; }
  res.writeHead(404, {"content-type":"application/json"}); res.end('{"error":"not found"}');
}).listen($port);
JS
printf '{"name":"p","type":"module","scripts":{"start":"node server.js"}}' > package.json
W=./.aicodepipeline/bin/wo
n="$($W new "Self starting" --size trivial --area backend | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
$W suite "$n" >/dev/null
f="$(ls Workspace/Testing/suites/wo-$n-*.sh)"
# nothing is running, nothing is exported beyond the base URL: the suite must cope
out="$(API_BASE="http://127.0.0.1:$port/api/v1" bash "$f" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "a scaffolded suite could not run on its own:"; echo "$out" | tail -6; exit 1; }
case "$out" in *"PASS health"*) ;; *) echo "health check did not pass: $out"; exit 1;; esac
sleep 1; curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$port/health" && { echo "the suite left its service running"; exit 1; }
exit 0
