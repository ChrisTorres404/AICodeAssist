# Load Harness Runbook (WO-50000)

k6-based capacity testing for the {{PROJECT_NAME}} API. Permanent infrastructure — re-run after
every perf fix to measure the gain.

## Prerequisites
- `k6` installed (`brew install k6`)
- Target stack up. **Round 1 = Docker** (`docker compose up -d`; API at :4201, DB at :4232).
- `LOAD_USER_PASSWORD` exported (never committed).
- Load tenants exist: `load-alpha`, `load-bravo` (enterprise), `load-charlie` (free).
  Create via provisioning if missing — the seeder will not auto-create them.

## 1. Seed fixtures (once per environment)
```bash
cd {{TESTING_DIR}}/load
export LOAD_USER_PASSWORD='...'
./seed-load-users.sh          # writes fixtures/users.json (gitignored)
```

## 2. Smoke first — always
```bash
k6 run scenarios/smoke.js
```
Must be green (token acquired, /me 200) before any load scenario. If red, the harness or
stack is misconfigured — fix before proceeding.

## 3. Run a capacity scenario (with server metrics alongside)
```bash
RUN=$(date +%Y%m%d-%H%M%S)-login-storm
./capture-server-metrics.sh "$RUN" 540 &          # background, ~run duration
k6 run --summary-export="results/$RUN/summary.json" scenarios/login-storm.js
wait
```
Repeat for `refresh-steady.js`, `mixed-blend.js`.

## 4. Rate-limit flood (isolation check)
Run a low steady load on an enterprise tenant in one shell, flood charlie in another:
```bash
k6 run scenarios/refresh-steady.js &              # background, enterprise tenants
k6 run scenarios/rate-limit-flood.js              # floods free-tier charlie
```
PASS = flood gets 429s, zero 5xx, and the enterprise run's p99 is unaffected.

## 5. Soak (leak hunt)
```bash
RUN=$(date +%Y%m%d-%H%M%S)-soak
./capture-server-metrics.sh "$RUN" 14400 &
SOAK=1 SOAK_RATE=120 k6 run scenarios/mixed-blend.js
wait
```
Inspect `results/$RUN/server-metrics.csv` for monotonic memory growth or a climbing active-conn
floor (pool leak).

## Reading results
- **Breakpoint** = last ramp stage where `http_req_duration p(99) < 500ms` held and error rate < 1%.
- Cross-reference the timestamp against `server-metrics.csv` to name the bottleneck:
  - active_conns pinned at pool max → **DB pool exhaustion** (raise pool / add PgBouncer)
  - api_cpu near 100%, db_cpu low → **login CPU bound** (add API replicas)
  - db_cpu high, writes climbing → **audit/write amplification** (async audit)
- Fill in `results/<run>/` and the capacity report from `RESULTS-TEMPLATE.md`.

## Round 2 (EC2) — deliberate, off-hours
Set `API_BASE`, `DB_*` to production, and **expect to knock it over** — that's the point.
Coordinate first: production is a single box; the beating is an outage. Never run round 2
against a stack with live pilot users without scheduling it.
