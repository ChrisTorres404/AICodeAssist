#!/usr/bin/env bash
# INTAKE-06 — knowledge base: the repository has been described, and the
# description is bound to the source it describes.
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
pipeline_root="${PIPELINE_ROOT:-.aicodepipeline}"
engine="$root/$pipeline_root/core/hooks/kb.py"
build="describe the repository first (under Claude Code run  /analyze-repo ; under any other agent open the knowledge-base work order and follow its prompt), then run  acp kb bind"

echo "== INTAKE-06 knowledge base — $root"

command -v python3 >/dev/null 2>&1 || {
  echo "  precondition: python3 is not on PATH, and the knowledge-base engine needs it"
  exit 77; }
[ -f "$engine" ] || {
  echo "  precondition: the knowledge-base engine is missing ($pipeline_root/core/hooks/kb.py). Nothing here can be checked until it is installed — re-run the installer with a version that ships it."
  exit 77; }

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
  bad "no source-index.tsv in $kb_rel, so nothing binds the description to the source" "run  acp kb bind"
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

# 5. the engine's own verdict: current, stale, or broken
rc=0
out="$(python3 "$engine" status --root "$root" --kb "$kb" 2>&1)" || rc=$?
[ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/  kb: /'
case "$rc" in
  0) ok "every profile is current against the source it cites";;
  1) bad "some profiles are stale: the source moved under them" "run  acp kb status  to see which, update the stale profiles, then  acp kb bind";;
  2) bad "some profiles are broken: they cite source that no longer exists" "run  acp kb status  to see which, repair those profiles, then  acp kb bind";;
  3) bad "the engine found no knowledge base to report on" "$build";;
  *) bad "the knowledge-base engine exited $rc, so its verdict could not be read" "run  acp kb status  and read the error";;
esac

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
