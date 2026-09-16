#!/usr/bin/env bash
# INTAKE-03 — baseline: the project's own tests have been run once and recorded
# against this tree.
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

pipeline_root="${PIPELINE_ROOT:-.aicodepipeline}"
bl="$root/${TESTING_DIR:-Workspace/Testing}/results/BASELINE.md"
wo_bin="$root/$pipeline_root/bin/wo"
fix="run  acp baseline  (or  acp baseline --command '<your test command>'  when the tool cannot find one)"

echo "== INTAKE-03 baseline — $root"

[ -x "$wo_bin" ] || {
  echo "  precondition: $pipeline_root/bin/wo is missing or not executable, so the recorded tree cannot be compared to the current one — re-run the installer"
  exit 77; }

if [ -f "$bl" ]; then
  ok "a baseline is recorded at ${bl#$root/}"

  recorded="$(grep -m1 -oE 'tree [0-9a-f]{16}' "$bl" 2>/dev/null | cut -d' ' -f2 || true)"
  if [ -n "$recorded" ]; then
    ok "the baseline names the tree it was taken against ($recorded)"
    current="$(cd "$root" && "$wo_bin" fingerprint 2>/dev/null || true)"
    if [ -z "$current" ] || [ "$current" = nofp ]; then
      bad "the current tree fingerprint could not be computed" "check the install, then $fix"
    elif [ "$current" = "$recorded" ]; then
      ok "the baseline was taken against this exact tree"
    else
      bad "the tree has changed since the baseline was taken (recorded $recorded, now $current)" "re-run acp baseline: $fix"
    fi
  else
    bad "the baseline names no tree, so nothing binds it to a source state" "it predates this format or was written by hand: $fix"
    bad "the recorded tree could not be compared to the current one" "$fix"
  fi

  if grep -q '^\*\*Result:\*\*\|^- \*\*Result:\*\*' "$bl"; then
    ok "the baseline records a result: $(sed -n 's/^- \*\*Result:\*\* //p;s/^\*\*Result:\*\* //p' "$bl" | head -1 | cut -c1-80)"
  else
    bad "the baseline has no Result line, so it says nothing about whether the tests passed" "$fix"
  fi
else
  bad "no baseline: the project's own tests have never been run under this tool" "$fix"
  bad "no recorded tree to compare against the current one" "$fix"
  bad "no recorded result" "$fix"
fi

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
