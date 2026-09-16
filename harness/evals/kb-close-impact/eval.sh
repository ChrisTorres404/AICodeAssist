#!/usr/bin/env bash
set -uo pipefail
. "$(dirname "$0")/../_lib/verification.sh"
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
git config user.email e@x; git config user.name e
W=./.aicodepipeline/bin/wo; A=./.aicodepipeline/bin/acp
mkdir -p src/auth src/billing Workspace/Docs/KnowledgeBase/profiles
printf 'export function login() {}\nexport function logout() {}\n' > src/auth/login.ts
printf 'export function invoice() {}\n' > src/billing/invoice.ts
printf '# Repository analysis\n\nTwo features.\n' > Workspace/Docs/KnowledgeBase/analysis.md
printf '# Auth — Feature Profile\n\nLogin lives here. <!-- SOURCE: src/auth/login.ts:L1 -->\n' > Workspace/Docs/KnowledgeBase/profiles/auth.md
printf '# Billing — Feature Profile\n\nInvoices. <!-- SOURCE: src/billing/invoice.ts:L1 -->\n' > Workspace/Docs/KnowledgeBase/profiles/billing.md
$A kb bind >/dev/null 2>&1 || { echo "kb bind failed"; $A kb bind; exit 1; }
git add -A >/dev/null 2>&1; git commit -q -m "chore: knowledge base" >/dev/null 2>&1
$A kb status >/dev/null 2>&1 || { echo "a freshly bound knowledge base is not current"; $A kb status; exit 1; }
doc="$($A doctor . 2>&1 || true)"; case "$doc" in *"knowledge base: kb: 2 profiles"*) ;; *) echo "doctor does not report the knowledge base"; printf '%s\n' "$doc" | grep -i knowledge; exit 1;; esac

# a work order that changes auth code
n="$($W new "Change login" --size small --area api | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
printf 'export function login(user) {}\nexport function logout() {}\n' > src/auth/login.ts
printf '#!/usr/bin/env bash\necho "1 passed, 0 failed"\n' > ok.sh; chmod +x ok.sh
$W verify "$n" --run ./ok.sh >/dev/null 2>&1; fill_wo "$n"
out="$($W close "$n" 2>&1)" || { echo "close failed under the standard profile"; echo "$out"; exit 1; }
case "$out" in *"profiles/auth.md"*) ;; *) echo "close did not name the profile that describes the changed file"; echo "$out"; exit 1;; esac
case "$out" in *"profiles/billing.md"*) echo "close named a profile that does not describe the change"; exit 1;; esac
c="$(ls Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-CLOSEOUT.md)"
grep -q '## Knowledge Base Impact' "$c" && grep -q 'profiles/auth.md' "$c" || { echo "the closeout does not record the impact"; exit 1; }
# the engine agrees the profile is now stale, and doctor says so
rc=0; $A kb status >/dev/null 2>&1 || rc=$?; [ "$rc" -eq 1 ] || { echo "the changed file did not make its profile stale (exit $rc)"; exit 1; }
doc="$($A doctor . 2>&1 || true)"; case "$doc" in *"1 stale"*) ;; *) echo "doctor does not report the stale profile"; printf '%s\n' "$doc" | grep -i knowledge; exit 1;; esac

# the same rule in the checker, which is what the pre-commit hook and CI run
git add -A >/dev/null 2>&1
out="$($A check --staged 2>&1 || true)"
case "$out" in *"profiles/auth.md"*"update it"*) ;; *) echo "acp check did not report the profile that describes staged changes"; echo "$out"; exit 1;; esac
git commit -q -m "chore: change login" >/dev/null 2>&1 || { echo "an advisory knowledge-base finding blocked a commit"; exit 1; }

# strict refuses to close until the profile is updated and re-bound
m="$($W new "Change invoice" --size small --area api | grep -o 'WO-[0-9]*' | head -1)"; m="${m#WO-}"
printf 'export function invoice(total) {}\n' > src/billing/invoice.ts
$W verify "$m" --run ./ok.sh >/dev/null 2>&1; fill_wo "$m"
rc=0; ACP_STRICT=1 $W close "$m" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "strict closed a work order whose change left a profile stale"; exit 1; }
printf '# Billing — Feature Profile\n\nInvoices take a total. <!-- SOURCE: src/billing/invoice.ts:L1 -->\n' > Workspace/Docs/KnowledgeBase/profiles/billing.md
$A kb bind >/dev/null 2>&1
ACP_STRICT=1 $W close "$m" >/dev/null 2>&1 || { echo "strict still refused after the profile was updated and re-bound"; ACP_STRICT=1 $W close "$m"; exit 1; }
exit 0
