# Behavioral Test Harness

Real requests against a running system, then assertions on the state that
changed. This is what verification evidence means: a suite that was executed,
with its output kept, stamped `EXECUTED — PASS` or `EXECUTED — FAIL`. Anything
not run is `NOT EXECUTED — PLAN ONLY`, and says so.

Nothing in `harness/` assumes a language, a framework, or a domain. It needs an
HTTP endpoint; a database, a cache, and authentication are each optional and
inert until configured.

## Quick start

Three commands, in the order you will want them.

```bash
harness/runners/run-all-critical-tests.sh --quick   # is the system alive and its core path intact
harness/runners/test-cli.sh                          # the menu, if you would rather not remember flags
wo verify 0407 --run Workspace/Testing/suites/rate-limit.sh   # record one suite as evidence
```

Nothing needs installing and nothing needs configuring first: with no suites
listed yet, the runner says so and exits 0 rather than pretending to pass.

Every runner and script here answers `-h` / `--help` by printing its own file
header, so the authority on a flag is the script, never this page:

```bash
harness/runners/run-all-critical-tests.sh --help
harness/scripts/run-behavioral-tests.sh --help
harness/runners/test-runner.sh --help
harness/runners/test-cli.sh --help
```

Paths on this page use the example configuration — `Workspace/Testing` for the
testing directory, `Workspace/Docs/WorkOrders` for work orders, and
`.aicodepipeline` for the installed pipeline. Substitute whatever
`pipeline.config.sh` sets for this project.

## Layout

```
harness/
├── config/test-config.env     one file switches the whole suite between environments
├── config/local.env           thin wrapper that selects the local environment
├── config/suites.manifest     the seed; the live copy is Workspace/Testing/suites.manifest (project-owned)
├── lib/paths.sh               one resolution of suites, manifest, and results directory
├── lib/test-env.sh            where the service is, whether a database is configured,
│                               and how to put the system back into a known state
├── lib/test-common.sh         one definition of everything more than one library needs
├── lib/test-helpers.sh        HTTP, SQL, and optional auth helpers for suites
├── lib/test-framework.sh      suite scaffolding, summaries, progress
├── lib/verbose-test-framework.sh   full request/response/SQL transcripts
├── lib/nyan-cat-progress.sh   optional progress bar, sourced by the runners when present
├── runners/run-all-critical-tests.sh   the canonical runner, driven by the manifest
├── runners/test-cli.sh        the menu: run, record, inspect, switch environment
├── runners/test-runner.sh     interactive: pick a suite, a tier, or hunt a flake
├── scripts/run-behavioral-tests.sh   the same run, written out as a markdown report
├── scripts/calculate-coverage.js     how much of a verification document was executed
├── load/                      k6 capacity harness (see load/RUNBOOK.md)
├── load/seed-load-users.sh    registers N accounts through the API and writes the k6 fixture
└── sql/rls-check.sql          parameterised Postgres row-level-security check
```

Suites live in the project's `Workspace/Testing/suites/`. The runners find that
directory automatically; `SUITES_DIR` overrides it, and `SUITES_MANIFEST`
overrides which manifest lists them — the two are resolved in `lib/paths.sh`
alongside `TEST_RESULTS_DIR`, so no two scripts can disagree about where a
suite is or where its evidence goes.

`lib/test-env.sh` is the other shared file, and it is sourced rather than run.
It is where the three questions every runner used to answer for itself are
answered once:

| It provides | What it is |
|---|---|
| `health_url` | the first health endpoint that answers 200 — `HEALTH_PATH` under `API_BASE`, then under the bare host |
| `db_configured`, `run_psql` | whether a database is configured at all, and one query against it |
| `release_idle_db_connections`, `recover_db_pool` | release the backends a suite left idle, so the next tier is not failed by the one before it |
| `flush_rate_limiter`, `reset_test_environment` | `REDIS_FLUSH` and `TEST_PREP_SQL`, both inert until configured (`clean_risk_state` is an alias of the reset, not a second implementation) |
| `prepare_test_environment` | the health check, the reset and the pool check, in that order, before a run |
| `TEST_USER_AGENT` | a browser User-Agent by default, so a service that scores clients for risk does not make the harness measure its bot filter |

