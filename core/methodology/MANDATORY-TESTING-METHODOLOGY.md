# Mandatory Behavioral Testing Methodology

> This is non-negotiable. Every agent working on {{PROJECT_NAME}} follows it.

The long form of `{{PIPELINE_ROOT}}/core/rules/common/testing.md`. That file
states the rule; this one explains it, shows the shapes, and lists what a
suite has to contain before it counts.

---

## Core Rule

**Every test suite offered as verification must exercise real system behavior
through actual execution — not mocked responses.**

Unit tests cover isolated logic. Behavioral tests verify that the running
system does what was claimed and that the state actually changed. They are not
interchangeable, and only the second kind is verification evidence.

---

## What Behavioral Testing Is

Behavioral testing validates software through **real execution** against a
**live system** — the running application and its real data store — capturing
**actual evidence** of what happened.

### The absolute honesty clause

A test is only ever reported with one of these three statuses:

| Status | Meaning | Evidence required |
|---|---|---|
| `EXECUTED — PASS` | It ran; the behavior was verified | The real response, plus the state query and its output |
| `EXECUTED — FAIL` | It ran; the behavior was wrong | The error, verbatim |
| `NOT EXECUTED — PLAN ONLY` | It has not been run | None; it is a placeholder |

The third status exists so that the first is never needed falsely. A
fabricated PASS is the worst thing that can be put into an engineering record,
because every decision downstream is then made on a lie.

---

## Core Principles

1. **Real execution only.** No mocked responses, no simulated data state, no
   "this should work".
2. **Evidence-based.** Every test carries proof: the request and its response,
   the state query and its output.
3. **Reproducible by hand.** Commands are copy-pasteable and run anywhere the
   project's HTTP client and database client are installed. No framework
   ceremony required to reproduce a failure.
4. **Transparent.** Anyone reading the record can see exactly what happened,
   not a summary of what happened.

---

## Where Tests Live

```
{{TESTING_DIR}}/
├── suites/                             # the suites themselves
│   ├── wo-XXXX-feature-name.sh
│   └── comprehensive/                  # longer domain suites
└── results/                            # execution archive
    └── behavioral-test-report_*.md     # timestamped reports
```

The shared framework, runners, and configuration come from the installed
harness under `{{PIPELINE_ROOT}}/harness/`:

| Path | What |
|---|---|
| `harness/config/test-config.env` | One place that decides which environment every suite talks to |
| `harness/lib/test-helpers.sh` | Assertions and status helpers to source, not reimplement |
| `harness/runners/run-all-critical-tests.sh` | The canonical runner: the manifest, tier by tier |

Templates for the written record are in
`{{PIPELINE_ROOT}}/core/templates/testing/`: a harness template, an execution
template, and a verification template.

---

## Naming

| Pattern | Purpose | Example |
|---|---|---|
| `wo-XXXX-feature-name.sh` | A suite tied to one work order | `wo-0102-login-critical-path.sh` |
| `wo-XXXX-*-critical-path.sh` | The critical path of a feature | `wo-0310-websocket-critical-path.sh` |
| `category-tests.sh` | A standing domain suite | `auth-login-tests.sh` |

---

## Reporting Status

### In a suite

Source the harness helpers rather than writing your own; they already emit the
three statuses and keep the counters.

```bash
test_pass() {
    echo -e "${GREEN}├─ RESULT: $1${NC}"
    echo -e "${GREEN}└─ STATUS: EXECUTED — PASS${NC}"
    PASSED=$((PASSED + 1))
}

test_fail() {
    echo -e "${RED}├─ RESULT: $1${NC}"
    echo -e "${RED}└─ STATUS: EXECUTED — FAIL${NC}"
    FAILED=$((FAILED + 1))
}

test_skip() {
    echo -e "${YELLOW}├─ RESULT: $1${NC}"
    echo -e "${YELLOW}└─ STATUS: NOT EXECUTED — SKIP${NC}"
    SKIPPED=$((SKIPPED + 1))
}
```

A skip always records why, and the reason is a fact about the environment —
"prerequisite not configured", "depends on an external service that is not
reachable from here" — never "did not get to it".

### In a document

```markdown
| Test ID | Description | Status | Evidence |
|---------|-------------|--------|----------|
| 1.1 | Sign-in returns 200 | EXECUTED — PASS | HTTP 200, session cookie set |
| 1.2 | Wrong password rejected | EXECUTED — PASS | HTTP 401 |
| 1.3 | Second-factor challenge | NOT EXECUTED — SKIP | Prerequisite not configured |
```

---

## Unit Tests Versus Behavioral Tests

### Unit tests

Run with the project's unit runner — whatever the stack uses (Jest, Vitest,
pytest, JUnit, `go test`, and so on). The project `CLAUDE.md` records the
command. Use them for **isolated logic with no external dependency**:

- Pure functions: parsing, formatting, arithmetic, date handling
- Validators and guards operating on an input value
- Service logic with its collaborators substituted
- Mappers and transformations between shapes
- Utility helpers

