#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"
mkdir -p repo && cd repo && git init -q . && git -c user.email=e@x -c user.name=e commit -q --allow-empty -m init
git worktree add -q ../wt -b wtbranch >/dev/null 2>&1 || { echo "could not create a linked worktree"; exit 1; }
cd ../wt
sed -e 's|^export PROJECT_NAME=.*|export PROJECT_NAME="P"|' -e 's|^export PROJECT_SLUG=.*|export PROJECT_SLUG="p"|' \
    "$PIPELINE_ROOT/pipeline.config.example.sh" > pipeline.config.sh
"$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1 || { echo "install into the linked worktree failed"; exit 1; }
git config user.email e@x; git config user.name e

# git itself says where the hook belongs; that is the only place worth checking
hookpath="$(git rev-parse --git-path hooks/commit-msg)"
[ -f "$hookpath" ] || { echo "no hook where git looks for one ($hookpath)"; exit 1; }
[ -x "$hookpath" ] || { echo "the hook where git looks is not executable"; exit 1; }
# capture first: grep -q closes the pipe early, which under pipefail reports a
# failure that never happened
doc="$(./.aicodepipeline/bin/acp doctor . 2>&1 || true)"
case "$doc" in *"commit-msg hook wired"*) ;; *) echo "doctor did not confirm the hook in a linked worktree"; printf '%s\n' "$doc" | grep -i commit-msg; exit 1;; esac

base="$(git rev-parse HEAD)"; echo x > f.txt; git add f.txt
git commit -q -m "WO-9999: phantom from a linked worktree" >/dev/null 2>&1
[ "$(git rev-parse HEAD)" = "$base" ] || { echo "a phantom citation was recorded from a linked worktree"; exit 1; }

# a configured hooks directory has to be honoured too
mkdir -p ../shared-hooks && git config core.hooksPath ../shared-hooks
"$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1 || { echo "reinstall with core.hooksPath failed"; exit 1; }
hookpath="$(git rev-parse --git-path hooks/commit-msg)"
case "$hookpath" in /*) ;; *) hookpath="./$hookpath";; esac
[ -f "$hookpath" ] || { echo "the configured hooks directory was not honoured ($hookpath)"; exit 1; }
base="$(git rev-parse HEAD)"; echo y > g.txt; git add g.txt
git commit -q -m "WO-9999: phantom with a configured hooks path" >/dev/null 2>&1
[ "$(git rev-parse HEAD)" = "$base" ] || { echo "a phantom citation was recorded with core.hooksPath set"; exit 1; }
exit 0
