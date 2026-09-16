# Behavioral Tests in Continuous Integration

Behavioral testing earns its keep because the evidence is real: a request that
was actually sent, a row that was actually read back. What it costs is
someone's afternoon. Two patterns pay that back — run the suites in the
pipeline, and publish the result somewhere a person can look at without
opening a log.

This document is those two patterns in full: a continuous-integration
workflow that runs the estate on every change and keeps the evidence, and a
results dashboard that reads what the run wrote.

For how a suite is written and what its result is allowed to claim, see
`.aicodepipeline/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`. For how
to work out what the estate covers, see
`.aicodepipeline/core/methodology/TEST-INVENTORY-AND-GAP-ANALYSIS.md`.

---

## The problem these solve

Manual behavioral testing has three specific limitations, and every one of
them is about scale rather than about correctness:

1. **It is not automated.** A person copies commands into a terminal and
   pastes the output back into a document. That works for five tests and
   collapses at fifty.
2. **There is no coverage number.** Nobody can say "eighty-five percent of the
   declared behaviors were exercised," so the conversation stays at "the tests
   passed", which is not the same claim.
3. **It does not scale past about a hundred tests.** Serial manual execution
   of a full estate is a day's work, so it happens before releases and not
   before merges — which is the wrong end.

The fix is an automated harness that keeps the transparency and the evidence.
Not a harness that hides them to go faster.

---

# Part 1 — Running the estate in CI

## What the workflow does

| Property | How |
|---|---|
| Fully automated | It runs on every push and every pull request; nobody has to be asked |
| No human in the loop | The job starts the database, runs the migrations, starts the application, and executes the suites |
| Evidence preserved | The whole results directory is uploaded as a build artifact, so the transcripts outlive the job |
| Feedback where the change is | The summary is posted back onto the pull request as a comment |
| Catches drift overnight | A scheduled run finds the breakages that come from the outside world rather than from a commit |

## The workflow

`.github/workflows/behavioral-tests.yml`

```yaml
name: Behavioral Tests

on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 2 * * *'   # nightly, to catch drift that no commit caused

jobs:
  behavioral-tests:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          # Throwaway: this container exists for the life of the job and is
          # not reachable from outside it. Never reuse these values anywhere.
          POSTGRES_DB: myapp_dev
          POSTGRES_USER: ci
          POSTGRES_PASSWORD: ci
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      API_BASE_URL: http://localhost:3001
      DATABASE_URL: postgresql://ci:ci@localhost:5432/myapp_dev

    steps:
      - uses: actions/checkout@v4

      - name: Set up the runtime
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: npm

      - name: Install dependencies
        run: |
          cd apps/api
          npm ci

      - name: Run migrations
        run: |
          cd apps/api
          npm run migration:run

      - name: Start the application
        run: |
          cd apps/api
          npm run start:dev &

      - name: Wait for it to answer
        run: |
          source .aicodepipeline/harness/lib/test-helpers.sh
          wait_for_server "$API_BASE_URL/health" 60

      - name: Run the behavioral suites
        run: |
          chmod +x .aicodepipeline/harness/scripts/run-behavioral-tests.sh
          .aicodepipeline/harness/scripts/run-behavioral-tests.sh

      - name: Upload the evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: behavioral-test-report
          path: Workspace/Testing/results/
          retention-days: 90

      - name: Comment on the pull request
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('Workspace/Testing/results/summary.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Behavioral Test Results\n\n\`\`\`\n${report}\n\`\`\``
            });
```

## Reading the workflow, step by step

**The service container.** The database is a real PostgreSQL, not a stub. That
is the whole point: a behavioral suite that runs against a substitute data
layer has proven the substitute. The health check matters more than it looks —
without it the migration step starts before the socket is listening and the
job fails in a way that reads as a test failure.

**Migrations before the application.** The application will start against an
empty schema and then fail every suite with a confusing error. Running the
migrations first turns "everything is broken" into "the migration is broken",
which is the same information at a tenth of the debugging cost.

**Starting the application in the background.** `&` detaches it; nothing yet
guarantees it is listening. The wait step is not optional. A fixed `sleep 10`
works most of the time, which is exactly what makes it a bad choice — it fails
on the slow runs, and slow runs correlate with the changes you most want
tested.

`wait_for_server` lives in `.aicodepipeline/harness/lib/test-helpers.sh`
and polls once a second up to the limit it is given. If you would rather not
source the helpers in the job, this is the same thing inline:

```bash
for i in $(seq 1 60); do
  curl -sf "$API_BASE_URL/health" >/dev/null && break
  sleep 1
