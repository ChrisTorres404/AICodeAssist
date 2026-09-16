#!/usr/bin/env bash
# A verification document has to fit the thing being verified: a bug has a
# reproduction, not a spec, and a UI change is evidenced by what rendered — and
# no template may arrive with a result already in it.
set -uo pipefail
cd "$PIPELINE_ROOT" || { echo "no PIPELINE_ROOT"; exit 1; }

SHARED=core/templates/testing/TEST-TEMPLATE-VERIFICATION.md
BUGV=core/templates/bugs/BUG-TEMPLATE-VERIFICATION.md
UIV=core/templates/testing/TEST-TEMPLATE-VERIFICATION-UI.md
UIC=core/templates/workorders/WO-TEMPLATE-CLOSEOUT-UI.md
BASEC=core/templates/workorders/WO-TEMPLATE-CLOSEOUT.md

fail() { echo "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2"; exit 1; }

# The drivers' own count of prompts a document still carries. Kept identical
# here, because the close gate is what these templates have to survive.
placeholders() {
  awk 'BEGIN{c=0;code=0} /^```/{code=!code;next} code{next} /^## Execution Record/{stop=1} stop{next}
       {n=gsub(/\[[A-Za-z][^]]{2,}\]/,""); c+=n} END{print c}' "$1"
}
absent() { # <file> <label> <pattern...>
  local f="$1" label="$2"; shift 2
  local p
  for p in "$@"; do
    grep -qi -- "$p" "$f" && fail "$f is $label: it still says '$p'"
  done
  return 0
}
present() {
  local f="$1" label="$2"; shift 2
  local p
  for p in "$@"; do
    grep -qi -- "$p" "$f" || fail "$f $label: nothing about '$p'"
  done
  return 0
}
# The drivers append the Execution Record and the Overall status line; a
# template that carries its own would give a document two of each.
no_record() {
  grep -q '^## Execution Record' "$1" && fail "$1 carries its own Execution Record heading"
  grep -q '^\*\*Overall status:\*\*' "$1" && fail "$1 carries its own Overall status line"
  return 0
}

# --- the bug verification template -----------------------------------------
[ -f "$BUGV" ] || fail "no bug verification template: a bug's verification opens as a work order's"
absent "$BUGV" "still written for a work order" 'WO-XXXX' 'Work Order' 'WO spec'
present "$BUGV" "is not about a defect" 'reproduc' 'before the fix' 'after the fix' 'Regression check' 'Root Cause'
no_record "$BUGV"
n="$(placeholders "$BUGV")"
[ "$n" -ge 20 ] || fail "the bug verification template has only $n prompts: the close gate counts them"
[ "$n" -le "$(placeholders "$SHARED")" ] \
  || fail "the bug verification template carries more prompts ($n) than the shared one it replaces"

# --- the UI verification template ------------------------------------------
[ -f "$UIV" ] || fail "no UI verification template: a browser-evidenced work order has nothing to fill in"
absent "$UIV" "still backend-shaped" 'HTTP 200' 'Database record created' 'Database state verified' 'Coverage:'
present "$UIV" "does not describe rendered evidence" \
        'visible' 'keyboard' 'contrast' 'console' 'screenshot' 'route'
no_record "$UIV"
base="$(placeholders "$SHARED")"; n="$(placeholders "$UIV")"
d=$(( n - base )); [ "$d" -lt 0 ] && d=$(( -d ))
[ "$d" -le 10 ] || fail "the UI verification template carries $n prompts against the shared $base: the placeholder budget is no longer comparable"

# --- the UI closeout template ----------------------------------------------
[ -f "$UIC" ] || fail "no UI closeout template"
absent "$UIC" "still backend-shaped" 'Coverage:' 'Database Schema Changes' 'API Endpoints Created' 'Backend Services' 'migration'
present "$UIC" "does not name UI deliverables" \
        '## Deliverables' 'Components' 'Pages and Routes' 'State and Data' 'Styles and Tokens' 'Screenshots'
base="$(placeholders "$BASEC")"; n="$(placeholders "$UIC")"
d=$(( n - base )); [ "$d" -lt 0 ] && d=$(( -d ))
[ "$d" -le 10 ] || fail "the UI closeout template carries $n prompts against the original $base"

# --- the shared template is honest about how the mapping was obtained -------
sec="$(awk '/^## Requirements Traceability/{f=1;next} /^### /{if(f)exit} f' "$SHARED")"
case "$sec" in
  *"per check"*) ;;
  *) fail "the shared verification template does not say that per-check lines are what the driver records" "$sec";;
esac
case "$sec" in
  *"traced from the suite's source"*) ;;
  *) fail "the shared verification template does not say that an unlabelled suite leaves the mapping traced by hand" "$sec";;
esac

# --- no template ships a result nobody produced -----------------------------
# The templates are what an author starts from, and the close gate reads what
# is in them. A row that arrives already saying PASS is a pass no run produced:
# the author fills in the rest of the document around it, the gate counts a
# filled row, and the work order closes on evidence that was typed by the
# template. The same goes for a checkbox that arrives ticked.
#
# Documents only. A suite template under core/templates is a script, and a
# script that prints "PASS" at run time is printing a real result.
#
# A tick is `- [x]`, lower case. `- [X]` is left alone on purpose: the closeout
# templates use [X] as a count placeholder — "- [X] tests passing",
# "Coverage: [X]%" — and those are prompts to fill in, not claims.
prefilled="$(
  find core/templates -type f -name '*.md' | sort | while IFS= read -r f; do
    awk -v F="$f" '
      /^[[:space:]]*```/ { code = !code; next }
      code { next }
      {
        line = $0
        sub(/[[:space:]]+$/, "", line)
        sub(/\|[[:space:]]*$/, "", line)          # a table row ends in a pipe
        sub(/[[:space:]]+$/, "", line)
        if (line ~ /(—|-)[[:space:]]*(EXECUTED[[:space:]]*(—|-)[[:space:]]*)?PASS$/)
          printf "  %s:%d: %s\n", F, FNR, $0
        else if ($0 ~ /^[[:space:]]*[-*][[:space:]]+\[x\]/)
          printf "  %s:%d: %s\n", F, FNR, $0
      }' "$f"
  done
)"
[ -z "$prefilled" ] && exit 0
fail "a template ships a status nobody produced: blank the result, leave the prompt" "$prefilled"
