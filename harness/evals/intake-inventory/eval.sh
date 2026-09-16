#!/usr/bin/env bash
# Three repositories that have never heard of this pipeline, each shaped differently.
# The inventory has to read each one correctly and leave all three untouched.
set -uo pipefail
INV="$PIPELINE_ROOT/core/hooks/inventory.py"
cd "$EVAL_TMP" || { echo "no scratch directory"; exit 1; }
fail() { echo "FAIL: $*"; exit 1; }

git_init() { ( cd "$1" && git init -q && git config user.email e@example.test && git config user.name Fixture ); }
save() { ( cd "$1" && git add -A >/dev/null && git commit -q -m "$2" ); }
doc() { mkdir -p "$(dirname "$1")"; printf '%b' "$2" > "$1"; }

# Content and names both, so a tool that only moved mtimes is still caught.
listing() { ( cd "$1" && find . -path ./.git -prune -o -type f -print | sort |
             while read -r f; do printf '%s  %s\n' "$(cksum < "$f")" "$f"; done ); }

run() { # <repo> <json out> [extra args...]
  local repo="$1" out="$2"; shift 2
  python3 "$INV" --root "$repo" --workorders-dir docs/work-orders --bugs-dir docs/bugs \
    --testing-dir tests --pipeline-dir .aicodepipeline --json "$@" > "$out" 2> "$out.err" ||
    { echo "inventory exited non-zero for $repo"; cat "$out.err"; return 1; }
}

