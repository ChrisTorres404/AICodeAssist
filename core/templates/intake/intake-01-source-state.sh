#!/usr/bin/env bash
# INTAKE-01 — source state: the project is under version control, with history.
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

echo "== INTAKE-01 source state — $root"

command -v git >/dev/null 2>&1 || {
  echo "  precondition: git is not on PATH, so nothing about the source state can be established"
  exit 77; }

top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$top" ]; then
  if [ "$top" = "$root" ]; then
    ok "git repository at the project root"
  else
    ok "git repository at $top (the project root $root is tracked inside it)"
  fi

  head=""; head="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || true)"
  if [ -n "$head" ]; then
    dirty="$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    ok "at least one commit on file (HEAD $head, $dirty uncommitted path(s))"
  else
    bad "the repository has no commits" "history is what evidence is bound to: run  git add -A && git commit -m baseline"
  fi

  up="$(git -C "$root" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
  if [ -n "$up" ]; then
    ab="$(git -C "$root" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null | tr '\t' ' ' || true)"
    behind="${ab%% *}"; ahead="${ab##* }"
    if [ -n "$ab" ]; then
      ok "remote: behind ${behind:-?}, ahead ${ahead:-?} of $up"
      [ "${behind:-0}" != 0 ] && echo "  note: the pushed tree is not this tree; decide which one is the project of record before recording evidence about it"
    else
      ok "remote: $up is tracked (the ahead and behind counts could not be read)"
    fi
  elif [ -n "$(git -C "$root" remote 2>/dev/null)" ]; then
    br="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
    ok "remote: configured, but this branch tracks nothing (a remote is recommended, not required)"
    echo "  note: nothing says whether this directory is the project of record — track one with  git push -u origin $br"
  else
    ok "remote: none (a remote is recommended, not required)"
    echo "  note: with no remote, this directory is the only copy of the project of record"
  fi
else
  bad "this is not a git repository" "evidence is bound to a source state, and there is none: run  git init  then  git add -A && git commit -m baseline"
  bad "the repository has no commits" "run  git add -A && git commit -m baseline"
  bad "the remote could not be reported" "create the repository first:  git init && git add -A && git commit -m baseline"
fi

echo "== $pass passed, $fail failed"
[ "$fail" -eq 0 ]