done
curl -sf "$API_BASE_URL/health" >/dev/null || { echo "application never answered"; exit 1; }
```

**The runner's exit code is the number of failures.** That is what makes the
job pass or fail without any extra plumbing: zero failures exits zero.

**`if: always()` on the upload.** The evidence from a failed run is the
evidence you actually need. Uploading only on success is a way of keeping the
transcripts you were never going to read.

**Retention.** A CI run whose output is discarded proves nothing a week later,
which is when someone asks. Ninety days is a reasonable floor; match it to how
long your release cycle is.

## What the pull request comment looks like

```
## Behavioral Test Results

Total:    25
Passed:   24
Failed:   1
Coverage: 96%

FAILED
  4.2  Replay detection after the grace window
       expected 401, got 200
       Workspace/Testing/results/behavioral-test-report_20240115_021304.md

Report: Workspace/Testing/results/behavioral-test-report_20240115_021304.md
```

The failing test names its own evidence file. A reviewer who wants the request
and response opens the artifact; a reviewer who just wants to know whether to
look reads four lines.

## The summary file the comment reads

The workflow reads `summary.txt`, so the runner has to write it. If your
runner does not, this is the whole of it:

```bash
# Append to the end of the run, after the counters are final
cat > "Workspace/Testing/results/summary.txt" <<EOF
Total:    $TOTAL_TESTS
Passed:   $PASSED_TESTS
Failed:   $FAILED_TESTS
Coverage: $COVERAGE_PCT%

$( [ "$FAILED_TESTS" -eq 0 ] && echo "ALL TESTS PASSED" || printf 'FAILED\n%s\n' "$FAILURE_LINES" )

Report: $REPORT_FILE
EOF
```

`.aicodepipeline/harness/scripts/run-behavioral-tests.sh` already writes the
dated markdown report; `summary.txt` is the short form of the same numbers,
written beside it.

## Variations worth having

### Run the tiers separately

The manifest already carries a tier per suite. Splitting the job by tier gives
faster feedback on the part that matters and keeps the slow part off the
critical path.

```yaml
    strategy:
      fail-fast: false
      matrix:
        tier: [essential, core, security]

    steps:
      # ...
      - name: Run the ${{ matrix.tier }} tier
        run: .aicodepipeline/harness/runners/run-all-critical-tests.sh --tier ${{ matrix.tier }}
```

`fail-fast: false` is deliberate. Cancelling the security tier because the
core tier failed throws away the result you would most want to see.

### Run the suites in parallel within one job

Independent suites do not need to be serial. Four suites in parallel is four
times faster, and the only requirement is that they do not contend for the
same fixture rows.

```bash
#!/usr/bin/env bash
# Parallel execution of independent suites
set -uo pipefail

run_suite() {
  local suite="$1"
  local out="Workspace/Testing/results/${suite}_$(date +%s).md"
  bash "Workspace/Testing/suites/${suite}.sh" > "$out" 2>&1
  echo "$? $suite"
}

run_suite auth-flows  &
run_suite rotation    &
run_suite lockout     &
run_suite cleanup     &
wait