q() { # <json> <dotted.path[#]>  — '#' asks for the length of a list
  python3 - "$1" "$2" <<'PY'
import json, sys
path = sys.argv[2]; want_len = path.endswith("#")
if want_len: path = path[:-1].rstrip(".")
d = json.load(open(sys.argv[1]))
for k in [p for p in path.split(".") if p]:
    d = d[int(k)] if k.lstrip("-").isdigit() else d[k]
print(len(d) if want_len else ("" if d is None else d))
PY
}
is() { # <json> <path> <expected> <what>
  local got; got="$(q "$1" "$2")"
  [ "$got" = "$3" ] || fail "$4: expected '$3', got '$got'"
}
commands_of() { python3 -c "import json,sys;print('\n'.join(json.load(open(sys.argv[1]))['suggested_adopt']))" "$1"; }
docs_of() { python3 -c "import json,sys
[print(d['path'], d['kind']) for d in json.load(open(sys.argv[1]))['docs']]" "$1"; }

# ---------------------------------------------------------------- (a) work-order shaped
mkdir -p a && git_init a
doc a/docs/work-orders/WO-0007-thing/WO-0007-SPEC.md '# Ship the export button\n\nWritten long before any of this.\n'
doc a/docs/work-orders/WO-0007-thing/WO-0007-CHECKLIST.md '# Checklist\n\n- [x] shipped\n'
doc a/docs/bugs/BUG-0031-crash/BUG-0031-crash.md '# Crash when saving twice\n\nStatus: Fixed\n'
doc a/README.md '# Fixture A\n'
doc a/src/app.js 'export const x = 1;\n'
save a "the record as it stood"
before_a="$(listing a)"

run a a.json || exit 1
is a.json record.shape workorders "(a) shape"
is a.json record.items# 1 "(a) work-order count"
is a.json record.bugs# 1 "(a) bug count"
is a.json record.items.0.number 7 "(a) work-order number"
is a.json record.items.0.title "Ship the export button" "(a) title from the H1"
is a.json record.items.0.kind work-order "(a) kind"
is a.json record.items.0.path docs/work-orders/WO-0007-thing/WO-0007-SPEC.md "(a) the folder's specification is the document"
is a.json record.bugs.0.number 31 "(a) bug number"
is a.json git.commits 1 "(a) commits"
is a.json git.present True "(a) git present"
commands_of a.json > a.cmds
grep -qx 'wo adopt "docs/work-orders/WO-0007-thing/WO-0007-SPEC.md" --number 7 --title "Ship the export button" --status migrated' a.cmds \
  || fail "(a) work-order adopt command wrong: $(cat a.cmds)"
grep -qx 'bug adopt "docs/bugs/BUG-0031-crash/BUG-0031-crash.md" --number 31 --category other --status fixed' a.cmds \
  || fail "(a) a Status: Fixed line, or the fallback category, did not reach the bug command: $(cat a.cmds)"
grep -q 'CHECKLIST' a.cmds && fail "(a) every document in a work-order folder became its own item"

# ------------------------------------------------------- (b) numbered documents, and loose ones
mkdir -p b && git_init b
doc b/docs/work-orders/12-feat-search.md '# Search across projects\n\nDone in the spring.\n'
doc b/docs/work-orders/13-fix-login.md '# Login redirect loop\n'
doc b/docs/work-orders/14-feat-export.md '# Export to CSV\n\nStatus: Open\n'
doc b/docs/bugs/003-fixed-crash.md '# Crash on an empty query\n'
doc b/docs/adr/0001-use-postgres.md '# Use PostgreSQL\n\nWe chose it for the JSON support.\n'
doc b/README.md '# Fixture B\n\nA project with a scheme of its own.\n'
doc b/docs/guide.md '# Getting started\n\nHow to run it.\n'
doc b/notes/meeting.md '# Planning session\n\nWho said what.\n'
doc b/src/main.py 'x = 1\n'
save b "the record"
doc b/src/extra.py 'y = 2\n'
save b "a second commit, so the count is read and not assumed"
before_b="$(listing b)"

run b b.json --out "$EVAL_TMP/b-INDEX.md" || exit 1
is b.json record.shape numbered "(b) shape"
is b.json record.where docs/work-orders "(b) where the scheme lives"
is b.json record.items# 4 "(b) item count (three work orders and one decision record)"
is b.json record.bugs# 1 "(b) bug count"
is b.json record.bugs.0.number 3 "(b) bug number"
is b.json record.bugs.0.status_hint fixed "(b) status from the name token"
is b.json git.commits 2 "(b) commits"

commands_of b.json > b.cmds
[ "$(wc -l < b.cmds)" -eq 5 ] || fail "(b) expected five commands, got: $(cat b.cmds)"
grep -qx 'wo adopt "docs/work-orders/12-feat-search.md" --number 12 --title "Search across projects" --status migrated' b.cmds \
  || fail "(b) numbered work order not proposed correctly: $(cat b.cmds)"
grep -qx 'wo adopt "docs/work-orders/14-feat-export.md" --number 14 --title "Export to CSV" --status open' b.cmds \
  || fail "(b) an open item was proposed as migrated: $(cat b.cmds)"
# 'query' in the title is what makes this one a database guess; a bug the word list
# cannot place falls back to 'other', which fixture (a) covers.
grep -qx 'bug adopt "docs/bugs/003-fixed-crash.md" --number 3 --category database --status fixed' b.cmds \
  || fail "(b) the bug command is wrong: $(cat b.cmds)"
grep -qx 'wo adopt "docs/adr/0001-use-postgres.md" --number 1 --title "Use PostgreSQL" --status migrated' b.cmds \
  || fail "(b) the decision record was not proposed: $(cat b.cmds)"

# The loose documentation is catalogued, and proposed for nothing.
docs_of b.json > b.docs
grep -qx 'README.md readme' b.docs || fail "(b) README not catalogued as a readme: $(cat b.docs)"
grep -qx 'docs/guide.md guide' b.docs || fail "(b) guide not catalogued: $(cat b.docs)"
grep -qx 'notes/meeting.md meeting-notes' b.docs || fail "(b) meeting notes not catalogued: $(cat b.docs)"
for loose in README.md docs/guide.md notes/meeting.md; do
  grep -q "$loose" b.cmds && fail "(b) loose documentation produced an adoption command: $loose"
done

# The document
I="$EVAL_TMP/b-INDEX.md"
[ -f "$I" ] || fail "(b) --out wrote no INDEX.md"
grep -q 'The record is numbered documents' "$I" || fail "(b) INDEX.md does not state the shape"
grep -q '^| Number | Kind | Title | Status hint | Path |$' "$I" || fail "(b) INDEX.md has no record table"
grep -q '| 12 | work-order | Search across projects | — | `docs/work-orders/12-feat-search.md` |' "$I" \
  || fail "(b) INDEX.md record table has no row for the first work order"
grep -q '^| Path | Kind | Size | Modified |$' "$I" || fail "(b) INDEX.md has no document table"
grep -q 'read-only' "$I" || fail "(b) INDEX.md does not say the inventory changed nothing"
grep -q "$EVAL_TMP" "$I" && fail "(b) INDEX.md names an absolute host path"

# ------------------------------------------------------------------ (c) nothing but code
mkdir -p c && git_init c
doc c/src/app.py 'def main():\n    return 0\n'
doc c/src/util.py 'VALUE = 2\n'
doc c/.gitignore '*.pyc\n'
save c "code only"
before_c="$(listing c)"

run c c.json --out "$EVAL_TMP/c-INDEX.md" || exit 1
is c.json record.shape none "(c) shape"
is c.json record.items# 0 "(c) item count"
is c.json record.bugs# 0 "(c) bug count"
is c.json docs# 0 "(c) document count"
is c.json suggested_adopt# 0 "(c) adoption commands"
is c.json git.commits 1 "(c) commits"
grep -q 'No record was found' "$EVAL_TMP/c-INDEX.md" || fail "(c) INDEX.md does not say the record is absent"

# ------------------------------------------------------------------ read-only, and a bad root
for r in a b c; do
  eval "was=\$before_$r"
  [ "$was" = "$(listing "$r")" ] || fail "($r) the inventory changed the repository it read"
done
[ -z "$(cd a && git status --porcelain)" ] || fail "(a) the inventory left the tree dirty"

rc=0; python3 "$INV" --root "$EVAL_TMP/absent" --json > bad.out 2> bad.err || rc=$?
[ "$rc" -eq 1 ] || fail "a missing root exited $rc, not 1"
grep -q 'is not a directory' bad.err || fail "a missing root produced no message: $(cat bad.err)"

echo "three repositories read, three shapes named, nothing written"
exit 0