A suite that needs any of those sources it directly; it is guarded against
being sourced twice.

## Four entry points, and which one to use

There is one runner to reach for and three ways of reaching it differently. All
four read the same manifest, and the canonical runner's flags are the
vocabulary the others speak.

| Entry point | Use it when |
|---|---|
| `runners/run-all-critical-tests.sh` | **the default.** A regression, tier by tier, reported in the terminal |
| `scripts/run-behavioral-tests.sh` | you need the run as a document — a dated markdown report to attach to a closeout |
| `runners/test-cli.sh` | you would rather pick from a menu than remember flags, or you want to switch environment, read an earlier result, or look at the system before running anything |
| `runners/test-runner.sh` | you are working by hand: one suite, one tier, or repeating a suite to catch a flake |

`scripts/calculate-coverage.js` is not a runner. It runs nothing; it reads a
verification document and reports how much of it was actually executed.

A run looks like this — one line per suite while it goes, then the verdict:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TIER: ESSENTIAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PASS  Health & Readiness (2s)
  PASS  Sign-in and session (6s)
  SKIP  Dependency audit (file not found)

╔════════════════════════════════════════════════════════════════════╗
║  FINAL RESULTS
╠════════════════════════════════════════════════════════════════════╣
║  Mode:                 QUICK
║  Duration:             8s
║  Total Suites:         3
║  Passed:               2
║  Failed:               0
║  Skipped:              1
║  Pass Rate:            66%
╠════════════════════════════════════════════════════════════════════╣
║  PASS (1 skipped — missing files)
║
║  Skipped:
║    - Dependency audit
╚════════════════════════════════════════════════════════════════════╝
```

### Exit codes

The runners are meant to stand in a CI step, so the exit code is a contract,
not an afterthought:

| Code | `run-all-critical-tests.sh` | `run-behavioral-tests.sh` |
|---|---|---|
| `0` | every suite that ran passed — including a run where nothing was listed, which says so rather than pretending | the same, and the report was written |
| `1` | at least one suite failed | at least one suite failed; the report still exists |
| `2` | — | the manifest is missing, or an argument was not recognised |

`--list` and `--help` exit 0 without running anything. A skipped suite — listed
in the manifest, file absent — does not fail the run on its own; it is counted
apart from the passes and named in the summary, so a manifest that has drifted
is visible rather than fatal. The canonical runner stops with exit 1 before any
suite runs if the health check says nothing is listening; the report script
records the outage and carries on, because a work order with no evidence at all
is worse than a report that says the service was down.

`test-runner.sh --suite <file>` passes the suite's own exit code back, so it
composes with anything that checks `$?`.

### The menu

```bash
harness/runners/test-cli.sh              # the menu
harness/runners/test-cli.sh --list       # the inventory, then exit
harness/runners/test-cli.sh --status     # service, database, cache, metrics, then exit
harness/runners/test-cli.sh --env DOCKER # select an environment first
harness/runners/test-cli.sh --help       # the usage text, then exit
```

It holds no test list and no endpoint of its own: every suite it offers is a
row in the manifest, every URL and credential comes from `test-config.env`, and
running suites is delegated to the two runners above rather than reimplemented.
What it adds is everything around a run. This is the whole menu — the rest of
this page names these actions rather than their numbers, because the numbers
are the one thing about it that can move:

```
────────────────────────────────────────────────────────────────────
  Run
    1  Quick regression        essential tier
    2  Standard regression     essential + core + extended
    3  Full regression         every tier
    4  Run one tier
    5  Run one type            unit, e2e, api, ui, ...
    6  Run one suite

  Record
    7  Write an evidence report    markdown, for a closeout
    8  Coverage of a verification document
    9  Read an earlier result

  Inspect
   10  Suite inventory         listed, missing, unlisted
   11  System status           service, database, metrics
   12  Show configuration

  Environment
   13  Switch environment      LOCAL_DEV / LOCAL_TEST / DOCKER
   14  Load check              N requests at a chosen concurrency
   15  Clean up test data      needs TEST_CLEANUP_SQL

   [h] help   [0] exit
