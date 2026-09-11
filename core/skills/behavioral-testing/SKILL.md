---
name: behavioral-testing
description: Write or run behavioral tests that exercise a running system and verify real state. Use when asked to verify a feature works, write a test suite, produce verification evidence for a work order, or investigate why tests fail.
---

# Behavioral Testing

Unit tests prove a function behaves. Behavioral tests prove the **system** does:
a real request against a running service, and then a check that the database,
cache, or downstream state actually changed. Verification evidence for a work
order means the second kind.

## Run

```bash
{{TESTING_DIR}}/../harness/runners/run-all-critical-tests.sh --quick     # essentials
{{TESTING_DIR}}/../harness/runners/run-all-critical-tests.sh --standard  # full regression
```

Environment comes from `harness/config/test-config.env` — one file switches the
whole suite between local, docker, and test databases. Never hardcode a host,
port, or credential in a suite.

## Write

Source the shared framework rather than re-implementing assertions:

```bash
source "$(dirname "$0")/../lib/test-helpers.sh"        # HTTP + SQL assertions
source "$(dirname "$0")/../lib/verbose-test-framework.sh"  # richer reporting, user lifecycle
```

`bin/pack suite "<topic>"` finds an existing suite to model yours on. The
`comprehensive/` suites are the reference implementations.

A suite that only checks HTTP status codes is not a behavioral test. Assert on
the state change too.

## Reporting status honestly

| Status | Means |
|---|---|
| `EXECUTED — PASS` | It ran. You saw it pass. Evidence is attached. |
| `EXECUTED — FAIL` | It ran. It failed. The error is recorded. |
| `NOT EXECUTED — PLAN ONLY` | It has not been run. |

The third status exists so that you never need to use the first one falsely.
A work order closed on a fabricated PASS is worse than one left open.

## Load testing

`harness/load/` is a k6 harness — smoke, login storm, refresh steady state,
rate-limit flood, mixed blend. Always run `scenarios/smoke.js` green before any
load scenario; a red smoke means the harness or the stack is misconfigured and
every number after it is noise. See `harness/load/RUNBOOK.md`.