```
describe("token payload normalization")
  it("converts string identifiers to integers")
    given  { sub: "123", account: "456" }
    expect sub === 123
```

Unit tests are welcome, expected, and not verification evidence on their own.

### Behavioral tests

Use them to verify **what the running system does**:

- Endpoint responses: status, headers, body
- State changes: a row created, updated, or removed
- Authentication and session flows end to end
- Multi-step workflows where step three depends on step one
- Integration between two services that each pass their own unit tests

```bash
# Sign-in returns 200 for valid credentials
curl -X POST {{API_BASE_URL}}/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "Password123!"}'
# Expected: HTTP 200, body carries an access token
```

### Why unit tests alone are not enough

| Problem | Unit suite | Behavioral suite |
|---|---|---|
| Hidden failure | Passes against a substitute that never disagrees | Requires the real response |
| Opaque result | The actual exchange is not visible | The exchange is in the record |
| Environment coupling | Depends on the fixture matching reality | Uses the real system |
| Trust | "Passed" does not mean production works | What you see is what production does |
| Debugging | Framework indirection | Re-run one command |

---

### Why not end-to-end tests with stubs

| Concern | End-to-end with mocks and fixtures | Behavioural |
|---|---|---|
| What passing proves | that the code works against the stub | that the running system did the thing |
| Hidden failure | a stub that drifted from the real service keeps passing | a real response cannot drift from itself |
| What you can see | a framework's summary | the request, the response, the query, the row |
| Environment | a test database that is not the database | the database the code actually writes to |
| Reproducing a failure | rerun the framework | copy the command, paste it, watch it fail |
| The value asserted | often "a call was made" | the actual value that came back, against the value that was sent |

A suite that passes against a stub has proven the stub. The shipped examples under
`{{PIPELINE_ROOT}}/core/templates/testing/examples/` show the alternative in full.

---

## Test Harness Format

Every behavioral test is written in this shape, starting at
`NOT EXECUTED — PLAN ONLY` and only ever changed by running it.

```markdown
### Test X.Y: [Name]

**Goal:** what this test verifies

**Status:** NOT EXECUTED — PLAN ONLY

**Request:**
\`\`\`bash
curl -X POST {{API_BASE_URL}}/endpoint \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
\`\`\`

**Expected response:**
\`\`\`json
{ "result": "expected value" }
\`\`\`

**State verification:**
\`\`\`sql
SELECT column FROM table WHERE condition;
\`\`\`

**Execution evidence:**
\`\`\`
[paste the real output here]
\`\`\`

**Result:** EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY
```

Assert on state, not only on status codes. An endpoint that returns 200 and
writes nothing is the failure this catches.

---

## Execution Process

### Phase 1 — preparation

1. The application is running and reachable at `{{API_BASE_URL}}`
2. The data store is reachable, with the project's database client
3. Fixtures or test accounts exist, created by the project's own seed path
4. Prior test state is cleared so a rerun means the same thing

### Phase 2 — execute

```bash
{{TESTING_DIR}}/suites/wo-0102-login-critical-path.sh                # one suite
{{PIPELINE_ROOT}}/harness/runners/run-all-critical-tests.sh --full  # every tier
```

### Phase 3 — capture evidence

For each test: run the command, capture the response, run the state query,
set the status from what actually happened, and paste the real output.

### Phase 4 — record

Write the report into `{{TESTING_DIR}}/results/` as
`behavioral-test-report_YYYYMMDD_HHMMSS.md`, following
`{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-EXECUTION.md`.

Then let the driver stamp the work order:

```bash
wo verify <number> --run {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
```

`wo verify --run` executes the suite and writes `EXECUTED — PASS` or
`EXECUTED — FAIL` from its exit code, so nobody types a status by hand. That
is the point.

---

## Suite Skeleton

```bash
#!/usr/bin/env bash
# ============================================================================
# WO-XXXX: [Feature Name] — behavioral test suite
# ============================================================================
# Tests:         [what this suite covers]
# Prerequisites: the application is running and its data store is reachable
# ============================================================================

set -euo pipefail

# Environment comes from the shared configuration, never from this file.
# No hardcoded hosts, ports, or credentials in a suite, ever.
HARNESS="{{PIPELINE_ROOT}}/harness"
source "$HARNESS/config/test-config.env"
source "$HARNESS/lib/test-helpers.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PASSED=0; FAILED=0; SKIPPED=0; TOTAL=0

test_start() { TOTAL=$((TOTAL + 1)); echo -e "${BLUE}TEST $TOTAL: $1${NC}"; }
test_pass()  { echo -e "${GREEN}STATUS: EXECUTED — PASS${NC}"; PASSED=$((PASSED + 1)); }
test_fail()  { echo -e "${RED}STATUS: EXECUTED — FAIL: $1${NC}"; FAILED=$((FAILED + 1)); }
test_skip()  { echo -e "${YELLOW}STATUS: NOT EXECUTED — SKIP: $1${NC}"; SKIPPED=$((SKIPPED + 1)); }

echo "WO-XXXX: [Feature Name] — behavioral test suite"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"

test_start "Endpoint responds successfully"
RESPONSE=$(curl -s -w "\n---HTTP_STATUS:%{http_code}---" -X GET "${API_BASE}/endpoint")
HTTP_CODE=$(echo "$RESPONSE" | sed -n 's/.*HTTP_STATUS:\([0-9][0-9]*\).*/\1/p')
if [ "$HTTP_CODE" = "200" ]; then
    test_pass
else
    test_fail "Expected 200, got $HTTP_CODE"
fi

echo
echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED | Skipped: $SKIPPED"
[ "$FAILED" -gt 0 ] && exit 1 || exit 0
```

