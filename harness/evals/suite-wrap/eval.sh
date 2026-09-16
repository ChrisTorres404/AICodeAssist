#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
W=./.aicodepipeline/bin/wo
n="$($W new "Wrapped" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
mkdir -p scripts; printf '#!/usr/bin/env bash\n[ "$1" = "--filter" ] && echo "7 passed, 0 failed" && exit 0\nexit 3\n' > scripts/run.sh; chmod +x scripts/run.sh
$W suite "$n" --wrap 'bash scripts/run.sh --filter {slug}' >/dev/null || { echo "suite --wrap failed"; exit 1; }
s="$(ls Workspace/Testing/suites/wo-"$n"-*.sh)"
grep -q 'bash scripts/run.sh --filter wrapped' "$s" || { echo "the wrapper does not delegate with the placeholders resolved"; cat "$s"; exit 1; }
grep -q 'exit 77' "$s" || { echo "the wrapper does not explain the precondition exit code"; exit 1; }
$W verify "$n" --run "$s" >/dev/null 2>&1 || { echo "the wrapped suite did not pass"; exit 1; }
grep -m1 'Overall status' Workspace/Docs/WorkOrders/WO-"$n"-*/WO-"$n"-VERIFICATION.md | grep -q 'PASS.*checks 7/7' || { echo "the delegated run's result was not recorded"; exit 1; }
# the wrapper runs from the project root wherever it is invoked from
( cd /tmp && bash "$OLDPWD/$s" >/dev/null 2>&1 ) || { echo "the wrapper does not find the project root when run from elsewhere"; exit 1; }
# a configured default makes the wrapper the project's default shape
printf 'export SUITE_COMMAND="bash scripts/run.sh --filter {slug}"\n' >> pipeline.config.sh
m="$($W new "Configured" --size small --area docs | grep -o 'WO-[0-9]*' | head -1)"; m="${m#WO-}"
$W suite "$m" >/dev/null; grep -q 'scripts/run.sh --filter configured' "$(ls Workspace/Testing/suites/wo-"$m"-*.sh)" || { echo "SUITE_COMMAND was not used as the default"; exit 1; }
exit 0
