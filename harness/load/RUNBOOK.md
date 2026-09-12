# Load Harness Runbook

k6-based capacity testing for any HTTP service. Permanent infrastructure, not a
one-off: re-run it after every performance fix so the gain is measured rather
than asserted.

The method is the point. Ramp the **offered load** (arrival rate), watch latency
and errors, find the last stage that held the SLO, then name the bottleneck from
server-side metrics captured during the same window. A number without a named
bottleneck is not a result.

## Prerequisites

- `k6` installed, and `jq` if you use the seeder.
- The target stack running, and `API_BASE` pointing at it.
- The endpoint mix configured — see below. The default is a single `GET /health`,
  which proves the harness works but tells you nothing about your application.
- For authenticated runs: `AUTH_MODE=login`, `LOAD_USER_PASSWORD` exported
  (never committed), and `fixtures/users.json` present.

## Configure the endpoint mix

```bash
export API_BASE="http://localhost:3001/api/v1"
export LOAD_ENDPOINTS='[
  {"method":"GET",  "path":"/items?limit=20", "weight":70, "name":"list"},
  {"method":"GET",  "path":"/items/1",        "weight":20, "name":"detail"},
  {"method":"POST", "path":"/items",          "weight":10, "name":"create",
   "body":{"title":"load"}}
]'
```

Weights are relative. Each entry's `name` tags its requests, so thresholds and
the summary can address one endpoint at a time.

Unauthenticated runs need nothing else. For authenticated runs:

```bash
export AUTH_MODE=login
export AUTH_LOGIN_PATH=/auth/login        # default
export AUTH_TOKEN_JQ=.access_token        # dot-path to the token in the response
export LOAD_USER_PASSWORD='...'
```

## 1. Seed fixtures (authenticated runs only, once per environment)

```bash
cd {{TESTING_DIR}}/../harness/load
LOAD_USER_PASSWORD='...' ./seed-load-users.sh 200   # writes fixtures/users.json (gitignored)
```

The seeder only calls the API's registration endpoint. A hand-written
`fixtures/users.json` is equally valid — accounts created any other way work as
long as the file lists them.

## 2. Smoke first — always

```bash
k6 run scenarios/smoke.js
```

Every configured endpoint is called once per iteration, so a wrong path or a
broken login shows up here in one minute rather than halfway through a capacity
run. If smoke is red, the harness or the stack is misconfigured; fix that before
reading any other number.

## 3. Baseline: steady state

```bash
RUN=$(date +%Y%m%d-%H%M%S)-steady
./capture-server-metrics.sh "$RUN" 660 &
RATE=50 DURATION=10m k6 run --summary-export="results/$RUN/summary.json" scenarios/steady-state.js
wait
```

A constant arrival rate holds the offered load fixed while the system's latency
moves — the honest unit for "can it carry this much".

## 4. Find the breakpoint

```bash
RUN=$(date +%Y%m%d-%H%M%S)-ramp
./capture-server-metrics.sh "$RUN" 660 &
START_RATE=10 PEAK_RATE=200 STAGES=5 STAGE_DURATION=2m \
  k6 run --summary-export="results/$RUN/summary.json" scenarios/ramp-to-breakpoint.js
wait
```

Thresholds here do not abort the run: let the ramp continue past the knee so the
shape of the failure is visible.

**Breakpoint** = the last stage where `http_req_duration p(99)` stayed under your
SLO and the error rate stayed under 1%.

Then run `mixed-blend.js` for the blended picture across the whole endpoint mix.

## 5. Rate-limit flood (stability, not capacity)

```bash
RATE=20 DURATION=3m k6 run scenarios/steady-state.js &   # well-behaved traffic
FLOOD_RATE=500 FLOOD_PATH=/items k6 run scenarios/rate-limit-flood.js
```

PASS = the flood is answered with 429s and no 5xx, and the steady run's p99 is
unaffected. A limiter that turns excess load into server errors, or that drags
down unrelated traffic, has failed this test.

## 6. Soak (leak hunt)

```bash
RUN=$(date +%Y%m%d-%H%M%S)-soak
./capture-server-metrics.sh "$RUN" 14400 &
SOAK=1 SOAK_RATE=120 SOAK_DURATION=4h k6 run scenarios/mixed-blend.js
wait
```

Inspect `results/$RUN/server-metrics.csv` for memory that only climbs, or a
connection floor that never returns to where it started (a pool leak).

## Reading results

Cross-reference the breakpoint timestamp against `server-metrics.csv`:

- connections pinned at the pool maximum → **pool exhaustion** (raise the pool,
  or put a connection pooler in front of the database)
- application CPU near 100% while the database is idle → **application CPU bound**
  (add replicas, or make the hot path cheaper)
- database CPU high and writes climbing → **write amplification** (batch, defer,
  or make the writes asynchronous)

Record the run in a report built from `RESULTS-TEMPLATE.md`, and keep
`results/<run>/summary.json` beside it as the evidence.

## Capturing server-side metrics

```bash
API_CONTAINER=my-api DB_CONTAINER=my-db DB_NAME=my_db ./capture-server-metrics.sh "$RUN" 660
```

Anything not configured is recorded as `NA` rather than guessed at.

## A second round against a shared environment

Running this against a shared or production-like environment is a deliberate act:
expect to degrade it, because that is the point. Schedule it, tell whoever else
uses that environment, and never do it while real users depend on it.
