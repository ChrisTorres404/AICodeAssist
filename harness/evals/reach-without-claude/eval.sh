#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
rm -rf .claude                                   # nothing Claude-specific is left to load anything
A=./.aicodepipeline/bin/acp
n="$($A commands 2>/dev/null | grep -c . || true)"; [ "$n" -ge 30 ] || { echo "acp commands listed $n commands"; exit 1; }
out="$($A command analyze-repo 2>&1)" || { echo "acp command analyze-repo failed"; exit 1; }
case "$out" in *"read this as your instructions"*"eight phases"*|*"read this as your instructions"*"repo-analysis"*) ;; *) echo "the command did not come back as instructions"; echo "$out" | head -5; exit 1;; esac
case "$out" in *"{{PIPELINE_ROOT}}"*) echo "the command still carries an unrendered path"; exit 1;; esac
n="$($A skills 2>/dev/null | grep -c . || true)"; [ "$n" -ge 150 ] || { echo "acp skills listed $n skills"; exit 1; }
$A skill behavioral-testing 2>/dev/null | grep -q '^name: behavioral-testing' || { echo "acp skill did not print the skill"; exit 1; }
$A agent rest-expert 2>/dev/null | grep -q '^name: rest-expert' || { echo "acp agent did not print the specialist with .claude/ gone"; exit 1; }
rc=0; $A command no-such-command >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 0 ] || { echo "an unknown command was not refused"; exit 1; }
grep -q 'acp commands' AGENTS.md && grep -q 'acp skill' AGENTS.md || { echo "AGENTS.md does not say how to reach commands and skills"; exit 1; }
exit 0
