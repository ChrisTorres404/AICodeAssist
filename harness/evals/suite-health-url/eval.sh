#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null; cd p
W=./.aicodepipeline/bin/wo
n="$($W new "Health check" --size trivial --area backend | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"; $W suite "$n" >/dev/null
cat > srv.py <<'PY'
import http.server, socketserver, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health": self.send_response(200); self.end_headers(); self.wfile.write(b'{"status":"ok"}')
        else: self.send_response(404); self.end_headers()
    def log_message(self, *a): pass
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", int(sys.argv[1])), H) as s: s.serve_forever()
PY
port=$(( 20000 + RANDOM % 20000 )); python3 srv.py "$port" & spid=$!; sleep 1
rc=0; out="$(API_BASE="http://127.0.0.1:$port/api/v1" bash Workspace/Testing/suites/wo-$n-*.sh 2>&1)" || rc=$?
kill $spid 2>/dev/null
[ "$rc" -eq 0 ] || { echo "scaffolded suite failed against a service whose health lives at the root:"; echo "$out" | tail -5; exit 1; }
echo "$out" | grep -q "PASS health" || { echo "health check did not pass: $out"; exit 1; }
exit 0
