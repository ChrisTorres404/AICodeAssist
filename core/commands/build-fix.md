---
description: Get a broken build or type-check green with minimal, safe changes, one error at a time. Usage: /build-fix [path]
---

Delegate to `build-error-resolver`. Scope: **$ARGUMENTS** (default: the whole project).

1. Detect the build system with `{{PIPELINE_ROOT}}/bin/detect-stack .` and run the real build once; collect every error before touching anything.
2. Group by file, fix in dependency order (imports and types before logic), one error per change, re-run after each.
3. Stop and report if a fix creates more errors than it removes, the same error survives three attempts, or the fix needs a design decision; hand design to `orchestrator`.
4. Never suppress: no `@ts-ignore`, `as any`, `eslint-disable`, or `--no-verify`.
5. Report: errors before and after, files changed, lines changed, anything deferred and to whom. Record the green build in the work order's verification.
