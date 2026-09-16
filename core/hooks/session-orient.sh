#!/usr/bin/env bash
# session-orient — SessionStart hook.
#
# Opens each session with the state of in-flight work, so a session starts
# oriented instead of asking. Silent when nothing is in flight.
set -euo pipefail

# Resolve the pipeline from this script's own location, then walk up to the
# project root (the directory holding pipeline.config.sh). A hook may be
# invoked from any working directory.
PIPELINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -x "$PIPELINE/bin/wo" ] || exit 0

ROOT="$PIPELINE"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/pipeline.config.sh" ]; do
  ROOT="$(dirname "$ROOT")"
done
[ -f "$ROOT/pipeline.config.sh" ] || exit 0

open="$(cd "$ROOT" && "$PIPELINE/bin/wo" list --active 2>/dev/null | tail -n +2 | head -8 || true)"
[ -z "$open" ] && exit 0

echo "In-flight work orders (SCTPVC = Spec/Checklist/Tasks/Prompt/Verification/Closeout):"
echo "$open" | sed 's/^/  /'
echo
echo "Search prior work before specifying anything new: $PIPELINE/bin/playbook search \"<term>\""
