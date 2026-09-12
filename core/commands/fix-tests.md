---
description: Systematically fix a failing test suite — database-first verification, categorize failures, fix incrementally, measure. Usage: /fix-tests [suite or path]
---

Load the `behavioral-testing` skill, then read
`{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` and the agent
prompt library at `{{PIPELINE_ROOT}}/core/instructions/04-test-fixing-agent-prompts.md`.

Target: **$ARGUMENTS** (if empty, run the critical suite first and start from
its failures).

Delegate investigation in the order the failures demand, per
`core/rules/common/troubleshooting.md`: context first, then active debugging
with `support-engineer-expert`, then infrastructure with
`database-validator-expert`. Investigators return `file:line` findings and do
not edit.

Method, in order:

1. **Assess before touching anything.** Run the suite, capture the output to a
   file as the baseline, and categorize every failure: build or type errors,
   schema mismatches, wrong status codes or response shapes, authentication,
   timeouts, other.
2. **Verify against the real system** before assuming a column, table, field,
   or enum value exists. Never fix a test to match an assumption.
3. **Fix critical blockers first**, then one category at a time. Re-run after
   each fix. Record before and after counts.
4. **Fix the implementation, not the test**, unless the test is provably wrong.
5. **Report** with file:line for every change, the pass-rate delta, what
   remains categorized, and a handoff if the session is ending.

Never report a test as passing without having run it. `NOT EXECUTED — PLAN
ONLY` is an acceptable status; a false PASS is not.
