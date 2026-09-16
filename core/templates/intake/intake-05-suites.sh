#!/usr/bin/env bash
# INTAKE-05 — suites: the project has at least one way to produce evidence.
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

tdir="${TESTING_DIR:-Workspace/Testing}"
pipeline_root="${PIPELINE_ROOT:-.aicodepipeline}"
manifest="$root/$tdir/suites.manifest"

# A brand new project has nothing here yet. That is not a failure of the project;
# this step becomes real when there is something to run, and says so until then.
if "$root/$pipeline_root/bin/detect-stack" "$root" --json 2>/dev/null | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("empty") else 1)' 2>/dev/null; then
  ok "nothing to run yet: the tree has no source files; this step counts again once there is"
  echo "== $pass passed, $fail failed"; exit 0
fi
suites_dir="$root/$tdir/suites"
fix="wrap the runner this project already has:  wo suite <number> --wrap '<your test command>'   or set SUITE_COMMAND in pipeline.config.sh"

echo "== INTAKE-05 suites — $root"

runnable=0; not_exec=0; absent=0; first=""
if [ -f "$manifest" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue;; esac
    nf="$(printf '%s' "$line" | awk -F'|' '{print NF}')"
    if [ "${nf:-0}" -ge 4 ]; then
      f="$(printf '%s' "$line" | awk -F'|' '{print $3}')"
    elif [ "${nf:-0}" -eq 3 ]; then
      f="$(printf '%s' "$line" | awk -F'|' '{print $2}')"
    else
      continue
    fi
    f="$(printf '%s' "$f" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$f" ] || continue
    p="$suites_dir/$f"
    [ -f "$p" ] || p="$root/$f"
    if [ ! -f "$p" ]; then
      absent=$((absent + 1))
      echo "  note: the manifest lists $f, and no such file exists (the runner reports it as SKIP, never as a pass)"
    elif [ -x "$p" ]; then
      runnable=$((runnable + 1)); [ -n "$first" ] || first="${p#$root/}"
    else
      not_exec=$((not_exec + 1))
      bad "the registered suite ${p#$root/} is not executable, so the runner cannot run it" "run  chmod +x ${p#$root/}"
    fi
  done < "$manifest"
else
  echo "  note: no manifest at ${manifest#$root/}"
fi

cfg_cmd=""
[ -n "${SUITE_COMMAND:-}" ] && cfg_cmd="SUITE_COMMAND"
[ -z "$cfg_cmd" ] && [ -n "${BASELINE_COMMAND:-}" ] && cfg_cmd="BASELINE_COMMAND"

if [ "$runnable" -gt 0 ]; then
  ok "$runnable executable suite(s) registered in ${manifest#$root/}, first: $first"
elif [ -n "$cfg_cmd" ]; then
  ok "no suite registered yet, and $cfg_cmd is set in pipeline.config.sh, so every new suite delegates to the runner this project already has"
else
  bad "no way to produce evidence: no executable suite is registered and neither SUITE_COMMAND nor BASELINE_COMMAND is set" "$fix"
fi

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
