#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo; B=./.aicodepipeline/bin/bug
BAR="$EVAL_TMP/barrier"

race() { # <n workers> <command...>
  local n="$1"; shift
  rm -f "$BAR"
  local i
  for i in $(seq 1 "$n"); do
    ( while [ ! -f "$BAR" ]; do :; done; "$@" "worker $i" >/dev/null 2>&1 ) &
  done
  sleep 0.4; touch "$BAR"; wait
  rm -f "$BAR"
}

new_wo() { $W new "$1" --size trivial --area docs; }
new_bug() { $B new "$1" --category api; }

race 6 new_wo
folders="$(non_intake_wos | grep -c . || true)"
ids="$(non_intake_wos | sed 's/^WO-\([0-9]*\)-.*/\1/' | sort -u | grep -c . || true)"
[ "$folders" -eq 6 ] || { echo "six concurrent creators produced $folders work orders"; ls Workspace/Docs/WorkOrders; exit 1; }
[ "$ids" -eq 6 ] || { echo "six work orders share only $ids distinct numbers:"; ls Workspace/Docs/WorkOrders; exit 1; }

race 6 new_bug
bfolders="$(ls Workspace/Docs/Bugs 2>/dev/null | grep -c . || true)"
bids="$(ls Workspace/Docs/Bugs 2>/dev/null | sed 's/^BUG-\([0-9]*\)-.*/\1/' | sort -u | grep -c . || true)"
[ "$bfolders" -eq 6 ] || { echo "six concurrent creators produced $bfolders bugs"; ls Workspace/Docs/Bugs; exit 1; }
[ "$bids" -eq 6 ] || { echo "six bugs share only $bids distinct numbers:"; ls Workspace/Docs/Bugs; exit 1; }

# a series is a band, not a prefix: consecutive bugs in one category must not collide
for i in 1 2 3; do $B new "sequential $i" --category database >/dev/null 2>&1; done
dbids="$(ls Workspace/Docs/Bugs | grep -c '^BUG-02' || true)"
[ "$dbids" -eq 3 ] || { echo "three bugs in the database series produced $dbids records"; ls Workspace/Docs/Bugs; exit 1; }

# and a number carried by two folders is refused rather than resolved by picking one
mkdir -p "Workspace/Docs/WorkOrders/WO-0001-duplicate-by-hand"
out="$($W show 0001 2>&1 || true)"
case "$out" in *ambiguous*) ;; *) echo "a duplicated number was not reported as ambiguous: $out"; exit 1;; esac
exit 0
