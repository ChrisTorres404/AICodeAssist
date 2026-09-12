#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null 2>&1; cd p || { echo "scaffold failed"; exit 1; }
OVERLAY=.aicodepipeline/core/agents/overlays/my-agent.md
HCONF=.aicodepipeline/harness/config/my-harness.conf
mkdir -p "$(dirname "$OVERLAY")" "$(dirname "$HCONF")"
echo "authored overlay" > "$OVERLAY"; echo "authored setting" > "$HCONF"

# a copy that fails, the way a full disk or a vanished source would
FAKE="$EVAL_TMP/fakebin"; mkdir -p "$FAKE"; printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKE/cp"; chmod +x "$FAKE/cp"
rc=0; PATH="$FAKE:$PATH" "$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || { echo "install reported success while its copy was failing"; exit 1; }
[ -f "$OVERLAY" ] || { echo "a failed install destroyed the authored overlay"; exit 1; }
[ -f "$HCONF" ] || { echo "a failed install destroyed the authored harness configuration"; exit 1; }
[ -d .aicodepipeline/core ] || { echo "a failed install left the project with no installed core/"; exit 1; }

# the retry has to put everything back, not merely succeed
"$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1 || { echo "the retry failed"; exit 1; }
[ "$(cat "$OVERLAY" 2>/dev/null)" = "authored overlay" ] || { echo "the retry did not restore the authored overlay"; exit 1; }
[ "$(cat "$HCONF" 2>/dev/null)" = "authored setting" ] || { echo "the retry did not restore the authored harness configuration"; exit 1; }
[ -d .aicodepipeline/.acp-install-recovery ] && { echo "the recovery directory outlived a successful install"; exit 1; }

# and the harder case: the process died after the trees were already removed
mkdir -p .aicodepipeline/.acp-install-recovery/overlays .aicodepipeline/.acp-install-recovery/harness-config
echo "authored overlay" > .aicodepipeline/.acp-install-recovery/overlays/my-agent.md
echo "authored setting" > .aicodepipeline/.acp-install-recovery/harness-config/my-harness.conf
rm -rf .aicodepipeline/core .aicodepipeline/harness
"$PIPELINE_ROOT/bin/install.sh" . >/dev/null 2>&1 || { echo "install could not recover from an interrupted attempt"; exit 1; }
[ "$(cat "$OVERLAY" 2>/dev/null)" = "authored overlay" ] || { echo "recovery did not restore the authored overlay"; exit 1; }
[ "$(cat "$HCONF" 2>/dev/null)" = "authored setting" ] || { echo "recovery did not restore the authored harness configuration"; exit 1; }
exit 0
