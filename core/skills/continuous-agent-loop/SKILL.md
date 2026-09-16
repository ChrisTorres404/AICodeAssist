---
name: continuous-agent-loop
description: Patterns for continuous autonomous agent loops with quality gates, evals, and recovery controls. Use when running an agent loop that must self-check, gate on evals, and recover from failures.
---

# Continuous Agent Loop

This is the v1.8+ canonical loop skill name. It supersedes `autonomous-loops` while keeping compatibility for one release.

## Loop Selection Flow

```text
Start
  |
  +-- Need strict CI/PR control? -- yes --> continuous-pr
  |
  +-- Need RFC decomposition? -- yes --> rfc-dag
  |
  +-- Need exploratory parallel generation? -- yes --> infinite
  |
  +-- default --> sequential
```

## Combined Pattern

Recommended production stack:
1. RFC decomposition (`work-order` — one work order per deliverable)
2. quality gates (the quality-gate and evidence-gate hooks)
3. eval loop (`eval-harness`)
4. session persistence (`session-handoff`)

## Failure Modes

- loop churn without measurable progress
- repeated retries with same root cause
- merge queue stalls
- cost drift from unbounded escalation

## Recovery

- freeze loop
- run `acp eval run`
- reduce scope to failing unit
- replay with explicit acceptance criteria

## In this pipeline

- Work is a work order: open it with `wo new`, size it honestly, fill the SPEC before code.
- Verification means behavioural tests that **ran**: `wo verify <n> --run <suite>` writes the status from the exit code. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Search the playbooks before building: `playbook search "<problem>"`.
- Route by area: `wo new --area`, `bug new --category`; the routing tables are in `core/rules/common/`.
