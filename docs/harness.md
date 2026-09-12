# Behavioral Test Harness

Real requests against a running system, then assertions on the state that
changed. This is what verification evidence means: a suite that was executed,
with its output kept, stamped `EXECUTED — PASS` or `EXECUTED — FAIL`. Anything
not run is `NOT EXECUTED — PLAN ONLY`, and says so.

Nothing in `harness/` assumes a language, a framework, or a domain. It needs an
HTTP endpoint; a database, a cache, and authentication are each optional and
inert until configured.

## Layout

```
harness/
├── config/test-config.env     one file switches the whole suite between environments
├── config/local.env           thin wrapper that selects the local environment
├── config/suites.manifest     the seed; the live copy is {{TESTING_DIR}}/suites.manifest (project-owned)
├── lib/test-helpers.sh        HTTP, SQL, and optional auth helpers for suites
├── lib/test-framework.sh      suite scaffolding, summaries, progress
├── lib/verbose-test-framework.sh   full request/response/SQL transcripts
├── runners/run-all-critical-tests.sh   regression runner, driven by the manifest
├── runners/run-all-tests.sh   runs every suite on disk, listed or not
├── runners/test-runner.sh     interactive runner over the same inventory
├── scripts/run-behavioral-tests.sh   runs the manifest and writes an evidence report
├── scripts/run-test-suite.sh  runs one suite, keeps its output
├── scripts/calculate-coverage.js     how much of a verification document was executed
├── load/                      k6 capacity harness (see load/RUNBOOK.md)
└── sql/rls-check.sql          parameterised Postgres row-level-security check
```

Suites live in the project's `{{TESTING_DIR}}/suites/`. The runners find that
directory automatically; `SUITES_DIR` overrides it.

## Configure once

`config/test-config.env` is the single source of truth. `ACTIVE_ENV` selects
`LOCAL_DEV` (default), `LOCAL_TEST`, or `DOCKER`; every value is an
override-friendly default, so exporting a variable in your shell or in CI wins.

```bash
API_BASE   {{API_BASE_URL}}   # override with API_BASE, or DOCKER_API_BASE for containers
ORIGIN     {{WEB_ORIGIN}}     # override with ORIGIN, or DOCKER_ORIGIN
DB_PORT    5432               # override with DOCKER_DB_PORT for containers
REDIS_PORT 6379
```

Optional blocks, all empty by default and all inert when unset:

| Variable | What it does |
|---|---|
| `AUTH_LOGIN_PATH`, `AUTH_REGISTER_PATH` | endpoints the auth helpers call |
| `AUTH_TOKEN_JQ` | where the token sits in the login response (`.access_token`) |
| `AUTH_EMAIL_FIELD`, `AUTH_PASSWORD_FIELD` | body field names |
| `AUTH_EXTRA_LOGIN_FIELDS` | JSON merged into every login/register body |
| `AUTH_USER_CLEANUP_SQL` | how to delete a user the harness made (`{email}`) |
| `DB_STATS_QUERIES` | `label=SQL` lines printed as evidence in summaries |
| `API_STAT_METRICS` | Prometheus-format metric names printed alongside |
| `REDIS_FLUSH`, `TEST_PREP_SQL` | optional preparation before a batch of suites |

A suite that only makes HTTP calls needs none of it.

## Write a suite

A suite must run for anyone, not only for whoever wrote it. `wo suite <n>`
scaffolds one that starts the service itself when nothing is listening
(`SUITE_START_CMD`, defaulting to the project's run command), stops it on exit,
and creates its own fixtures. A suite that needs data passed in through the
environment passes for its author and fails in the regression tier.


```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../../.aicodepipeline/harness/config/test-config.env"
source "$(dirname "$0")/../../.aicodepipeline/harness/lib/test-helpers.sh"

assert_http_status "health responds" "$API_BASE/health" 200
assert_sql_contains "row was written" "SELECT status FROM jobs WHERE id=1" "queued"
```

Assert on state, not only on status codes. No hardcoded hosts, ports, or
credentials: everything comes from `test-config.env` and the environment.

For a transcript of every request, response, and query — the thing you paste
into a closeout — source `lib/verbose-test-framework.sh` instead.

## Run and record

```bash
wo verify 0407 --run {{TESTING_DIR}}/suites/rate-limit.sh
```

The status is written from the exit code: `EXECUTED — PASS`, `EXECUTED — FAIL`,
or, before any run, `NOT EXECUTED — PLAN ONLY`.

## Regression tiers

Add each suite to `{{TESTING_DIR}}/suites.manifest` as `tier|file|label` (created on
install next to your suites and never overwritten; `harness/config/` edits such as
`test-config.env` also survive reinstalls). The
tiers, in the order the runner uses them:

| Tier | What belongs in it |
|---|---|
| `essential` | the system is alive and its core path works |
| `core` | the everyday regression set |
| `extended` | slower or less central functional suites |
| `security` | authorization, input validation, abuse, hardening |
| `integration` | anything crossing a boundary — third party, queue, webhook |
| `performance` | latency and throughput assertions |
| `infrastructure` | migrations, configuration, deployment shape |
| `recent` | suites for work still settling, promoted later |

```bash
harness/runners/run-all-critical-tests.sh --quick      # essential
harness/runners/run-all-critical-tests.sh --standard   # essential + core + extended
harness/runners/run-all-critical-tests.sh --full       # every tier
harness/runners/run-all-critical-tests.sh --list       # what would run, and what is missing
harness/runners/run-all-critical-tests.sh --tier security
```

A listed suite whose file is missing is reported `SKIP`, never counted as a
pass. For an evidence report in markdown rather than terminal output:

```bash
harness/scripts/run-behavioral-tests.sh          # writes behavioral-test-report_<ts>.md
```

## Load

```bash
cd harness/load
k6 run scenarios/smoke.js        # must be green before any load scenario
```

Scenarios are generic and endpoint-configurable through `LOAD_ENDPOINTS`
(a JSON array of `{method, path, weight, name}`) and `AUTH_MODE` (`none` or
`login`):

| Scenario | Question it answers |
|---|---|
| `smoke.js` | is the harness itself wired up correctly |
| `steady-state.js` | does it hold a constant arrival rate |
| `ramp-to-breakpoint.js` | where does it leave its SLO |
| `rate-limit-flood.js` | does excess load shed as 429s instead of 5xx |
| `mixed-blend.js` | the blended ceiling — and with `SOAK=1`, leaks |

Capture server-side metrics during every run; latency alone never names a
bottleneck. See `harness/load/RUNBOOK.md`.

## Row-level security

```bash
psql -d mydb -v schema=public -v table=documents -v guc=app.current_scope \
  -f harness/sql/rls-check.sql
```

Read-only. Reports whether RLS is enabled and forced, whether policies exist and
reference the GUC, and whether the connecting role bypasses all of it.
