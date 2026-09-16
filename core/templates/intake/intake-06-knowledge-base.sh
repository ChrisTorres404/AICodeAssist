#!/usr/bin/env bash
# INTAKE-06 — knowledge base: the repository has been described, the description
# is bound to the source it describes, and it reaches the level this project asked
# for.
#
# The lite level is built by the tool itself (acp kb scaffold), so a fresh install
# passes this step without an agent run. KNOWLEDGE_LEVEL raises the bar to
# standard (the narrative written) or full (validated by a second reader).
#
# Exit codes: 0 every check passed, 1 at least one failed, 77 the checks could
# not be attempted at all. This suite reads; it never writes into the project.
set -uo pipefail

root="$(cd "$(dirname "$0")" && while [ "$PWD" != / ] && [ ! -f pipeline.config.sh ]; do cd ..; done; pwd -P)"
[ -f "$root/pipeline.config.sh" ] || {
  echo "  precondition: no pipeline.config.sh in this directory or any directory above it, so the project root cannot be resolved"
  exit 77; }
. "$root/pipeline.config.sh"

pass=0; fail=0
ok()  { pass=$((pass + 1)); printf '  PASS %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL %s — %s\n' "$1" "$2"; }

kb_rel="${KNOWLEDGE_DIR:-Workspace/Docs/KnowledgeBase}"
kb="$root/$kb_rel"
level="${KNOWLEDGE_LEVEL:-lite}"
case "$level" in lite|standard|full) ;; *) level=lite;; esac
pipeline_root="${PIPELINE_ROOT:-.aicodepipeline}"
engine="$root/$pipeline_root/core/hooks/kb.py"
detect="$root/$pipeline_root/bin/detect-stack"
build="run  acp kb scaffold  — it reads the tree and writes the knowledge base itself, no agent run needed"

echo "== INTAKE-06 knowledge base ($level) — $root"

command -v python3 >/dev/null 2>&1 || {
  echo "  precondition: python3 is not on PATH, and the knowledge-base engine needs it"
  exit 77; }
[ -f "$engine" ] || {
  echo "  precondition: the knowledge-base engine is missing ($pipeline_root/core/hooks/kb.py). Nothing here can be checked until it is installed — re-run the installer with a version that ships it."
  exit 77; }

# 0. a tree with no source in it yet
# A brand new project has nothing to describe, and saying so is the true answer.
# The knowledge base grows as work orders close; asking for profiles of code that
# has not been written is asking for fiction.
empty=unknown
if [ -f "$detect" ]; then
  if python3 "$detect" "$root" --json 2>/dev/null \
     | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("empty") else 1)' 2>/dev/null; then
    empty=yes
  elif python3 "$detect" "$root" --json >/dev/null 2>&1; then
    empty=no
  fi
fi
if [ "$empty" = unknown ]; then
  # Fallback: any file with a source extension outside the directories no rule reads.
  if find "$root" \( -name .git -o -name node_modules -o -name dist -o -name build -o -name .next \
                     -o -name coverage -o -name .venv -o -name venv -o -name __pycache__ \) -prune -o \
          -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' \
                     -o -name '*.cjs' -o -name '*.py' -o -name '*.go' -o -name '*.rb' -o -name '*.java' \
                     -o -name '*.kt' -o -name '*.rs' -o -name '*.php' -o -name '*.cs' -o -name '*.swift' \
                     -o -name '*.vue' -o -name '*.svelte' \) -print 2>/dev/null | head -1 | grep -q .; then
    empty=no
  else
    empty=yes
  fi
fi
if [ "$empty" = yes ]; then
  ok "nothing to describe yet — this tree holds no source, and the knowledge base grows as work orders close"
  if [ -d "$kb" ]; then
    ok "the knowledge base is at $kb_rel, ready for the first feature"
  else
    bad "no knowledge base at $kb_rel" "$build — it writes the survey that records an empty tree"
  fi
  echo "== $pass passed, $fail failed"
  [ "$fail" -eq 0 ]
  exit
fi

# 1. the directory
if [ -d "$kb" ]; then
  ok "the knowledge base is at $kb_rel"
else
  bad "no knowledge base at $kb_rel" "$build"
fi

# 2. the binding between the description and the source
if [ -f "$kb/source-index.tsv" ]; then
  ok "source-index.tsv binds the description to the files it was written from ($(wc -l < "$kb/source-index.tsv" | tr -d ' ') row(s))"
else
  bad "no source-index.tsv in $kb_rel, so nothing binds the description to the source" "run  acp kb bind  (or  acp kb scaffold, which binds on its way out)"
fi

# 3. at least one Feature Profile
profiles=0
for p in "$kb"/profiles/*; do [ -f "$p" ] && profiles=$((profiles + 1)); done
if [ "$profiles" -gt 0 ]; then
  ok "$profiles Feature Profile(s) under $kb_rel/profiles"
else
  bad "no Feature Profile under $kb_rel/profiles" "$build"
fi

# 4. an analysis document: the prose, as opposed to the index and the matrix
analysis=""
for m in "$kb"/*.md; do
  [ -f "$m" ] || continue
  case "$(basename "$m")" in
    INDEX.md|README.md|source-index.md|*matrix*|*MATRIX*) continue;;
  esac
  analysis="$(basename "$m")"; break
done
if [ -n "$analysis" ]; then
  ok "an analysis document is on file ($analysis)"
else
  bad "no analysis document in $kb_rel — an index and a matrix are not a description" "$build"
fi

# 5. the engine's own verdict: current, stale, broken, or short of the level
rc=0
out="$(python3 "$engine" status --root "$root" --kb "$kb" --level "$level" 2>&1)" || rc=$?
[ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/  kb: /'
short="$(printf '%s\n' "$out" | awk '/^short of /{f=1;next} f&&/^  /{print $1;next} f{f=0}' | tr '\n' ' ' | sed 's/  *$//')"
case "$level" in
  full) howto="have ${short:-each of them} validated: read it against the source, then set  validated: true  and  reviewed-by: <name>  in its frontmatter";;
  *)    howto="write the narrative sections of ${short:-each of them}, then  acp kb bind";;
esac
case "$rc" in
  0) ok "every profile is current against the source it cites, and at the $level level";;
  1) bad "some profiles are stale: the source moved under them" "run  acp kb status  to see which, update the stale profiles, then  acp kb bind";;
  2) bad "some profiles are broken: they cite source that no longer exists" "run  acp kb status  to see which, repair those profiles, then  acp kb bind";;
  3) bad "the engine found no knowledge base to report on" "$build";;
  4) bad "the profiles are current, but these fall short of the $level level: ${short:-run  acp kb status  to see which}" "$howto";;
  *) bad "the knowledge-base engine exited $rc, so its verdict could not be read" "run  acp kb status  and read the error";;
esac

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