────────────────────────────────────────────────────────────────────
```

With no terminal to read from it refuses rather than looping, and names the
non-interactive runners instead — so a CI job that invokes it by mistake fails
immediately with a usable message.

The load check is a convenience, not the capacity harness: it reports status
codes, throughput, mean, min, max and p50/p95/p99 for one endpoint. Arrival
rates, thresholds and server-side metrics are `harness/load` with k6.

### Where results go

Everything any of them writes — reports, summaries, per-suite logs — goes to
one directory: `Workspace/Testing/results/`. The installer creates it, and the
drivers exclude it from the source fingerprint that binds evidence to the code
it was produced against. A runner that wrote somewhere else would stale every
recorded PASS the moment it ran. The resolution lives in `lib/paths.sh`;
`TEST_RESULTS_DIR` overrides it.

What lands there, and what each file is for:

| File | Written by | Contents |
|---|---|---|
| `behavioral-test-report_<ts>.md` | `scripts/run-behavioral-tests.sh` | one section per suite: tier, type, command, exit code, duration, the checks it reported, its complete transcript, and a status |
| `summary.txt` | the same run | the one-screen verdict, for a CI step summary or a closeout line |
| `<suite>_<ts>.log` | `test-cli.sh`, `test-runner.sh` | the full output of a single suite that was run by hand |
| `coverage-summary.txt` | `scripts/calculate-coverage.js` | how much of a verification document is backed by execution |

Three statuses, and only three:

| Status | Means |
|---|---|
| `EXECUTED — PASS` | the suite ran and exited 0 |
| `EXECUTED — FAIL` | the suite ran and exited non-zero; the output is in the report |
| `NOT EXECUTED` | it did not run — a listed suite whose file is missing, or a test that was only ever planned |

Nothing is ever stamped PASS that was not executed, which is why a missing
suite file is reported `SKIP` and counted apart from the passes rather than
quietly dropped.

## Configure once

`config/test-config.env` is the single source of truth. `ACTIVE_ENV` selects
`LOCAL_DEV` (default), `LOCAL_TEST`, or `DOCKER`; every value is an
override-friendly default, so exporting a variable in your shell or in CI wins.

```bash
API_BASE   http://localhost:3001/api/v1   # override with API_BASE, or DOCKER_API_BASE for containers
ORIGIN     http://localhost:3000     # override with ORIGIN, or DOCKER_ORIGIN
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
| `TEST_CLEANUP_SQL` | how to remove the data the harness created; run only by the CLI's cleanup action, only after you confirm, and never by a suite or a regression |

A suite that only makes HTTP calls needs none of it.

### Switching environment

`ACTIVE_ENV` is the whole switch. Nothing else changes between a run against
your machine and a run against containers:

```bash
ACTIVE_ENV=DOCKER harness/runners/run-all-critical-tests.sh --standard
export ACTIVE_ENV=LOCAL_TEST            # for a whole shell
harness/runners/test-cli.sh --env DOCKER
```

| Value | Points at |
|---|---|
| `LOCAL_DEV` | the stack you run on your machine (the default) |
| `LOCAL_TEST` | the same stack against a throwaway database (`TEST_DB_NAME`, else `<db>_test`) |
| `DOCKER` | the stack running in containers (`DOCKER_API_BASE`, `DOCKER_ORIGIN`, `DOCKER_DB_PORT` when the published ports differ) |

Anything already exported wins over the file, so one variable can be overridden
without leaving the selected environment. The CLI's **Switch environment**
action clears the previously resolved values before re-reading the
configuration — otherwise a switch would be cosmetic, with the old API base
still in the environment.

## Write a suite

