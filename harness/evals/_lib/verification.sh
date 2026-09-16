#!/usr/bin/env bash
# Shared helper for evaluations. Directories without an eval.sh are not collected
# as evaluations, so this one is only ever sourced.
#
# The close gate refuses a verification document that is still mostly template.
# Evaluations that are testing something else still have to get past it, and the
# honest way is to fill the document the way an author would rather than to set
# the override — that keeps the gate live in every evaluation that closes.
fill_verification() { # <verification file>
  local f="$1"; [ -f "$f" ] || return 0
  awk 'BEGIN{code=0;stop=0}
       /^```/{code=!code}
       !code && !stop {gsub(/\[[A-Za-z][^]]{2,}\]/,"recorded from the run above")}
       /^## Execution Record/{stop=1}
       {print}' "$f" > "$f.filled" && mv "$f.filled" "$f"
}

fill_wo() { # <number> [project root]
  local n="$1" root="${2:-.}" f
  for f in "$root"/Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-VERIFICATION.md; do fill_verification "$f"; done
}

fill_bug() { # <number> [project root]
  local n="$1" root="${2:-.}" f
  for f in "$root"/Workspace/Docs/Bugs/BUG-"$n"-*/BUG-"$n"-VERIFICATION.md; do fill_verification "$f"; done
}

fill_review() { # <number> [project root] — stand in for the reviewer, for evaluations testing something else
  local n="$1" root="${2:-.}" f
  for f in "$root"/Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-REVIEW.md; do fill_verification "$f"; done
}

non_intake_wos() { # [project root] -> the work-order folder names that are not intake steps, one per line
  local root="${1:-.}" d
  for d in "$root"/Workspace/Docs/WorkOrders/WO-*; do
    [ -d "$d" ] || continue
    grep -q '^intake=' "$d/.wo-meta" 2>/dev/null && continue
    basename "$d"
  done
}
