---
description: Restate requirements, ground the plan in the codebase, assess risks, and produce the work order's SPEC and TASK-BREAKDOWN. Waits for confirmation before any code. Usage: /plan "<feature>" | /plan WO-####
---

Delegate to `planner`. Input: **$ARGUMENTS**

1. If a work order number is given, plan into its folder; otherwise open one: `{{PIPELINE_ROOT}}/bin/wo new "<title>" --size <honest size> --area <area>`.
2. Search precedent first: `{{PIPELINE_ROOT}}/bin/pack search "<problem>"`. If a prior work order covers it, start from its SPEC.
3. Ground the plan in the codebase before writing it: naming, error handling, logging, data access, and test conventions in the affected area, each with a file reference. If nothing similar exists, say so; do not invent a pattern.
4. Write the SPEC (problem, current state, solution, file-by-file changes, acceptance criteria, cross-cutting checks) and the TASK-BREAKDOWN (phases, dependencies, risk per step, estimate).
5. State the size and the routing you chose. **Stop and wait for confirmation.** No code until the plan is approved.
