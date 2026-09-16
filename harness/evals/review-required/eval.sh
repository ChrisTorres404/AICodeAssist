#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo; A=./.aicodepipeline/bin/acp
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh; chmod +x ok.sh

# the specialists are in the work order, with a path any tool can open
n="$($W new "Reviewed" --size standard --area api | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
d="$(ls -d Workspace/Docs/WorkOrders/WO-"$n"-*)"
grep -q '^## Specialists for this work order' "$d/WO-$n-Prompt.md" || { echo "the prompt carries no specialists section"; exit 1; }
grep -q 'openapi-expert' "$d/WO-$n-Prompt.md" || { echo "the validator role is not named in the prompt"; exit 1; }
path="$(sed -n 's/.*Definition: `\([^`]*\)`.*/\1/p' "$d/WO-$n-Prompt.md" | head -1)"
[ -n "$path" ] && [ -f "$path" ] || { echo "the specialist definition path does not resolve: $path"; exit 1; }
$A agent openapi-expert | grep -q '^name: openapi-expert' || { echo "acp agent did not print the specialist"; exit 1; }
$A agents --area api | grep -q 'validate.*openapi-expert' || { echo "acp agents --area did not show the routed validator"; exit 1; }
[ -f "$d/WO-$n-REVIEW.md" ] || { echo "no review document was scaffolded for a standard work order"; exit 1; }

# close refuses while the review is still the template, and again when it is missing
$W verify "$n" --run ./ok.sh >/dev/null 2>&1; fill_wo "$n"
out="$($W close "$n" 2>&1)"; case "$out" in *"still the template"*) ;; *) echo "close did not refuse an unfilled review:"; echo "$out"; exit 1;; esac
rm -f "$d/WO-$n-REVIEW.md"
out="$($W close "$n" 2>&1)"; case "$out" in *"no independent review on file"*) ;; *) echo "close did not refuse a missing review:"; echo "$out"; exit 1;; esac
# a review under the other accepted name, filled in, is enough
printf '# Review\n\nReviewer: someone else. Role: openapi-expert.\n\nFindings: none open. Verdict: APPROVED.\n' > "$d/WO-$n-INDEPENDENT-REVIEW.md"
$W close "$n" >/dev/null 2>&1 || { echo "close refused a filled review under the INDEPENDENT-REVIEW name"; $W close "$n"; exit 1; }

# the documented override says so out loud
m="$($W new "Skipped review" --size standard --area docs | grep -o 'WO-[0-9]*' | head -1)"; m="${m#WO-}"
$W verify "$m" --run ./ok.sh >/dev/null 2>&1; fill_wo "$m"
ACP_SKIP_REVIEW=1 $W close "$m" >/dev/null 2>&1 || { echo "ACP_SKIP_REVIEW=1 did not let a standard work order close"; exit 1; }

# small work orders stay light
s="$($W new "Small" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; s="${s#WO-}"
$W verify "$s" --run ./ok.sh >/dev/null 2>&1; fill_wo "$s"
$W close "$s" >/dev/null 2>&1 || { echo "a small work order was held to the review requirement"; $W close "$s"; exit 1; }
exit 0
