# Behavioral Test Harness

Real requests against a running system, then assertions on the state that
changed. This is what verification evidence means.

## Layout

```
harness/
├── config/test-config.env     one file switches the whole suite between environments
├── config/suites.manifest     tier|file|label — which suites run under --quick / --standard / --full
├── lib/test-helpers.sh        HTTP and SQL assertions for work-order suites
├── lib/verbose-test-framework.sh   richer reporting, user lifecycle helpers
├── runners/run-all-critical-tests.sh   the regression runner, driven by the manifest
├── runners/test-runner.sh     interactive runner
├── scripts/                   run-behavioral-tests, run-test-suite, coverage
├── load/                      k6 capacity harness: smoke, login storm, refresh, flood, blend
└── sql/                       database checks
```

Suites live in the project's `Workspace/Testing/suites/`, one per work order,
named `wo-####-<slug>.sh`.

## Write a suite

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../../.aicodepipeline/harness/config/test-config.env"
source "$(dirname "$0")/../../.aicodepipeline/harness/lib/test-helpers.sh"

assert_http_status "health responds" "$API_BASE/health" 200
assert_sql_contains "row was written" "SELECT status FROM jobs WHERE id=1" "queued"
```

Assert on state, not only on status codes. No hardcoded hosts, ports, or
credentials; everything comes from `test-config.env` and the environment.

## Run and record

```bash
wo verify 0407 --run Workspace/Testing/suites/wo-0407-rate-limit.sh
```

The status is written from the exit code. `EXECUTED — PASS`, `EXECUTED — FAIL`,
or, before any run, `NOT EXECUTED — PLAN ONLY`.

## Regression tiers

Add each suite to `harness/config/suites.manifest` with a tier. The runner
exposes tiers as flags:

```bash
harness/runners/run-all-critical-tests.sh --quick      # essentials
harness/runners/run-all-critical-tests.sh --standard   # full regression
```

## Load

```bash
cd harness/load && k6 run scenarios/smoke.js   # must be green before any load scenario
```

See `harness/load/RUNBOOK.md`.