cat Workspace/Testing/results/*.md > Workspace/Testing/results/combined-report.md
echo "All suites complete. Report: Workspace/Testing/results/combined-report.md"
```

Suites that create and delete the same account, or that assert on a global
count, are not independent. Give each parallel suite its own tenant or its own
email prefix, or run it serially and say why in the manifest.

### A manual gate for the changes that can hurt

Not everything should be waved through by a green job. For authentication,
authorization, payments and anything irreversible, the pipeline stops and a
person runs the suites and records the result.

```yaml
jobs:
  deploy:
    steps:
      - name: Wait for behavioral verification
        uses: trstringer/manual-approval@v1
        with:
          instructions: |
            Run the behavioral suites from:
              Workspace/Docs/WorkOrders/WO-NNNN-<name>/WO-NNNN-VERIFICATION.md
            Record the results in that document, then approve.
```

The two arrangements coexist: scripted for everything, plus a gate on the
paths where being wrong is expensive.

### Fail the job on a coverage regression

```yaml
      - name: Check verification coverage
        run: |
          node .aicodepipeline/harness/scripts/calculate-coverage.js \
            Workspace/Docs/WorkOrders/WO-NNNN-<name>/WO-NNNN-VERIFICATION.md
```

That script exits non-zero when any test in the document recorded
`EXECUTED — FAIL`, and prints the breakdown:

```
Behavioral Test Coverage Report
========================================

Total Tests:      25
Executed:         10 (40.0%)
Passed:           10
Failed:           0
Not Executed:     15

Execution Rate:   40.0%
Pass Rate:        100% (of executed)

Overall: GOOD
```

Two numbers, not one. A pass rate of 100% over 40% of the document is not the
same claim as a pass rate of 100%, and a report that prints only the second is
the report that gets misread.

## What CI does not fix

A green pipeline is not production readiness. It says the suites that exist
passed against the environment CI builds. It says nothing about the behaviors
nobody wrote a suite for, and nothing about whether the CI environment
resembles production. Keep the gap analysis separate and keep it current.

---

# Part 2 — The results dashboard

## What it is for

A dashboard is not a report. Its job is to answer "is it green right now?"
from across a room, and to make the live metrics visible next to the test
result so a failure and a spike in error rate can be seen as the same event.

It is static HTML. It reads a JSON file the run wrote and, optionally, a
metrics endpoint. There is no build step and no server-side code, because
anything more elaborate becomes a thing to maintain instead of a thing that
tells you something.

## The dashboard

`Workspace/Testing/dashboard/index.html`

```html
<!DOCTYPE html>
<html>
<head>
  <title>Behavioral Test Dashboard</title>
  <meta http-equiv="refresh" content="10">
  <style>
    body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px; }
    .pass    { color: #4ec9b0; }
    .fail    { color: #f48771; }
    .pending { color: #dcdcaa; }
    .metric  { background: #2d2d2d; padding: 10px; margin: 10px 0; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>Behavioral Test Dashboard</h1>
  <div id="summary"></div>
  <div id="tests"></div>
  <div id="metrics"></div>

  <script>
    // Where the run publishes its results. A relative path when the dashboard
    // is served from the results directory; an absolute URL when it is served
    // by the application.
    const RESULTS_URL = './latest.json';
    const METRICS_URL = '/metrics/json';
    const METRIC_PREFIX = 'auth_';

    // The run summary and the per-test list
    fetch(RESULTS_URL)
      .then(r => r.json())
      .then(data => {
        document.getElementById('summary').innerHTML = `
          <div class="metric">
            <h2>Coverage: ${data.coverage}%</h2>
            <p>Passed: ${data.passed}/${data.total}</p>
            <p>Failed: ${data.failed}</p>
            <p>Run: ${data.generated_at}</p>
          </div>
        `;

        const tests = data.tests.map(t => `
          <div class="metric ${t.status}">
            <strong>${t.id}:</strong> ${t.name}
            <span class="${t.status}">${t.status}</span>
          </div>
        `).join('');

        document.getElementById('tests').innerHTML = tests;
      })
      .catch(e => {
        document.getElementById('summary').innerHTML =
          `<div class="metric fail">No results published yet (${e.message})</div>`;
      });

    // The live metrics, beside the test result
    fetch(METRICS_URL)
      .then(r => r.json())
      .then(metrics => {
        const selected = metrics.filter(m => m.name.startsWith(METRIC_PREFIX));
        const html = selected.map(m => `
          <div class="metric">
            <strong>${m.name}:</strong> ${JSON.stringify(m.values[0]?.value ?? 0)}
          </div>
        `).join('');

        document.getElementById('metrics').innerHTML = '<h2>Live Metrics</h2>' + html;
      })
      .catch(() => { /* metrics are optional; a dashboard without them is still useful */ });
  </script>
</body>
</html>
```

Three details that are load-bearing:

- **`<meta http-equiv="refresh" content="10">`** is the entire update
  mechanism. No websocket, no polling loop, no state to get wrong. The page
  reloads every ten seconds and re-reads the file.
- **The status string is also the CSS class.** `pass`, `fail`, `pending` are
  both the value in the JSON and the class name, so adding a status is a
  one-line change in two places rather than a mapping table.
- **Both fetches catch.** A dashboard that throws on a missing file shows a
  blank page, which reads as "everything is fine".

## The JSON the dashboard reads

`Workspace/Testing/results/latest.json`

```json
{
  "generated_at": "2024-01-15T02:13:04Z",
  "suite": "core",
  "total": 25,
  "passed": 24,
  "failed": 1,
  "coverage": 96,
  "report": "behavioral-test-report_20240115_021304.md",
  "tests": [
    { "id": "1.1", "name": "Account registration",                  "status": "pass" },
    { "id": "2.1", "name": "Token rotation on refresh",             "status": "pass" },
    { "id": "3.1", "name": "Metrics endpoint answers",              "status": "pass" },
    { "id": "4.1", "name": "Dual hash written to the session row",  "status": "pass" },
    { "id": "4.2", "name": "Replay detection after the grace window","status": "fail" },
    { "id": "5.1", "name": "Account lockout after the threshold",   "status": "pending" }
  ]
}
```

`pending` is the dashboard's rendering of `NOT EXECUTED — PLAN ONLY`. The
dashboard shortens the five statuses to three colors; the report keeps all
five. Do not let the shortening travel back up into the report.

## Publishing the JSON from a run

The run already knows every number in that file. This writes it:

```bash
#!/usr/bin/env bash
# publish-results — write the dashboard's JSON from a completed run
set -euo pipefail

