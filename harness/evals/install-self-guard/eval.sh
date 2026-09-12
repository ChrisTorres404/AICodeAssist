#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P --no-git >/dev/null || exit 1
cd p
# 1. the installed copy must never install over itself
rm -f .aicodepipeline/.source
rc=0; ./.aicodepipeline/bin/install.sh "$PWD" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "installed copy installed over itself and exited 0"; exit 1; }
[ -d .aicodepipeline/core/agents ] && [ -d .aicodepipeline/harness/lib ] || { echo "self-install destroyed the pipeline"; exit 1; }
# 2. with the source recorded, it re-runs from the source instead
echo "$PIPELINE_ROOT" > .aicodepipeline/.source
./.aicodepipeline/bin/install.sh "$PWD" >/dev/null 2>&1 || { echo "re-run from recorded source failed"; exit 1; }
[ -d .aicodepipeline/core/agents ] || { echo "re-run lost the pipeline"; exit 1; }
# 3. wo suite scaffolds a runnable suite that fails honestly when nothing is up
n="$(./.aicodepipeline/bin/wo new "Suite check" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; n="${n#WO-}"
./.aicodepipeline/bin/wo suite "$n" >/dev/null || { echo "wo suite failed"; exit 1; }
f="$(ls Workspace/Testing/suites/wo-$n-*.sh)"; bash -n "$f" || { echo "scaffolded suite has a syntax error"; exit 1; }
rc=0; out="$(API_BASE=http://127.0.0.1:1/api/v1 bash "$f" 2>&1)" || rc=$?
[ "$rc" -ne 0 ] || { echo "scaffolded suite exited 0 with no service up"; exit 1; }
case "$out" in *"nothing is listening"*|*"service is not up"*|*"did not become healthy"*) ;; *) echo "scaffolded suite failed for the wrong reason:"; echo "$out" | head -5; exit 1;; esac
# 4. detect-stack --write installs the rule sets the code now needs
mkdir -p src && printf '{"name":"p","scripts":{"test":"vitest"},"dependencies":{"react":"19.0.0"}}' > package.json && echo '{}' > tsconfig.json && echo '{}' > package-lock.json
./.aicodepipeline/bin/detect-stack . --write >/dev/null || { echo "detect-stack --write failed"; exit 1; }
[ -d .claude/rules/typescript ] && [ -d .claude/rules/react ] || { echo "rule sets not installed by --write: $(ls .claude/rules)"; exit 1; }
grep -q "Run tests:\*\* \`npm run test\`" CLAUDE.md || { echo "CLAUDE.md not refreshed"; grep -n "Run tests" CLAUDE.md; exit 1; }
# 5. the test framework exits non-zero from end_test_suite when a test failed
cat > fw.sh <<'EOS'
#!/usr/bin/env bash
source ./.aicodepipeline/harness/config/test-config.env; source ./.aicodepipeline/harness/lib/test-framework.sh
begin_test_suite "fw" >/dev/null 2>&1 || true
FAILED_TESTS=1; PASSED_TESTS=1; TOTAL_TESTS=2
end_test_suite >/dev/null 2>&1
EOS
rc=0; bash fw.sh || rc=$?; [ "$rc" -eq 1 ] || { echo "end_test_suite exited $rc with a failed test"; exit 1; }
exit 0
