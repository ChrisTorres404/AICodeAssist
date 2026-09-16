#!/usr/bin/env bash
# Builds a small project with a knowledge base, then moves the source underneath
# it: the engine must report exactly which profiles stopped resting on the code
# they were written from, and which code nothing describes.
set -uo pipefail
KB_PY="$PIPELINE_ROOT/core/hooks/kb.py"
cd "$EVAL_TMP" || exit 1
P="$EVAL_TMP/proj"; KB="$P/Workspace/Docs/KnowledgeBase"
mkdir -p "$P/src/auth" "$P/src/billing" "$P/src/util" "$KB/profiles"

# --- the fixture: four source files, two profiles, and an index nobody cites ---
cat > "$P/src/auth/login.ts" <<'F'
import { session } from "./session";
export async function login(email: string, password: string) {
  const user = await lookup(email);
  if (!user) return null;
  return session.start(user);
}
F
cat > "$P/src/auth/session.ts" <<'F'
export const session = {
  start(user: User) { return { id: user.id, issued: Date.now() }; },
  end(id: string) { return true; },
};
F
cat > "$P/src/billing/invoice.ts" <<'F'
export function total(lines: Line[]) {
  return lines.reduce((n, l) => n + l.amount, 0);
}
export function issue(invoice: Invoice) { return send(invoice); }
F
printf 'export const log = (m: string) => process.stdout.write(m);\n' > "$P/src/util/log.ts"

printf '# Analysis\n\nEight phases, no claims of its own; the profiles carry them.\n' > "$KB/analysis.md"
printf '# Feature Status Matrix\n\n| Feature | Status |\n|---|---|\n| Login | SHIPPED |\n' > "$KB/feature-status-matrix.md"
cat > "$KB/profiles/auth.md" <<'F'
---
wo: WO-0001
title: "Authentication — Feature Profile"
---
Login looks the user up and starts a session. <!-- SOURCE: src/auth/login.ts:L3 -->
A session records the user id and the time it was issued. <!-- SOURCE: src/auth/session.ts:L2 -->
Sessions can be ended by id. <!-- SOURCE: src/auth/session.ts:L3-L4 -->
Every claim carries its file and line, as <!-- SOURCE: path:L12 --> shows.
F
cat > "$KB/profiles/billing.md" <<'F'
---
wo: WO-0001
title: "Billing — Feature Profile"
---
An invoice total is the sum of its lines. <!-- SOURCE: src/billing/invoice.ts:L2 -->
Issuing an invoice sends it. <!-- SOURCE: src/billing/invoice.ts:L4 -->
F

snap() { python3 - "$1" <<'F'
import hashlib, os, sys
root = sys.argv[1]
for d, dirs, fs in os.walk(root):
    dirs.sort()
    for f in sorted(fs):
        p = os.path.join(d, f)
        print(os.path.relpath(p, root), hashlib.sha256(open(p, "rb").read()).hexdigest()[:12])
F
}
K() { python3 "$KB_PY" "$@" --root "$P" --kb "$KB"; }

# --- 1. before bind: every profile is stale, and nothing was written ----------
snap "$P" > "$EVAL_TMP/before"
out="$(K status 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || { echo "status before bind exited $rc, expected 1 (stale)"; echo "$out"; exit 1; }
case "$out" in *"not bound"*) ;; *) echo "status did not say the base was never bound"; echo "$out"; exit 1;; esac
for p in "profiles/auth.md" "profiles/billing.md"; do
  echo "$out" | grep -q "^$p  *stale" || { echo "$p was not stale before bind"; echo "$out"; exit 1; }
done
echo "$out" | grep -q "^kb: 2 profiles — 0 current, 2 stale, 0 broken;" || { echo "summary line wrong before bind"; echo "$out"; exit 1; }
# a document with no citations is not a profile
case "$out" in *"analysis.md"*|*"feature-status-matrix.md"*) echo "a document with no SOURCE comments was counted as a profile"; echo "$out"; exit 1;; *) ;; esac
K impact --files src/auth/login.ts >/dev/null 2>&1
snap "$P" > "$EVAL_TMP/after-reads"
diff "$EVAL_TMP/before" "$EVAL_TMP/after-reads" >/dev/null || { echo "status/impact wrote to the project:"; diff "$EVAL_TMP/before" "$EVAL_TMP/after-reads"; exit 1; }