`API_BASE` and `ORIGIN` come from `harness/config/test-config.env`, which is
rendered from `{{API_BASE_URL}}` and `{{WEB_ORIGIN}}`. One file switches every
suite between environments; a suite that hardcodes a URL breaks that and is
rejected in review.

`harness/lib/test-helpers.sh` carries the assertions worth reusing —
`assert_http_status`, `assert_sql_contains`, `extract_json_field`,
`wait_for_server`, `auth_login`, `random_email`. Read it before hand-rolling
anything; the helpers already handle the cases that bite.

---

## Good Examples

Two complete suites ship with the pipeline, in the shape every behavioural suite has:

- `{{PIPELINE_ROOT}}/core/templates/testing/examples/crud-with-state-verification.sh` — create,
  read, update, refuse, delete; every check on the actual value returned, then on the actual row
- `{{PIPELINE_ROOT}}/core/templates/testing/examples/auth-flow.sh` — register, sign in, use the
  token, refuse the wrong password and a forged token, sign out, confirm the token is dead

Then find the precedent that matches what you are testing:

```bash
pack suite "<term>"        # behavioral suites across every installed pack
pack search "<problem>"    # the work order and bug behind them
```

Failing that, read the newest suite in `{{TESTING_DIR}}/suites/` and follow it.

---

## Validation Checklist

Before a suite counts as complete:

**Structure**
- [ ] The file is in `{{TESTING_DIR}}/suites/` and executable
- [ ] It follows the naming convention
- [ ] Its header states what it covers and what it needs
- [ ] It sources the shared configuration and helpers; it hardcodes nothing

**Execution**
- [ ] Every test has a description a stranger could read
- [ ] Every test asserts on the response *and* on the state that changed
- [ ] Every test has pass, fail, and skip paths
- [ ] The summary reports totals and the exit code reflects failures

**Evidence**
- [ ] Everything marked PASS has real captured output
- [ ] Everything marked FAIL has the error text
- [ ] Everything marked SKIP has an environmental reason

---

## Instructions for Agents

When asked to create or run behavioral tests:

1. Read this file first
2. Start from the templates in `{{PIPELINE_ROOT}}/core/templates/testing/`
3. Execute for real; mark PASS only from evidence you saw
4. Use the exact status vocabulary
5. Paste actual output, never a paraphrase
6. Never invent a result

Creating a suite:

```bash
touch {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
chmod +x {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
# fill in from the skeleton above, then:
{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
```

---

## Relationship to Work Orders

Each suite names the work order it validates:

```
WO-0102 (sign-in flow)  → wo-0102-login-critical-path.sh
WO-0310 (live updates)  → wo-0310-websocket-critical-path.sh
```

The closeout rests on that suite's execution evidence, and `wo close` refuses
to produce a closeout without a VERIFICATION document. Do not route around it.

---

## Passing Tests Are Not Production Readiness

This is the most expensive lesson in this methodology: **green tests do not
mean the code is ready**.

### The anti-pattern

```
1. Write code until the tests pass
2. Tests pass, declare done
3. Ship debug logging, magic numbers, and dev fallbacks with it
4. Someone finds it in production; rework
```

### The pattern

```
1. Write production-quality code from the first line
2. Tests pass — now review the implementation
3. Debug logging? magic numbers? error handling? typing?
4. Clean up what the review found
5. Then declare done
```

### After tests pass, before declaring done

- [ ] Read every changed file line by line
- [ ] No debug logging; the project's logger, at the right level
- [ ] No magic numbers; configuration or named constants
- [ ] No temporary workarounds or dev-only branches
- [ ] Types are real and validated at the boundary
- [ ] Errors are handled explicitly with useful messages
- [ ] The change matches the conventions of the code around it

### Anti-patterns that have caused real rework

1. **Tests-pass tunnel vision.** Attention went to the suite, not the code;
   the tests passed over bandaid work.
2. **Incremental patching.** Each symptom fixed in isolation, debug code left
   behind, nobody stepped back to read the whole change.
3. **Expedience.** Values hardcoded instead of configured, logging left in,
   code copied instead of extracted.
4. **Ignoring the standards.** The checklist above was skipped, and "tests
   pass" was treated as "done".

---

## If This Is Not Followed

The tests are rejected, real evidence is requested, the closeout is incomplete
and cannot be produced, and defects reach production that this process exists
to catch.

---

No exceptions. This is the standard.