RESULTS="Workspace/Testing/results"
REPORT="${1:?usage: publish-results <report-file>}"

# Each result line in the report looks like:  Test 4.2: FAIL — <name>
tests=$(grep -oE '^Test [0-9.]+: (PASS|FAIL|NOT EXECUTED)[^|]*' "$REPORT" \
  | awk '{
      id = $2; sub(/:$/, "", id);
      status = $3;
      name = $0; sub(/^Test [0-9.]+: [A-Z ]+ — /, "", name);
      s = (status == "PASS" ? "pass" : (status == "FAIL" ? "fail" : "pending"));
      printf "%s{\"id\":\"%s\",\"name\":\"%s\",\"status\":\"%s\"}", (NR>1 ? ",\n    " : ""), id, name, s;
    }')

total=$(grep -c '^Test ' "$REPORT")
passed=$(grep -c '^Test [0-9.]*: PASS' "$REPORT" || true)
failed=$(grep -c '^Test [0-9.]*: FAIL' "$REPORT" || true)
coverage=$(( total > 0 ? passed * 100 / total : 0 ))

cat > "$RESULTS/latest.json" <<EOF
{
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "suite": "${SUITE_NAME:-all}",
  "total": $total,
  "passed": $passed,
  "failed": $failed,
  "coverage": $coverage,
  "report": "$(basename "$REPORT")",
  "tests": [
    $tests
  ]
}
EOF

echo "Published: $RESULTS/latest.json"
```

Call it as the last step of the run, and as the last step of the CI job so the
published page reflects CI and not only the last local run.

## Serving it

```bash
# Locally: anything that serves a directory
cd Workspace/Testing/results && python3 -m http.server 8080
# then open http://localhost:8080/../dashboard/index.html

# Simpler: keep the page in the results directory so the relative path resolves
cp Workspace/Testing/dashboard/index.html Workspace/Testing/results/
cd Workspace/Testing/results && python3 -m http.server 8080
# then open http://localhost:8080/index.html
```

Served from the application, mount the results directory as static content and
point `RESULTS_URL` at it. Two constraints, both of which have been learned
the expensive way:

- **Never expose it unauthenticated on anything reachable from outside.** The
  transcripts contain request bodies, and request bodies contain whatever the
  suites sent.
- **Never let it write.** It is a reader. Anything that lets a page mark a test
  as passed has just become a way to record a pass that never happened.

## Publishing it from CI

```yaml
      - name: Publish the dashboard payload
        if: always()
        run: |
          Workspace/Testing/publish-results.sh \
            "$(ls -1t Workspace/Testing/results/behavioral-test-report_*.md | head -1)"

      - name: Upload the dashboard
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: behavioral-test-dashboard
          path: |
            Workspace/Testing/dashboard/index.html
            Workspace/Testing/results/latest.json
```

Downloading that artifact and opening the page gives the same view of the CI
run that the local dashboard gives of a local run.

---

## Checklist

- [ ] The workflow runs on pull requests, not only on the default branch
- [ ] A real database service is used, not a substitute data layer
- [ ] Migrations run before the application starts
- [ ] The job waits for the application to answer instead of sleeping a fixed interval
- [ ] The runner's exit code is the failure count, so the job status is meaningful
- [ ] Results are uploaded with `if: always()`, so failures keep their evidence
- [ ] Artifact retention is at least as long as one release cycle
- [ ] The pull request comment names the report file for each failure
- [ ] Irreversible or security-sensitive changes have a manual gate, not only the scripted run
- [ ] The nightly scheduled run exists, to catch drift no commit caused
- [ ] `latest.json` is published by the run, not hand-written
- [ ] The dashboard is read-only and not reachable unauthenticated
- [ ] The dashboard's three colors are documented as a shortening of the five statuses

---

## Related

- `.aicodepipeline/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` — what a suite must contain and the five execution statuses
- `.aicodepipeline/core/methodology/TEST-INVENTORY-AND-GAP-ANALYSIS.md` — deriving the feature catalogue and ranking what is untested
- `.aicodepipeline/docs/harness.md` — the runners, the manifest, and the shared helpers
- `.aicodepipeline/harness/scripts/run-behavioral-tests.sh` — the run that writes the dated markdown report
- `.aicodepipeline/harness/scripts/calculate-coverage.js` — how much of a verification document was actually executed