# --- 2. bind writes the index, and only the index -----------------------------
out="$(K bind 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "bind exited $rc"; echo "$out"; exit 1; }
snap "$P" > "$EVAL_TMP/after-bind"
added="$(diff "$EVAL_TMP/before" "$EVAL_TMP/after-bind" | grep '^>' | awk '{print $2}')"
[ "$added" = "Workspace/Docs/KnowledgeBase/source-index.tsv" ] || { echo "bind wrote more than the index: $added"; exit 1; }
diff "$EVAL_TMP/before" "$EVAL_TMP/after-bind" | grep -q '^<' && { echo "bind changed an existing file"; exit 1; }
IDX="$KB/source-index.tsv"
head -1 "$IDX" | grep -q "bound_tree=[0-9a-f]\{16\}" || { echo "index header carries no bound_tree:"; head -1 "$IDX"; exit 1; }
[ "$(grep -vc '^#' "$IDX")" -eq 3 ] || { echo "index should hold 3 cited files, has $(grep -vc '^#' "$IDX")"; cat "$IDX"; exit 1; }
grep -q "^src/auth/session.ts	[0-9a-f]\{16\}	profiles/auth.md$" "$IDX" || { echo "session.ts row wrong:"; cat "$IDX"; exit 1; }
grep -q "^src/billing/invoice.ts	[0-9a-f]\{16\}	profiles/billing.md$" "$IDX" || { echo "invoice.ts row wrong:"; cat "$IDX"; exit 1; }
grep -q "src/util/log.ts" "$IDX" && { echo "a file no profile cites reached the index"; exit 1; }
grep -q "^path	" "$IDX" && { echo "the template's placeholder citation was bound as a real one"; exit 1; }
grep -q "/tmp\|$EVAL_TMP" "$IDX" && { echo "the index carries absolute paths:"; cat "$IDX"; exit 1; }

# --- 3. bound and unchanged: current, with the undescribed file named ---------
out="$(K status 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "status after bind exited $rc, expected 0"; echo "$out"; exit 1; }
echo "$out" | grep -q "^kb: 2 profiles — 2 current, 0 stale, 0 broken; 1 uncovered source files" || { echo "summary wrong after bind"; echo "$out"; exit 1; }
echo "$out" | grep -q "uncovered: 1 source file" || { echo "uncovered count not reported"; echo "$out"; exit 1; }
echo "$out" | grep -q "src/util .*src/util/log.ts" || { echo "the uncovered file was not named under its directory"; echo "$out"; exit 1; }

# --- 4. an edit makes exactly the profile that describes it stale -------------
printf '  refresh(id: string) { return true; },\n' >> "$P/src/auth/session.ts"
out="$(K status 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || { echo "status after editing a cited file exited $rc, expected 1"; echo "$out"; exit 1; }
echo "$out" | grep -q "^profiles/auth.md  *stale  *src/auth/session.ts — changed since bind" || { echo "auth profile not stale with a reason"; echo "$out"; exit 1; }
echo "$out" | grep -q "^profiles/billing.md  *current" || { echo "billing profile should be untouched"; echo "$out"; exit 1; }

# --- 5. impact names the profiles that describe a change ----------------------
out="$(K impact --files src/auth/session.ts 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || { echo "impact on a described file exited $rc, expected 1"; echo "$out"; exit 1; }
echo "$out" | grep -q "^profiles/auth.md	src/auth/session.ts$" || { echo "impact did not name the profile"; echo "$out"; exit 1; }
echo "$out" | grep -q "^profiles/billing.md" && { echo "impact named a profile that does not cite the file"; echo "$out"; exit 1; }
echo "$out" | grep -q "^kb impact: 1 profile(s) describe 1 of 1 changed file(s)" || { echo "impact count line wrong"; echo "$out"; exit 1; }
out="$(K impact --files src/util/log.ts 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "impact on an undescribed file exited $rc, expected 0"; echo "$out"; exit 1; }
echo "$out" | grep -q "^kb impact: 0 profile(s)" || { echo "impact should report no profiles"; echo "$out"; exit 1; }
printf '%s' "$out" | tr '\n' '|' | grep -q "uncovered:|  src/util/log.ts" || { echo "impact did not list the file as uncovered"; echo "$out"; exit 1; }
# the same set on stdin, same answer
out="$(printf 'src/auth/session.ts\n' | K impact --stdin 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || { echo "impact --stdin exited $rc, expected 1"; echo "$out"; exit 1; }

# --- 6. --json is the same report, machine-readable ---------------------------
K status --json > "$EVAL_TMP/s.json" 2>/dev/null; rc=$?
[ "$rc" -eq 1 ] || { echo "status --json exited $rc, expected 1"; exit 1; }
python3 - "$EVAL_TMP/s.json" <<'F' || exit 1
import json, sys
d = json.load(open(sys.argv[1]))
assert d["counts"] == {"profiles": 2, "current": 1, "stale": 1, "broken": 0}, d["counts"]
assert d["uncovered"]["count"] == 1 and d["uncovered"]["files"] == ["src/util/log.ts"], d["uncovered"]
assert d["uncovered"]["clusters"][0]["dir"] == "src/util", d["uncovered"]["clusters"]
assert d["bound"] is True and len(d["bound_tree"]) == 16, d["bound_tree"]
assert d["exit"] == 1, d["exit"]
s = {p["profile"]: p for p in d["profiles"]}
assert s["profiles/auth.md"]["state"] == "stale" and s["profiles/billing.md"]["state"] == "current", s
F

