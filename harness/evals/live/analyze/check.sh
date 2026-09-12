#!/usr/bin/env bash
set -uo pipefail; cd "$PROJECT"
fail() { echo "FAIL: $*"; exit 1; }
d="$(grep -l "^area=analysis" Workspace/Docs/WorkOrders/WO-*/.wo-meta 2>/dev/null | head -1)"; [ -n "$d" ] || fail "no work order with --area analysis"
d="$(dirname "$d")"
prof="$(grep -l "SOURCE:" "$d"/*.md 2>/dev/null | head -1)"; [ -n "$prof" ] || fail "no document with <!-- SOURCE: --> traceability comments in $d"
count="$(grep -o "<!-- SOURCE:" "$d"/*.md | wc -l | tr -d ' ')"; [ "$count" -ge 3 ] || fail "only $count SOURCE comments"
for f in "$d"/*.md; do
  out="$(python3 -c "import json,sys; print(json.dumps({'tool_input':{'file_path':sys.argv[1],'content':open(sys.argv[1]).read()}}))" "$PWD/$f" | python3 .aicodepipeline/core/hooks/doc-claims-check.py 2>&1)"
  echo "$out" | grep -q "does not exist" && fail "untraceable claim in $(basename "$f"): $(echo "$out" | grep 'does not exist' | head -1)"
done
ls "$d" | grep -qi "source-ref\|references" || echo "note: no source-reference index file (not failing)"
echo "PASS: analysis work order with $count traced claims, all SOURCE paths and lines resolve"
