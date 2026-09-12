#!/usr/bin/env bash
set -euo pipefail; cd "$PROJECT"; export PATH="$PWD/.aicodepipeline/bin:$PATH"
wo new "Task priorities" --size small --area backend >/dev/null
d="$(ls -d Workspace/Docs/WorkOrders/WO-0001-*)"
printf '# WO-0001: Task priorities\n\n## Problem Statement\n\nTasks have no priority field.\n\n## Solution\n\nAdd `priority` (low|normal|high, default normal) to POST and PATCH.\n\n## Acceptance Criteria\n\n- [ ] priority accepted and returned\n' > "$d/WO-0001-SPEC.md"
git add -A >/dev/null; git -c user.email=e@x -c user.name=e commit -q -m "WO-0001: spec"
