---
description: Produce a lean, problem-first product requirements document — who, what pain, why now, evidence, hypothesis, MVP, out of scope — and hand off to /plan. Usage: /prd "<idea>"
---

Idea: **$ARGUMENTS** (empty: ask what to build in one sentence)

Four gates, each a single set of questions, each waiting for answers:

1. **Frame**: who has the problem, what is the observable pain, why current options fail, why now.
2. **Ground**: what evidence exists. None is an acceptable answer and is recorded as `Assumption — needs validation via <method>`; never invent plausible requirements.
3. **Decide**: the hypothesis sentence (*we believe X will Y for Z; we will know when W*), the MVP that tests it, what is explicitly out of scope, open questions.
4. **Generate**: write `{{DOCS_DIR}}/prds/<slug>.prd.md` and hand off to `/plan`, which turns milestones into work orders.

A PRD says what must be true and why. The moment it names files or patterns, cut it; that belongs in the plan.
