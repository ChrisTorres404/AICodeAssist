#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null; cd p
port=$(( 25000 + RANDOM % 9000 ))
# module A stores notes; module B summarises them — but the summary ignores them (the composition bug)
cat > server.js <<JS
import { createServer } from "node:http";
const things = new Map(); const notes = new Map();
const send = (res, s, b) => { const p = JSON.stringify(b); res.writeHead(s, {"content-type":"application/json"}); res.end(p); };
const body = async (req) => { const c = []; for await (const x of req) c.push(x); const r = Buffer.concat(c).toString(); return r ? JSON.parse(r) : {}; };
createServer(async (req, res) => {
  const u = new URL(req.url, "http://x");
  if (u.pathname === "/health") return send(res, 200, { status: "ok" });
  let m = u.pathname.match(/^\/api\/v1\/things$/);
  if (m && req.method === "POST") { const b = await body(req); const id = "t" + (things.size + 1); things.set(id, { id, name: b.name }); return send(res, 201, things.get(id)); }
  m = u.pathname.match(/^\/api\/v1\/things\/([^/]+)\/notes$/);
  if (m && req.method === "POST") { const b = await body(req); const arr = notes.get(m[1]) || []; arr.push(b.note); notes.set(m[1], arr); return send(res, 201, { note: b.note }); }
  m = u.pathname.match(/^\/api\/v1\/things\/([^/]+)\/summary$/);
  if (m && req.method === "GET") { const t = things.get(m[1]); if (!t) return send(res, 404, { error: "not found" });
    const included = process.env.COMPOSE === "1" ? (notes.get(m[1]) || []) : [];
    return send(res, 200, { id: t.id, name: t.name, notes: included }); }
  send(res, 404, { error: "not found" });
}).listen($port);
JS
printf '{"name":"p","type":"module","scripts":{"start":"node server.js"}}' > package.json
W=./.aicodepipeline/bin/wo; SUITES=Workspace/Testing/suites
a="$($W new "Things module" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; a="${a#WO-}"
b="$($W new "Summary module" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; b="${b#WO-}"
cat > "$SUITES/wo-$a-things.sh" <<'S1'
#!/usr/bin/env bash
set -uo pipefail
id="$(curl -s -X POST -H 'content-type: application/json' -d '{"name":"T"}' "$API_BASE/things" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")"
[ -n "$id" ] && echo "  PASS create" || { echo "  FAIL create"; exit 1; }
curl -s -o /dev/null -X POST -H 'content-type: application/json' -d '{"note":"from module A"}' "$API_BASE/things/$id/notes" && echo "  PASS add note" || exit 1
exit 0
S1
cat > "$SUITES/wo-$b-summary.sh" <<'S2'
#!/usr/bin/env bash
set -uo pipefail
id="$(curl -s -X POST -H 'content-type: application/json' -d '{"name":"T"}' "$API_BASE/things" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")"
code="$(curl -s -o /dev/null -w '%{http_code}' "$API_BASE/things/$id/summary")"
[ "$code" = 200 ] && echo "  PASS summary answers" || { echo "  FAIL summary $code"; exit 1; }
exit 0
S2
chmod +x "$SUITES"/wo-*.sh
(PORT=$port node server.js >/tmp/cg.$$.log 2>&1 & echo $! > /tmp/cg.$$.pid); sleep 1
export API_BASE="http://127.0.0.1:$port/api/v1"
$W verify "$a" --run "$SUITES/wo-$a-things.sh" >/dev/null 2>&1 || { echo "module A suite should pass on its own"; kill "$(cat /tmp/cg.$$.pid)"; exit 1; }
$W verify "$b" --run "$SUITES/wo-$b-summary.sh" >/dev/null 2>&1 || { echo "module B suite should pass on its own"; kill "$(cat /tmp/cg.$$.pid)"; exit 1; }
kill "$(cat /tmp/cg.$$.pid)" 2>/dev/null; sleep 0.5
# both modules verified green. now the integration work order:
out="$($W integrate "Standup composition" --covers "$a,$b" 2>&1)" || { echo "wo integrate failed: $out"; exit 1; }
i="$(printf '%s' "$out" | grep -o 'WO-[0-9]*' | head -1)"; i="${i#WO-}"
f="$(ls "$SUITES"/wo-$i-*.sh)"
grep -q "wo-$a-things.sh" "$f" && grep -q "wo-$b-summary.sh" "$f" || { echo "the integration suite did not wire in the covered suites"; exit 1; }
# add the composition check the template asks for
python3 - "$f" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace('echo "== $pass passed, $fail failed"', '''id="$(curl -s -X POST -H 'content-type: application/json' -d '{"name":"Integration"}' "$BASE/things" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")"
curl -s -o /dev/null -X POST -H 'content-type: application/json' -d '{"note":"from module A"}' "$BASE/things/$id/notes"
contains "$(curl -s "$BASE/things/$id/summary")" "from module A" "the summary includes what the other module wrote"

echo "== $pass passed, $fail failed"''')
p.write_text(s)
PY
export SUITE_START_CMD="PORT=$port node server.js"
rc=0; $W verify "$i" --run "$f" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "the integration suite passed while the composition is broken"; exit 1; }
[ "$(grep -c 'EXECUTED — FAIL' Workspace/Docs/WorkOrders/WO-$i-*/WO-$i-VERIFICATION.md)" -ge 1 ] || { echo "the failure was not recorded"; exit 1; }
rc=0; $W close "$i" >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "the integration work order closed on a failed composition"; exit 1; }
# fix the composition; it must now pass
export SUITE_START_CMD="PORT=$port COMPOSE=1 node server.js"
$W verify "$i" --run "$f" >/dev/null 2>&1 || { echo "the integration suite still fails after the composition is fixed"; exit 1; }
fill_wo "$i"; $W close "$i" >/dev/null || { echo "close refused after a passing composition"; exit 1; }
exit 0
