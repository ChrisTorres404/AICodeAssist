#!/usr/bin/env bash
# INTAKE-02 — instructions: every agent reads the same file, and it is filled in.
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
wo_rel="${WORKORDERS_DIR:-Workspace/Docs/WorkOrders}"
agents="$root/AGENTS.md"
claude="$root/CLAUDE.md"
install_cmd="$pipeline_root/bin/acp install ."
detect_cmd="$pipeline_root/bin/detect-stack . --write"

echo "== INTAKE-02 instructions — $root"

if [ -f "$agents" ]; then
  ok "AGENTS.md is present ($(wc -l < "$agents" | tr -d ' ') lines)"

  if grep -qF "$wo_rel" "$agents"; then
    ok "AGENTS.md names the configured work-order directory ($wo_rel)"
  else
    bad "AGENTS.md never mentions $wo_rel" "the instructions point at a layout this project does not use: re-run  $install_cmd  or edit AGENTS.md so it names $wo_rel"
  fi

  unresolved="$(grep -o '{{[A-Za-z_][A-Za-z0-9_]*}}' "$agents" 2>/dev/null | sort -u | tr '\n' ' ' || true)"
  if [ -z "$unresolved" ]; then
    ok "AGENTS.md has no unresolved template variables"
  else
    bad "AGENTS.md still carries template variables: $unresolved" "the installer never rendered them: re-run  $install_cmd"
  fi

  # The stack and the test command are what an agent needs to produce evidence; a
  # library has nothing to "run locally", so that line may honestly stay empty.
  if grep -E '^- \*\*(Stack|Run tests):\*\*' "$agents" | grep -qE '_\(fill in\)_|_\(the command\)_|_\(empty project'; then
    bad "the Stack or Run tests line of AGENTS.md is still a placeholder" "fill them in:  $detect_cmd"
  else
    ok "the Stack and Run tests lines of AGENTS.md are filled in"
    grep -E '^- \*\*Run locally:\*\*' "$agents" | grep -qE '_\(the command\)_' && echo "  note: Run locally is still a placeholder; fine for a library, fill it in for a service"
  fi
else
  bad "AGENTS.md is missing" "it is the file every agent reads: re-run  $install_cmd"
  bad "AGENTS.md never mentions $wo_rel" "create it first:  $install_cmd"
  bad "AGENTS.md could not be read for template variables" "create it first:  $install_cmd"
  bad "the Project Specifics section could not be read" "create AGENTS.md first:  $install_cmd  then  $detect_cmd"
fi

if [ -f "$claude" ]; then
  if grep -q '@AGENTS.md' "$claude"; then
    ok "CLAUDE.md imports AGENTS.md, so Claude Code reads the same instructions"
  else
    bad "CLAUDE.md does not import AGENTS.md" "Claude Code and every other agent are reading different instructions: add the line  @AGENTS.md  to CLAUDE.md"
  fi
else
  ok "no CLAUDE.md, so AGENTS.md is the only instruction file"
fi

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