# --- 7. re-binding after the edit makes it current again ----------------------
K bind >/dev/null 2>&1 || { echo "re-bind failed"; exit 1; }
K status >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] || { echo "status after re-bind exited $rc, expected 0"; K status; exit 1; }

# --- 8. a deleted cited file is broken, and broken outranks stale -------------
rm "$P/src/billing/invoice.ts"
printf 'export function refresh() {}\n' >> "$P/src/auth/session.ts"     # stale at the same time
out="$(K status 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "a deleted cited file exited $rc, expected 2"; echo "$out"; exit 1; }
echo "$out" | grep -q "^profiles/billing.md  *broken  *src/billing/invoice.ts — cited file does not exist" || { echo "the missing path was not named"; echo "$out"; exit 1; }
echo "$out" | grep -q "^kb: 2 profiles — 0 current, 1 stale, 1 broken;" || { echo "summary wrong with a broken profile"; echo "$out"; exit 1; }

# --- 9. a citation past the end of the file is broken; one with no line is not -
cat > "$P/src/billing/invoice.ts" <<'F'
export function total(lines: Line[]) {
  return lines.reduce((n, l) => n + l.amount, 0);
}
export function issue(invoice: Invoice) { return send(invoice); }
F
printf -- '---\nwo: WO-0001\n---\nLogging exists. <!-- SOURCE: src/util/log.ts -->\n' > "$KB/profiles/util.md"
K bind >/dev/null 2>&1
out="$(K status 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || { echo "a citation with no line number should only check existence (exit $rc)"; echo "$out"; exit 1; }
echo "$out" | grep -q "^kb: 3 profiles — 3 current, 0 stale, 0 broken; 0 uncovered source files" || { echo "summary wrong once every file is cited"; echo "$out"; exit 1; }
printf -- '---\nwo: WO-0001\n---\nLogging exists. <!-- SOURCE: src/util/log.ts:L40 -->\n' > "$KB/profiles/util.md"
out="$(K status 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || { echo "a citation past the end of the file exited $rc, expected 2"; echo "$out"; exit 1; }
echo "$out" | grep -q "^profiles/util.md  *broken  *src/util/log.ts:L40 — past the end of the file (1 lines)" || { echo "the line past the end was not reported"; echo "$out"; exit 1; }
rm "$KB/profiles/util.md"

# --- 10. --source-ext is configurable ----------------------------------------
printf 'def helper():\n    return 1\n' > "$P/src/util/helper.py"
K bind >/dev/null 2>&1
out="$(K status --source-ext .py 2>&1)"
echo "$out" | grep -q "; 1 uncovered source files" || { echo "--source-ext did not narrow the scan"; echo "$out"; exit 1; }
echo "$out" | grep -q "src/util/helper.py" || { echo "--source-ext did not find the python file"; echo "$out"; exit 1; }

# --- 11. no knowledge base is its own answer, and still writes nothing --------
snap "$P" > "$EVAL_TMP/before-missing"
out="$(python3 "$KB_PY" status --root "$P" --kb "$P/Workspace/Docs/Nothing" 2>&1)"; rc=$?
[ "$rc" -eq 3 ] || { echo "a missing knowledge base exited $rc, expected 3"; echo "$out"; exit 1; }
case "$out" in *"no knowledge base at Workspace/Docs/Nothing"*) ;; *) echo "wrong message for a missing base: $out"; exit 1;; esac
out="$(python3 "$KB_PY" bind --root "$P" --kb "$P/Workspace/Docs/Nothing" 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || { echo "bind with no profiles exited $rc, expected 1"; echo "$out"; exit 1; }
case "$out" in *"no profiles"*) ;; *) echo "bind did not say why it refused: $out"; exit 1;; esac
snap "$P" > "$EVAL_TMP/after-missing"
diff "$EVAL_TMP/before-missing" "$EVAL_TMP/after-missing" >/dev/null || { echo "a failed bind wrote to the project"; exit 1; }
[ -d "$P/Workspace/Docs/Nothing" ] && { echo "bind created the directory it was told to read"; exit 1; }

# --- 12. the same tree binds to the same bytes --------------------------------
cp "$IDX" "$EVAL_TMP/idx1"; K bind >/dev/null 2>&1
diff "$EVAL_TMP/idx1" "$IDX" >/dev/null || { echo "two binds of one tree produced different indexes"; diff "$EVAL_TMP/idx1" "$IDX"; exit 1; }
exit 0
