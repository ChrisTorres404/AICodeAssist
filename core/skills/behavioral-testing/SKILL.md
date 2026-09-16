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
{{PIPELINE_ROOT}}/harness/runners/run-all-critical-tests.sh --quick     # essential tier
{{PIPELINE_ROOT}}/harness/runners/run-all-critical-tests.sh --standard  # essential + core + extended; --full runs every tier
```

Suites are registered by tier in `{{TESTING_DIR}}/suites.manifest`. Environment comes from `{{PIPELINE_ROOT}}/harness/config/test-config.env` — one file switches the
whole suite between local, docker, and test databases. Never hardcode a host,
port, or credential in a suite.

## Write

Start from a shipped example rather than a blank file:
`{{PIPELINE_ROOT}}/core/templates/testing/examples/crud-with-state-verification.sh` or
`auth-flow.sh`. Each is complete, asserts on actual values, verifies state in the database,
cleans up after itself, and exits 77 when its preconditions are not met.


Source the shared framework rather than re-implementing assertions:

```bash
source "$(dirname "$0")/../lib/test-helpers.sh"        # HTTP + SQL assertions
source "$(dirname "$0")/../lib/verbose-test-framework.sh"  # richer reporting, user lifecycle
```

Both files source `lib/test-common.sh` and `lib/test-env.sh`, where every shared
function (HTTP requests, `run_sql`, assertions, environment reset) is defined once, so
loading both is safe and gives one correct summary.

`bin/playbook suite "<topic>"` finds an existing suite to model yours on. The
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

## Lessons from running suites at scale

- **Comprehensive suites exhaust the connection pool.** Between heavy suites, terminate idle backends for the application and wait a few seconds, or the next suite fails on connections, not logic.
- **Test clients must look like real clients.** Risk scoring blocked a default `curl` user agent and failed every login; set a browser user agent in the config. Logins need tenant context where the API requires it.
- **Know the security policies the tests run under.** An MFA policy of "required for all" cannot be satisfied by automated tests without enrolment; use an optional policy in the test tenant, or enrol in setup.
- **Test both token delivery paths.** Auth changes that moved tokens from body to cookie broke every suite that read the body. Suites cover cookie and body delivery, through one helper that extracts from the cookie jar.
- **Run every related suite, not only the new one.** The archive-table drift was caught by a suite nobody re-ran.
- **Test the failure path.** Suites that only verify success missed cookies left behind after a failed validation.
- **Fixtures created by hand are not fixtures.** Keys, tenants, and users the tests depend on are registered by migration or seed script, never by a manual insert someone forgets to repeat.

## Load testing

`harness/load/` is a k6 harness — smoke, steady state, ramp to breakpoint, rate-limit flood, mixed blend with a soak mode. Always run `scenarios/smoke.js` green before any
load scenario; a red smoke means the harness or the stack is misconfigured and
every number after it is noise. See `harness/load/RUNBOOK.md`.
