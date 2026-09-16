#!/usr/bin/env bash
set -uo pipefail

# Nothing Claude-specific may be running for either pass. The variables are
# cleared here rather than per-run so that a leaked one cannot explain a pass.
for v in $(env | sed -n 's/^\(ACP_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$v"; done
[ -z "$(env | grep '^ACP_' || true)" ] || { echo "ACP_* variables survived the unset"; exit 1; }

LABEL=""
fail() { echo "[$LABEL] $*"; exit 1; }
recorded() { [ "$(git rev-parse HEAD)" != "$base" ]; }
rebase_here() { base="$(git rev-parse HEAD)"; }

# The whole sequence, run once with .claude deleted and once with it in place.
# $1 names the run, $2 is 1 when .claude is kept.
sequence() {
  LABEL="$1"; local keep_claude="$2" proj="$EVAL_TMP/$1" remote="$EVAL_TMP/$1-remote.git" out rc
  cd "$EVAL_TMP" || fail "no scratch directory"
  "$PIPELINE_ROOT/bin/new-project" "$1" --name P >/dev/null 2>&1 || fail "scaffold failed"
  cd "$proj" || fail "scaffold produced no directory"
  git config user.email e@x; git config user.name e
  [ "$(git rev-parse --abbrev-ref HEAD)" = main ] || git branch -m main

  if [ "$keep_claude" -eq 0 ]; then
    rm -rf .claude
    git add -A >/dev/null 2>&1; git commit -q -m "chore: remove agent-specific configuration" >/dev/null 2>&1
    [ -e .claude ] && fail ".claude survived deletion"
  else
    [ -d .claude ] || fail "the scaffold left no .claude to keep"
  fi

  # The three git hooks are the whole portable surface; if one is missing the
  # rest of this proves nothing.
  for h in commit-msg pre-commit pre-push; do
    local hp; hp="$(git rev-parse --git-path "hooks/$h")"
    [ -x "$hp" ] || fail "no executable $h hook after scaffolding"
  done

  git init -q --bare "$remote" || fail "could not create the bare remote"
  git remote add origin "$remote" || fail "could not add the remote"
  git push -q origin main >/dev/null 2>&1 || fail "the first push of a shared branch was refused"
  rebase_here

  # --- what must not be committable ----------------------------------------
  mkdir -p src; echo 'const k = "AKIA'ABCDEFGHIJKLMNOP'";' > src/k.ts
  git add -A; git commit -q -m "chore: key" >/dev/null 2>&1
  recorded && fail "a credential in staged source was committed"
  git reset -q >/dev/null 2>&1; rm -rf src

  # creating a configuration is allowed; weakening one is not
  echo '{}' > tsconfig.json; git add tsconfig.json; git commit -q -m "chore: add tsconfig" >/dev/null 2>&1
  recorded || fail "creating a configuration was refused"
  rebase_here
  echo '{"strict": false}' > tsconfig.json; git add tsconfig.json; git commit -q -m "chore: relax tsconfig" >/dev/null 2>&1
  recorded && fail "a modified tsconfig.json was committed"
  git reset -q >/dev/null 2>&1; git checkout -q -- tsconfig.json

  mkdir -p Workspace/Docs/WorkOrders/WO-0042-by-hand
  printf '**Overall status:** EXECUTED — FAIL (x)\n' > Workspace/Docs/WorkOrders/WO-0042-by-hand/WO-0042-VERIFICATION.md
  printf '# Closeout\n' > Workspace/Docs/WorkOrders/WO-0042-by-hand/WO-0042-CLOSEOUT.md
  git add -A; git commit -q -m "chore: closeout" >/dev/null 2>&1
  recorded && fail "a hand-written closeout on a failed verification was committed"
  git reset -q >/dev/null 2>&1; rm -rf Workspace/Docs/WorkOrders/WO-0042-by-hand

  # a citation to a work order nobody opened, by file and inline alike
  echo x > a.txt; git add a.txt
  printf 'WO-9999: never opened\n' > msg.txt
  git commit -q -F msg.txt >/dev/null 2>&1
  recorded && fail "a phantom WO-9999 citation was committed from a message file"
  git commit -q -m "WO-9999: never opened" >/dev/null 2>&1
  recorded && fail "a phantom WO-9999 citation was committed from an inline message"
  git reset -q >/dev/null 2>&1; rm -f a.txt msg.txt

  # --- what reports but does not block, until strict ------------------------
  mkdir -p src
  printf 'export function boot() {\n  console.log("boot");\n}\n' > src/boot.ts
  printf 'export const Badge = () => <span className="bg-red-500">!</span>;\n' > src/Badge.tsx
  git add -A
  out="$(git commit -m "chore: badge" 2>&1)"
  recorded || fail "an advisory finding blocked an ordinary commit: $out"
  case "$out" in *console.log*) ;; *) fail "the commit-time report never mentioned console.log: $out";; esac
  case "$out" in *bg-red-500*) ;; *) fail "the commit-time report never mentioned the hard-coded colour class: $out";; esac
  rebase_here

  printf 'export function again() {\n  console.log("again");\n}\n' > src/again.ts
  printf 'export const Tag = () => <span className="bg-red-500">!</span>;\n' > src/Tag.tsx
  git add -A
  ACP_HOOK_PROFILE=strict git commit -q -m "chore: tag" >/dev/null 2>&1
  recorded && fail "ACP_HOOK_PROFILE=strict let a debug log and a hard-coded colour through"
  ACP_STRICT=1 git commit -q -m "chore: tag" >/dev/null 2>&1
  recorded && fail "ACP_STRICT=1 let a debug log and a hard-coded colour through"
  git reset -q >/dev/null 2>&1; rm -f src/again.ts src/Tag.tsx

  # --- shared history at push time -----------------------------------------
  echo note > note.txt; git add note.txt; git commit -q -m "chore: note" >/dev/null 2>&1
  recorded || fail "a clean commit was refused"
  git push -q origin main >/dev/null 2>&1 || fail "an ordinary push to a shared branch was refused"

  git commit -q --amend -m "chore: note, rewritten" >/dev/null 2>&1 || fail "could not rewrite the last commit"
  rc=0; out="$(git push --force origin main 2>&1)" || rc=$?
  [ "$rc" -eq 0 ] && fail "a force push to main was accepted: $out"
  case "$out" in *ACP_ALLOW_FORCE_PUSH=1*) ;; *) fail "the refusal did not name the way through: $out";; esac
  ACP_ALLOW_FORCE_PUSH=1 git push --force -q origin main >/dev/null 2>&1 || fail "ACP_ALLOW_FORCE_PUSH=1 did not let the force push through"

  rc=0; out="$(git push origin --delete main 2>&1)" || rc=$?
  [ "$rc" -eq 0 ] && fail "the shared branch main was deleted on the remote: $out"
  case "$out" in *"shared branch"*) ;; *) fail "the deletion refusal did not say what it was protecting: $out";; esac
  git ls-remote --heads origin main 2>/dev/null | grep -q 'refs/heads/main' || fail "main is gone from the remote after a refused deletion"

  # a branch only this author touches stays the author's own
  git checkout -q -b feature
  echo f > f.txt; git add f.txt; git commit -q -m "chore: feature" >/dev/null 2>&1
  git push -q origin feature >/dev/null 2>&1 || fail "pushing a feature branch was refused"
  git commit -q --amend -m "chore: feature, rewritten" >/dev/null 2>&1
  git push --force -q origin feature >/dev/null 2>&1 || fail "force-pushing a branch that is not shared was refused"
  git checkout -q main
  return 0
}

sequence without-claude 0
sequence with-claude 1
[ -d "$EVAL_TMP/without-claude/.claude" ] && { echo ".claude came back in the run that deleted it"; exit 1; }
[ -d "$EVAL_TMP/with-claude/.claude" ] || { echo "the control run lost its .claude"; exit 1; }
exit 0