A suite must run for anyone, not only for whoever wrote it. `wo suite <n>`
scaffolds one that starts the service itself when nothing is listening
(`SUITE_START_CMD`, defaulting to the project's run command), stops it on exit,
and creates its own fixtures. A suite that needs data passed in through the
environment passes for its author and fails in the regression tier.


```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/../../.." && pwd; })"
HARNESS="$ROOT/.aicodepipeline/harness"
source "$HARNESS/config/test-config.env"   # API_BASE, ORIGIN, DB_*, AUTH_*
source "$HARNESS/lib/test-helpers.sh"      # assertions, wait_for_server, auth and SQL helpers

assert_http_status "health responds" "$API_BASE/health" 200
assert_sql_contains "row was written" "SELECT status FROM jobs WHERE id=1" "queued"
```

The header finds the repository root with `git rev-parse` and falls back to
walking up from the suite's own location, so a suite works from any working
directory and in a worktree. The pipeline directory is resolved from the
installed path rather than assumed — a project that installed the pipeline
somewhere other than the default still gets a suite that runs.

Assert on state, not only on status codes. No hardcoded hosts, ports, or
credentials: everything comes from `test-config.env` and the environment.

For a transcript of every request, response, and query — the thing you paste
into a closeout — source `lib/verbose-test-framework.sh` instead.

## Run and record

```bash
wo verify 0407 --run Workspace/Testing/suites/rate-limit.sh
```

The status is written from the exit code: `EXECUTED — PASS`, `EXECUTED — FAIL`,
or, before any run, `NOT EXECUTED — PLAN ONLY`.

## Regression tiers

Add each suite to `Workspace/Testing/suites.manifest` as `tier|type|file|label`
(created on install next to your suites and never overwritten; `harness/config/`
edits such as `test-config.env` also survive reinstalls).

**Tier** says how central the suite is — when it runs:

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

**Type** says what kind of test it is, which is a different question. It is
free-form, so a project can name its own; the conventional values are `unit`,
`e2e`, `static`, `backend`, `ui`, `browser`, `api`. A security suite can be a
`static` check or a `browser` one, and an `essential` suite can be either — the
two axes do not collapse into one another.

```
essential|api|health-and-readiness.sh|Health & Readiness
core|ui|signup-form.sh|Signup form renders and submits
security|static|dependency-audit.sh|Dependency audit
```

The older three-field `tier|file|label` line still reads: it simply has no
type, and `--type` never selects it. Nothing needs rewriting to keep working.

```bash
harness/runners/run-all-critical-tests.sh --quick      # essential
harness/runners/run-all-critical-tests.sh --standard   # essential + core + extended
harness/runners/run-all-critical-tests.sh --full       # every tier
harness/runners/run-all-critical-tests.sh --list       # what would run, what is missing,
                                                       # and what is present but unlisted
harness/runners/run-all-critical-tests.sh --tier security
harness/runners/run-all-critical-tests.sh --type unit            # one type, every tier
harness/runners/run-all-critical-tests.sh --tier essential --type unit
harness/runners/run-all-critical-tests.sh --include-unlisted     # and the files no row names
harness/runners/run-all-critical-tests.sh --verbose              # full output from each suite
harness/runners/run-all-critical-tests.sh --stop-fail            # stop at the first failure
harness/runners/run-all-critical-tests.sh --no-prep              # skip environment preparation
harness/runners/run-all-critical-tests.sh --show-config          # print the resolved configuration first
harness/runners/run-all-critical-tests.sh --help                 # this list, from the script itself
```

Three of those have an environment equivalent, so CI can set them once instead
of threading flags through a workflow: `VERBOSE=true` is `--verbose`,
`STOP_ON_FAIL=true` is `--stop-fail`, and `SHOW_CONFIG=true` is
`--show-config`. A flag always wins over the variable. `--stop-fail` matters
for what it does to the suites after the failure: they are recorded
`NOT EXECUTED`, never quietly counted as passes, so a stopped run is still an
honest document.

`--verbose` prints each suite's own output inline instead of collapsing it to a
`PASS`/`FAIL` line — the flag to reach for when a suite fails and the one-line
verdict does not say why. `VERBOSE=true` in the environment is the same thing,
for CI. It composes with every mode and with `--tier`/`--type`.

A listed suite whose file is missing is reported `SKIP`, never counted as a
pass. A suite file that no manifest row names never runs in a regression at
all, which is why `--list` names those too. `--include-unlisted` runs them as a
final `unlisted` tier — useful while a manifest is still being filled in, and
not a substitute for filling it in: the manifest is what a regression is
defined by, and a suite nobody listed is one nobody has decided is evidence.

For the same run written out as an evidence document rather than terminal
output — same manifest, same flags:

```bash
harness/scripts/run-behavioral-tests.sh                       # standard tiers
harness/scripts/run-behavioral-tests.sh --quick --type unit
harness/scripts/run-behavioral-tests.sh --standard --out ./artifacts
harness/scripts/run-behavioral-tests.sh --help
```

It writes `Workspace/Testing/results/behavioral-test-report_<ts>.md` and a
`summary.txt` beside it. `--out DIR` writes both somewhere else — a CI
workspace that is uploaded as an artifact, or a scratch directory while you are
comparing two runs. Use it deliberately: the results directory is the one the
drivers exclude from the source fingerprint, so a report written elsewhere and
then copied back in is evidence whose binding you have to re-establish.

Each suite's section carries the tier, the type, the command, the exit code,
the duration, the per-check verdict lines the suite printed, and then the
complete transcript — not a tail of it. The check that explains a failure is
always the one that would have scrolled off.

## Beyond one regression

A regression answers "does it still work". These are the other questions the
same suites and the same manifest can answer, without a second test list.

### Selecting what runs: by suite, by type, by tier

Three axes, composable, all reading the manifest:

```bash
harness/runners/test-runner.sh                          # menu: pick one suite by number
harness/runners/run-all-critical-tests.sh --type unit   # one type, every tier
harness/runners/run-all-critical-tests.sh --tier security
harness/runners/run-all-critical-tests.sh --tier essential --type unit
```

`test-runner.sh` does the same from a menu — **Run a single suite** and **Run a
tier** — and non-interactively with `--suite <file>`, which takes a path
relative to the suites directory, an absolute path, or a suite number from
`--list`, and passes the suite's own exit code back so it can stand in a script
or a CI step. `test-cli.sh` offers the same three (**Run one tier**, **Run one
type**, **Run one suite**) alongside everything else it does.

### Generations of suites, and running one of them

There is no version field in the manifest, and there does not need to be one:
the **type** field is free-form, so a generation is a type. A project rewriting
its authentication can carry both generations at once and run either:

```
core|auth-v1|login-legacy.sh|Legacy sign-in still works
core|auth-v2|login-token.sh|Token sign-in
security|auth-v2|token-replay.sh|Replayed token is rejected
```

```bash
harness/runners/run-all-critical-tests.sh --type auth-v2   # only the new generation
harness/runners/run-all-critical-tests.sh --type auth-v1   # the compatibility check
harness/runners/run-all-critical-tests.sh --standard       # both, as one regression
```

The `recent` tier is the other half of the same idea: suites for work that is
still settling live there, run in `--full` but not in `--standard`, and are
promoted into `core` when the work stops moving. Between the two, "run only the
new behaviour", "run only the baseline", and "run everything" are all one flag.

### Comparing two generations

A comparison is the same suite run twice with one thing changed, and the two
reports kept. The thing that changes is usually the environment:

```bash
ACTIVE_ENV=LOCAL_DEV harness/scripts/run-behavioral-tests.sh --tier performance
ACTIVE_ENV=DOCKER    harness/scripts/run-behavioral-tests.sh --tier performance
```

Both write a timestamped report into `Workspace/Testing/results/`, so the two sit
beside each other and the difference is `diff`-able. For a before-and-after
across a change rather than across an environment, run the suite on the old
commit first and keep that report: a claimed improvement with no recorded
baseline is a claim, not a measurement.

### Functional and performance from the same suite

Every suite answers two questions depending on how it is run:

| Run it | Question it answers |
|---|---|
| once, through a runner | does it work — `EXECUTED — PASS` or `EXECUTED — FAIL` |
| N times, with `test-runner.sh --suite <file> --repeat N` | is it stable, or does it flake |
| under the load harness | how does it behave at an arrival rate |

`--repeat` runs one suite N times and reports how many of the N passed — the
menu's **Repeat a suite** action is the same thing. A suite that passes 9 times
in 10 is a failing suite with a comfortable story; the repeat is how you find
that out before CI does.

```bash
harness/runners/test-runner.sh --suite rate-limit.sh --repeat 20
```

### Stress, and its sub-modes

Two tools, deliberately separate. The CLI's **Load check** is the quick one: N
requests to one endpoint at a chosen concurrency, reporting status codes,
throughput, mean, min, max, and p50/p95/p99. It needs no fixtures and no k6,
and it is not a capacity test. It asks for a path, a method, a request count
(default 50) and a concurrency (default 5). The script rejects anything that is
not a positive whole number, and the usable range is 1-1000 requests at 1-50 in
flight: past that you are measuring one machine's ability to fork `curl`, not
the service, which is what `harness/load` and k6 exist for.

```
Load check results
  URL:          http://localhost:3001/api/v1/health
  Requests:     50
  Responses:    50
  In flight:    5
  Duration:     3s
  Throughput:   16.7 req/s
  Mean:         41 ms
  Min / Max:    22 ms / 190 ms
  p50/p95/p99:  36 ms / 88 ms / 190 ms

  Status codes
    200  50
```

The capacity harness is `harness/load`, with k6, and its scenarios are the
sub-modes:

| Sub-mode | Scenario | What it puts under load |
|---|---|---|
| Smoke | `scenarios/smoke.js` | the harness itself — must be green before any of the others |
| Steady state | `scenarios/steady-state.js` | a constant arrival rate, held |
| Ramp to breakpoint | `scenarios/ramp-to-breakpoint.js` | rising load until the SLO breaks |
| Flood | `scenarios/rate-limit-flood.js` | excess load — does it shed as 429s rather than 5xx |
| Blend | `scenarios/mixed-blend.js` | every endpoint together; with `SOAK=1`, leaks over time |

Scenarios that need accounts read a fixture file, and
`harness/load/seed-load-users.sh` writes it:

```bash
LOAD_USER_PASSWORD='...' harness/load/seed-load-users.sh 200
```

It registers the accounts through the application's own registration endpoint —
no direct database access and no assumption about the schema — and writes
`fixtures/users.json`. An existing fixture file is left alone unless `FORCE=1`,
so a hand-written one is equally valid; the format is documented in the
script's header. `AUTH_REGISTER_PATH`, `AUTH_EMAIL_FIELD`, `AUTH_PASSWORD_FIELD`
and `LOAD_USER_EXTRA` shape the request body for an API that needs more than an
identifier and a secret. The password comes from the environment and is never
written to the fixture.

### Coverage of a verification document

`scripts/calculate-coverage.js` runs nothing. It reads a verification document
and reports how much of it is backed by an execution rather than a plan:

```bash
node harness/scripts/calculate-coverage.js \
  Workspace/Docs/WorkOrders/WO-0407-<name>/WO-0407-VERIFICATION.md
```

```
Behavioral test coverage: 44.0%
Total: 25 | Passed: 11 | Failed: 0
```

A document at 44% is not a document with a problem; it is a document that is
honest about 14 tests nobody has run yet. Use it before a closeout to see which
they are. It also writes `coverage-summary.txt` into
`Workspace/Testing/results/`, and the CLI's **Coverage of a verification
document** is the same thing from the menu.

### The metrics view

The CLI's **System status** — or `--status` without entering the menu — prints
the state of the system under test before or after a run: whether the service
answers, whether the database is reachable, and two configurable evidence
blocks:

```bash
harness/runners/test-cli.sh --status
```

```
Service
  healthy  http://localhost:3001/health  (HTTP 200)

Database
  connected  app@localhost:5432/my_platform_dev
  idle connections: 2
  DB_STATS_QUERIES is empty — nothing to report as evidence

Cache
  reachable  localhost:6379

Metrics
  API_STAT_METRICS is empty — set it to the metric names worth watching
```

| Setting | Prints |
|---|---|
| `DB_STATS_QUERIES` | `label=SQL` lines, one row of output each — counts that should have moved |
| `API_STAT_METRICS` | named metrics scraped from the application's metrics endpoint |

Both are empty by default and say so rather than pretending to report. Set them
to the handful of numbers that actually mean something for this project —
sessions created, jobs queued, failures counted — and a run's before-and-after
becomes evidence rather than an impression. **Show configuration** prints the
resolved configuration, so you can see which environment those numbers came
from.

### Progress output

`harness/lib/nyan-cat-progress.sh` is an optional progress bar. The runners
source it when it is present and work identically when it is not — it draws a
percentage bar with a rainbow trail as suites complete, and nothing depends on
it. It is sourced with an explicit empty argument so its own demo mode never
sees the runner's arguments. Delete the file if you would rather not have it;
nothing breaks.

```bash
harness/lib/nyan-cat-progress.sh demo    # watch the bar, prove the terminal renders it
```

### Four worked examples

#### Quick smoke, about two minutes

Before pushing.

```bash
harness/runners/run-all-critical-tests.sh --quick
# essential tier only: is the system alive and is its core path intact
```

#### Stress before a deployment, about ten minutes

After the smoke passes.

```bash
harness/load/seed-load-users.sh 200          # once, with LOAD_USER_PASSWORD set
cd harness/load && k6 run scenarios/smoke.js # must be green first
k6 run scenarios/ramp-to-breakpoint.js       # where does it leave the SLO
```

Capture server-side metrics during the run with
`harness/load/capture-server-metrics.sh`; latency alone never names a
bottleneck.

#### Daily regression, about five minutes

Every morning, or on every pull request.

```bash
harness/scripts/run-behavioral-tests.sh --standard
# essential + core + extended, written to Workspace/Testing/results/ as a report
```

#### Performance benchmarking, variable

When a number has to be defended.

```bash
harness/runners/run-all-critical-tests.sh --tier performance --verbose
harness/runners/test-runner.sh --suite <file> --repeat 20   # is the number stable
```

Run it on the baseline first and keep that report. Then run it on the change.
The improvement is the difference between two recorded runs, not a remembered
one.

---

## In CI

The same manifest, the same flags, no separate CI test list. Run the report
script rather than the terminal runner: it fails the job on the same condition
and leaves an artifact behind.

```yaml
- name: Behavioral suites
  env:
    ACTIVE_ENV: LOCAL_DEV
    API_BASE: http://127.0.0.1:8080
  run: .aicodepipeline/harness/scripts/run-behavioral-tests.sh --standard

- name: Keep the evidence
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: behavioral-report
    path: Workspace/Testing/results/
```

Three things make this hold up:

- **Start the system first.** `run-all-critical-tests.sh` polls the health
  endpoint before it claims anything and stops with a message, rather than
  reporting failures that are really a service that was never up. The report
  script does not, so a workflow either waits for the service in the step
  before, or runs suites that start it themselves — which is what `wo suite <n>`
  scaffolds.
- **Pick the tier deliberately.** `--quick` on every push, `--standard` on a
  pull request, `--full` nightly or before a release. A regression nobody waits
  for stops being run.
- **Configure through the environment, not the file.** Every value in
  `test-config.env` yields to an exported one, so the workflow sets `API_BASE`,
  `ACTIVE_ENV` and any credentials as environment or secrets and the file stays
  the local default.

Adding a suite to CI is adding a row to the manifest. Nothing in the workflow
names a suite, so a new one runs in the tier it was filed under without the
pipeline being touched — and `--list` is the check that it really is filed.

## Troubleshooting

**Every suite fails with a connection error.** The service is not up. The
canonical runner polls the health endpoint first and stops with a message
rather than reporting a wall of failures; the report script does not, so a run
that starts with everything red usually means nothing was listening.

```bash
harness/runners/test-cli.sh --status    # is the service answering, is the store reachable
```

Start the service the way this project's `CLAUDE.md` says to, wait for it, and
re-run. A suite scaffolded by `wo suite <n>` starts it itself, which is why
those suites survive CI and hand-written ones often do not.

**A suite fails only on a state assertion.** The database credentials in
`test-config.env` point somewhere the suite cannot read, or `ACTIVE_ENV` is
selecting a different one than you think.

```bash
harness/runners/test-cli.sh            # "Show configuration": the resolved values
harness/runners/run-all-critical-tests.sh --show-config --quick   # the same, before a run
```

Then try the connection the suite is trying, with the values the harness
resolved — if this fails, the suite was never going to pass:

```bash
. harness/config/test-config.env
psql -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U "${DB_USER:-$USER}" \
     -d "$DB_NAME" -t -A -c 'SELECT 1;'
```

Anything exported in the shell wins over the file, so a stale exported
`API_BASE` from an earlier session is a common cause of "it works in the other
terminal".

**A suite passes alone and fails in the regression.** It depends on data a
previous suite left behind, or on data it did not create. Repeat it in
isolation (`test-runner.sh --suite <file> --repeat 5`) and then in the tier, and fix the suite
to create its own fixtures — not the ordering of the manifest.

**A suite is listed but reported `SKIP`.** The file named by the manifest row
does not exist. `--list` shows every row's file and whether it is present, and
also the suite files no row names.

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
