---
description: Multi-perspective pull request review — code quality, comments, tests, silent failures, type design, simplification — aggregated and ranked. Usage: /review-pr [number|url] [--focus=code|comments|tests|errors|types|simplify]
---

Target: **$ARGUMENTS** (default: the current branch's PR)

1. `gh pr view` for the diff, files, and description; read the project's `CLAUDE.md` and rules.
2. Run the review roles, in parallel where independent: `code-reviewer`, `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter`, `type-design-analyzer`, `code-simplifier` (report-only). `--focus` narrows to one.
3. Aggregate: deduplicate overlapping findings, rank by severity, keep only findings with a location and a concrete failure scenario.
4. Report grouped by severity with a verdict: approve, changes requested, or blocked. A clean review with zero findings is a valid outcome.
5. If the PR references a work order, confirm its verification is executed; if not, that is the first finding.
