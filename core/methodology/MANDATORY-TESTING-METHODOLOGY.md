# Mandatory Behavioral Testing Methodology

> This is non-negotiable. Every agent working on {{PROJECT_NAME}} follows it.

The long form of `{{PIPELINE_ROOT}}/core/rules/common/testing.md`. That file
states the rule; this one explains it, shows the shapes, and lists what a
suite has to contain before it counts.

---

## Table of Contents

1. [Core Rule](#core-rule)
2. [What Behavioral Testing Is](#what-behavioral-testing-is)
3. [Core Principles](#core-principles)
4. [Why Not End-to-End Tests With Mocks](#why-not-end-to-end-tests-with-mocks)
5. [Where Tests Live](#where-tests-live)
6. [Naming](#naming)
7. [Reporting Status](#reporting-status)
8. [Unit Tests Versus Behavioral Tests](#unit-tests-versus-behavioral-tests)
9. [The Four Phases](#the-four-phases)
10. [The Documents a Verification Produces](#the-documents-a-verification-produces)
11. [Test Harness Format](#test-harness-format)
12. [Evidence Requirements](#evidence-requirements)
13. [Suite Skeleton](#suite-skeleton)
14. [Real Examples](#real-examples)
15. [Templates](#templates)
16. [Common Patterns](#common-patterns)
17. [Best Practices](#best-practices)
18. [Workflow Summary](#workflow-summary)
19. [Test Categories by Feature Type](#test-categories-by-feature-type)
20. [Real-World Examples](#real-world-examples)
21. [Tools Required](#tools-required)
22. [Good Examples](#good-examples)
23. [Validation Checklist](#validation-checklist)
24. [Anti-Patterns in the Record](#anti-patterns-in-the-record)
25. [Instructions for Agents](#instructions-for-agents)
26. [Relationship to Work Orders](#relationship-to-work-orders)
27. [Running in CI](#running-in-ci)
28. [Passing Tests Are Not Production Readiness](#passing-tests-are-not-production-readiness)
29. [What This Catches](#what-this-catches)
30. [Recorded Outcomes](#recorded-outcomes)
31. [FAQ](#faq)
32. [Conclusion](#conclusion)

---

## Core Rule

**Every test suite offered as verification must exercise real system behavior
through actual execution — not mocked responses.**

Unit tests cover isolated logic. Behavioral tests verify that the running
system does what was claimed and that the state actually changed. They are not
interchangeable, and only the second kind is verification evidence.

### Mocked end-to-end tests were abandoned on purpose

This project does not accept end-to-end suites built on mocks, stubs, fixtures,
or a substitute data layer as evidence that a feature works. That decision was
made deliberately, after those suites repeatedly went green over software that
was broken.

The reasoning is one sentence: **a suite that passes against a mock has proven
the mock.** It has proven that the code agrees with a fixture someone wrote by
hand, which drifts from the real service the moment the real service changes,
and drifts silently. Nothing about a green run tells you the running system
responded, that a row was written, or that a token was ever accepted by the
code that checks tokens.

So behavioral testing replaced it. Every claim of "this works" rests on a run
against the real thing.

### What "real" means here

| Element | What is required | What is not acceptable |
|---|---|---|
| The request | Real HTTP, over the network, to a service that is actually running | An in-process handler call, a supertest-style app instance, a mocked transport |
| The response | The status, headers, and body the service actually returned | An asserted-on fixture, a recorded cassette, a hand-written expectation standing in for a response |
| The state | A real read from the real data store, after the request, confirming what changed | A mocked repository, an in-memory substitute, "the service reported success" |
| Authentication | A real token or session issued by the real sign-in path and accepted by the real guard | A hand-forged token, a test-only bypass, a stubbed identity |
| The environment | The application, its database, and its dependencies as they actually run | A test harness that boots a different wiring than production uses |

If any row of that table is a substitute, the result is not behavioral
evidence. Say so plainly in the record rather than blurring it.

---

## What Behavioral Testing Is

Behavioral testing validates software through **real execution** against a
**live system** — the running application and its real data store — capturing
**actual evidence** of what happened.

### The absolute honesty clause

> **If I did not literally send the request or run the state query, I am not
> allowed to say the test was executed or that it passed.**

A test is only ever reported with one of these five statuses. There is no
sixth, and no softer wording.

| Status | Meaning | Evidence required |
|---|---|---|
| `EXECUTED — PASS` | It ran; the behavior was verified | The real response, plus the state query and its output |
| `EXECUTED — FAIL` | It ran; the behavior was wrong | The error, verbatim |
| `NOT EXECUTED — PLAN ONLY` | It has not been run | None; it is a placeholder |
| `NOT EXECUTED — PRECONDITION FAILED` | It could not run: the environment never came up, so nothing was asserted | The precondition message, and which precondition failed |
| `RUNNING` | A run started and has not finished | None yet; an interrupted run is not a result |

The last four exist so that the first is never needed falsely. A fabricated
PASS is the worst thing that can be put into an engineering record, because
every decision downstream is then made on a lie.

**Where SKIP went.** Older suites wrote `NOT EXECUTED — SKIP`. That word
covered two different things — "the environment was not there" and "I did not
get to it" — and the second is not a status, it is `NOT EXECUTED — PLAN ONLY`.
So SKIP maps onto `NOT EXECUTED — PRECONDITION FAILED`: a suite that cannot
establish its preconditions exits `77`, and `wo verify --run` records exactly
that. A `test_skip` helper in a suite you inherit means the same thing; keep
the helper name if you like, but have it print the precondition status and let
the suite exit 77 when nothing could be asserted.

`wo close` refuses a work order whose last verification is `RUNNING` or
`NOT EXECUTED — PRECONDITION FAILED`, because neither says anything about the
code. Fix the environment and run it again.

**Only write PASS when** you ran the actual command, captured the actual
output, checked it against the expected behavior, and can show the evidence.

**Never write PASS when** you did not run the command, you simulated the
response, you assumed it should work, or you are inferring behavior from
reading the code.

These phrasings are not statuses and must never appear in place of one:

- "PASS" without "EXECUTED"
- "Should pass"
- "Expected to work"
- "Verified by code review" — that is design review, not behavioral
  verification. If that is genuinely all that was done, write exactly that,
  and leave the test at `NOT EXECUTED — PLAN ONLY`.

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
5. **Honest status.** A test is `EXECUTED — PASS`, `EXECUTED — FAIL`, `NOT
   EXECUTED — PLAN ONLY`, `NOT EXECUTED — PRECONDITION FAILED`, or `RUNNING`.
   There is no sixth option and no softer wording. A run that was interrupted
   stays `RUNNING` until it is run again; whatever passed before the interrupt
   says nothing about now.

---

## Why Not End-to-End Tests With Mocks

### What goes wrong with mocked and framework-driven end-to-end suites

- **Hidden failures.** A suite can pass without touching the real system.
  Mocked dependencies hide integration faults, and a mis-wired harness
  produces false positives that look exactly like real ones.
- **Opaque results.** When it fails you cannot see the actual response or the
  actual state; you see an assertion message about a value you no longer have.
- **Environment coupling.** It needs its own database and its own setup, which
  is not the setup the application runs in, and which breaks on every schema
  change.
- **Drift.** Mocks age. The real service changes shape and the mock does not,
  so the suite keeps passing against a service that no longer exists.
- **Trust.** "Tests passed" stops meaning "production works", and once that
  link is broken the suite is worse than nothing, because it is believed.

### What behavioral testing gives instead

- **Transparency.** You see exactly what happened: the real response and the
  real rows, in the record.
- **Debuggability.** Copy the failing command, paste it, watch it fail again.
  No framework between you and the fault.
- **Trustworthiness.** No mocks to maintain, no harness magic. What you see is
  what the running system does.
- **Maintainability.** No test-framework upgrades, no mock synchronization.
  The commands keep working as long as the contract holds — and when the
  contract changes, the suite fails, which is the point.
- **Fast iteration.** No compilation, no runner boot. Run one command.

### Side by side

| Aspect | Behavioral testing | End-to-end with mocks and fixtures |
|---|---|---|
| Execution | Real HTTP and real state queries | Mocked transport, or a test-only database |
| What passing proves | The running system did the thing | The code agrees with the stub |
| Evidence | The actual response and the actual rows | A framework's assertion summary |
| Hidden failure | A real response cannot drift from itself | A stub that drifted keeps passing |
| Debuggability | Copy and paste one command | Re-run the whole suite and add printouts |
| Speed | Fast; nothing to compile | Slow; boot and teardown per run |
| Maintenance | Low; the commands are stable | High; framework and mocks both need upkeep |
| Environment | The one the code actually runs in | A test-specific arrangement |
| The value asserted | The actual value returned, against the value sent | Often only that a call was made |

### Where each belongs

Use behavioral testing for:

- Integration verification — the data store and the API together
- Work order verification
- Post-deployment validation
- Production smoke tests
- Manual QA workflows
- Debugging a live issue

Use the unit runner for:

- Unit tests — pure logic, no I/O
- CI/CD automation (if set up correctly)
- Regression prevention (if maintained)

**The standing choice for this project: behavioral tests for everything
integration-level or behavioral; the unit runner for isolated unit tests
only.** A mocked end-to-end suite is not evidence and is not accepted as one.

The shipped examples under
`{{PIPELINE_ROOT}}/core/templates/testing/examples/` show the alternative in
full.

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
| `harness/lib/test-env.sh` | Environment: health check, database access, pool recovery, known-state reset |
| `harness/lib/test-common.sh` | The one definition of HTTP requests, `run_sql`, and the shared assertions |
| `harness/lib/test-helpers.sh` | Assertions and status helpers to source, not reimplement |
| `harness/lib/test-framework.sh` | The longer-form framework: suite banners, progress, summary reports |
| `harness/runners/run-all-critical-tests.sh` | The canonical runner: the manifest, tier by tier |
| `harness/scripts/run-behavioral-tests.sh` | Non-interactive entry point, for CI and for batch runs |

### Templates Location

All templates for the written record live in one place:

```
{{PIPELINE_ROOT}}/core/templates/testing/
├── README.md                           # how to use these
├── TEST-TEMPLATE-HARNESS.md            # the command reference
├── TEST-TEMPLATE-EXECUTION.md          # the execution results
├── TEST-TEMPLATE-VERIFICATION.md       # the verification report
├── TEST-TEMPLATE-VERIFICATION-UI.md    # the verification report, for UI work
└── examples/                           # two complete suites to copy
```

---

## Naming

| Pattern | Purpose | Example |
|---|---|---|
| `wo-XXXX-feature-name.sh` | A suite tied to one work order | `wo-0102-login-critical-path.sh` |
| `wo-XXXX-*-critical-path.sh` | The critical path of a feature | `wo-0310-websocket-critical-path.sh` |
| `category-tests.sh` | A standing domain suite | `auth-login-tests.sh` |

---

## Reporting Status

### Status Values

Use exactly the five values from [the absolute honesty
clause](#the-absolute-honesty-clause), spelled exactly that way, in suites and
in documents alike. A status is a controlled vocabulary, not prose: tooling
reads it, `wo close` gates on it, and a variant spelling reads as an unknown
state.

### In a suite

Source the harness helpers rather than writing your own; they already emit the
statuses above and keep the counters.

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
    echo -e "${YELLOW}└─ STATUS: NOT EXECUTED — PRECONDITION FAILED${NC}"
    SKIPPED=$((SKIPPED + 1))
}

# A suite that could not establish its preconditions at all asserted nothing.
# Say so and exit 77; the driver records NOT EXECUTED — PRECONDITION FAILED
# rather than a failure, and refuses to close the work order on it.
precondition() { echo "precondition: $*" >&2; exit 77; }
```

A precondition status always records why, and the reason is a fact about the
environment — "prerequisite not configured", "depends on an external service
that is not reachable from here" — never "did not get to it". That last case
is `NOT EXECUTED — PLAN ONLY`.

### In a document

```markdown
| Test ID | Description | Status | Evidence |
|---------|-------------|--------|----------|
| 1.1 | Sign-in returns 200 | EXECUTED — PASS | HTTP 200, session cookie set |
| 1.2 | Wrong password rejected | EXECUTED — PASS | HTTP 401 |
| 1.3 | Second-factor challenge | NOT EXECUTED — PRECONDITION FAILED | Second-factor provider not configured here |
| 1.4 | Password reset by email | NOT EXECUTED — PLAN ONLY | - |
```

Test IDs are hierarchical and grouped by category: 1.1 and 1.2 belong to
category 1, 2.1 to category 2. The grouping is how a reader sees which area of
the feature is untested.

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

## The Four Phases

### Phase 1 — design the test plan

**In:** the work order specification. **Out:** a test matrix.

1. Read the specification and identify the behaviors that must be true
2. Group them into categories
3. Assign hierarchical test IDs
4. Write each description so that it is checkable — a statement that is either
   true or false about the running system, not "the feature works"
5. Mark every row `NOT EXECUTED — PLAN ONLY`

```markdown
| Test ID | Category | Description | Status |
|---------|----------|-------------|--------|
| 1.1 | Storage | The stored credential is hashed, never plaintext | NOT EXECUTED — PLAN ONLY |
| 2.1 | Rotation | Refresh returns a different token than the one sent | NOT EXECUTED — PLAN ONLY |
| 3.1 | Grace period | The previous token stays valid for the configured window | NOT EXECUTED — PLAN ONLY |
```

### Phase 2 — build the harness

Turn each row into an executable block: the exact command, the expected
response, the state query, the expected rows, and an empty evidence block.
Every command is copy-pasteable, with no hidden setup. See
[Test Harness Format](#test-harness-format).

### Phase 3 — execute

Preparation first. Start the system:

```bash
# from the project root
<the project's start command>
```

Confirm the data store answers before blaming the application for anything:

```bash
run_sql "SELECT 1;"
```

Then check each of these:

1. The application is running and reachable at `{{API_BASE_URL}}`
2. The data store is reachable, with the project's database client
3. Fixtures or test accounts exist, created by the project's own seed path
4. Prior test state is cleared so a rerun means the same thing — for a suite
   that needs a known-good starting database, restore the baseline described
   in `{{PIPELINE_ROOT}}/core/methodology/DATABASE-GOLD-STANDARD-METHODOLOGY.md`

Then run:

```bash
{{TESTING_DIR}}/suites/wo-0102-login-critical-path.sh                # one suite
{{PIPELINE_ROOT}}/harness/runners/run-all-critical-tests.sh --full   # every tier
```

For each test: run the command, capture the full output, run the state query,
capture that too, set the status from what actually happened, and paste the
real output into the evidence block. Add a one- or two-sentence verdict saying
why the evidence means pass or fail.

A failure is documented, never skipped. Capture the error, mark
`EXECUTED — FAIL`, say what went wrong, and raise it. Hiding a failure is the
same offence as fabricating a pass.

### Phase 4 — record

Write the report into `{{TESTING_DIR}}/results/` as
`behavioral-test-report_YYYYMMDD_HHMMSS.md`, following
`{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-EXECUTION.md`.

A summary carries: executed count over total, passed and failed counts, key
findings, any measurements taken, any security checks, regression checks, and
the known limitations — including which tests could not run and why.

```markdown
## Summary

Executed: 10/25 tests
Passed:   10/10
Failed:   0
Not executed: 15 (require an environment not available here)

Key findings:
- Refresh latency 157ms against a 500ms budget
- Token rotation observed across four consecutive refreshes
- Lockout triggered at the configured failure threshold
```

Then let the driver stamp the work order:

```bash
wo verify <number> --run {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
```

`wo verify --run` executes the suite and writes `EXECUTED — PASS` or
`EXECUTED — FAIL` from its exit code, so nobody types a status by hand. That
is the point.

---

## The Documents a Verification Produces

Three documents, each with one job. Their templates are in
`{{PIPELINE_ROOT}}/core/templates/testing/`.

| Document | Job | Contains |
|---|---|---|
| Harness | The command reference | Setup, every command by category, expected outputs, state queries, cleanup. No statuses, no evidence — this is the copy-paste source |
| Verification report | The record | Executive summary, environment, the full test matrix with statuses, each test with its evidence, security checks, build and lint output, out-of-scope items, closure statement |
| Execution results | The answer to "did it work" | Pass and fail counts, the key evidence, measurements, a verdict per critical requirement |

The harness is written once and reused: implementation, re-verification after
a change, and post-deployment validation all run the same commands.

### Required Documents (3 files)

#### 1. Verification report — `WO-XXXX-VERIFICATION.md`

The main record: the matrix and the evidence. Its sections, in order:

- Executive summary
- Test environment setup
- Test matrix — every test, with a status column
- Detailed test cases — goal, commands, evidence, verdict
- Security validation
- Build and lint status
- Out-of-scope items
- Closure statement

#### 2. API test harness — `WO-XXXX-api-test-harness.md`

A pure command reference: no statuses, no evidence. It holds setup commands,
every test command grouped by category, the expected outputs, the state
queries, and a quick-reference section. This is the copy-paste source, and it
is the document that gets reused after deployment.

#### 3. Execution results — `WO-XXXX-EXECUTION-RESULTS.md`

The short answer to "did it work": pass and fail counts, the key evidence,
the measurements taken, and a verdict for each critical requirement.

---

## Test Harness Format

### Command Block Template

Every behavioral test is written in this shape, starting at
`NOT EXECUTED — PLAN ONLY` and only ever changed by running it. Setup lines
that produce a variable belong inside the block, so the block is self-contained
and a reader never has to hunt for where `$TOKEN` came from.

~~~markdown
### Test X.Y: [Name]

**Goal:** what this test verifies

**Status:** NOT EXECUTED — PLAN ONLY

**Request:**
```bash
curl -X POST {{API_BASE_URL}}/endpoint \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

**Expected response:**
```json
{ "result": "expected value" }
```

**State verification:**
```sql
SELECT column FROM table WHERE condition;
```

**Expected state:**
```
 column | value
--------+-------
 foo    | bar
(1 row)
```

**Execution evidence:**
```
[paste the real output here]
```

**Result:** EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY

**Verdict:** one or two sentences on why the evidence means that result
~~~

Assert on state, not only on status codes. An endpoint that returns 200 and
writes nothing is the failure this catches.

---

## Evidence Requirements

### For a request test

Three parts, all of them required.

1. The request, exactly as sent

```bash
curl -X POST "${API_BASE}/endpoint" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

2. The response, exactly as returned

```json
{
  "actual": "response",
  "from": "the server"
}
```

3. A verdict naming the result and the reason

```
Result: EXECUTED — PASS
Reason: HTTP 200, and the body carries the identifier that was created.
```

### For a state test

1. The query

```sql
SELECT column FROM table WHERE condition;
```

2. Its output, including the row count line

```
 column | value
--------+-------
 foo    | bar
(1 row)
```

3. A verdict naming the result and the reason

```
Result: EXECUTED — PASS
Reason: the column holds the value the request was supposed to write.
```

### For a combined test

Show all four: request, response, state query, state output — then the result.

~~~markdown
**Request:** [the command]
**Response:** [the actual body]
**State verification:** [the query]
**State output:** [the actual rows]
**Result:** EXECUTED — PASS
~~~

Most tests worth writing are combined tests, because the interesting failure is
a successful response over an unchanged database.

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
test_skip()  { echo -e "${YELLOW}STATUS: NOT EXECUTED — PRECONDITION FAILED: $1${NC}"; SKIPPED=$((SKIPPED + 1)); }

# Nothing could be asserted at all: say why and exit 77, never 1.
precondition() { echo "precondition: $*" >&2; exit 77; }

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
echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED | Precondition: $SKIPPED"
# 0 pass, 77 could not run (a precondition failed; nothing was asserted),
# anything else fail.
[ "$FAILED" -gt 0 ] && exit 1 || exit 0
```

`API_BASE` and `ORIGIN` come from `harness/config/test-config.env`, which is
rendered from `{{API_BASE_URL}}` and `{{WEB_ORIGIN}}`. One file switches every
suite between environments; a suite that hardcodes a URL breaks that and is
rejected in review.

`harness/lib/test-helpers.sh` carries the assertions worth reusing —
`assert_http_status`, `assert_sql_contains`, `extract_json_field`,
`wait_for_server`, `auth_login`, `random_email`, `get_metric_value`,
`measure_metric_delta`. Read it before hand-rolling anything; the helpers
already handle the cases that bite.

---

## Real Examples

Two tests, written out end to end, from the plan state through to the captured
evidence. Copy the shape, not the endpoint names.

### Example 1 — a request test: token rotation

**From:** `{{TESTING_DIR}}/suites/wo-0102-login-critical-path.sh`

~~~markdown
## Test 2.1: Token rotation

**Goal:** refresh returns a NEW token, not the one it was given

**Status:** NOT EXECUTED — PLAN ONLY

### Request

```bash
# Sign in first
LOGIN=$(curl -s -X POST "${API_BASE}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Password123!"}')

TOKEN1=$(echo "$LOGIN" | jq -r '.refresh_token')
echo "Original: $TOKEN1"

# Refresh
REFRESH=$(curl -s -X POST "${API_BASE}/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$TOKEN1\"}")

TOKEN2=$(echo "$REFRESH" | jq -r '.refresh_token')
echo "New: $TOKEN2"

# Compare
if [ "$TOKEN1" != "$TOKEN2" ]; then
  echo "PASS: rotation working"
else
  echo "FAIL: the same token came back"
fi
```

### Expected output

```
Original: 47a46df5...
New:      724cfa79...
PASS: rotation working
```

### Execution evidence

```
Original: 47a46df5f47f7d21b37a2f6579f129a6175000986ecc9bf0576909f1cc77b548
New:      724cfa792e251efb4cdc993f3a2600710a8835b6b537628949d86fbe86c45fe5
PASS: rotation working
```

**Result:** EXECUTED — PASS
**Verdict:** the two tokens differ, so rotation is confirmed working.
~~~

### Example 2 — a state test: the version counter moved

~~~markdown
## Test 2.2: Token version increments

**Goal:** the stored token version increases on every refresh, and the previous
hash is retained for the grace window

**Status:** NOT EXECUTED — PLAN ONLY

### State verification

```bash
run_sql_formatted "
SELECT token_version,
       previous_token_hash IS NOT NULL AS has_previous
FROM sessions
WHERE user_id = (SELECT id FROM users WHERE email = 'test@example.com')
ORDER BY created_at DESC
LIMIT 1;
"
```

### Expected state

```
 token_version | has_previous
---------------+--------------
             2 | t
(1 row)
```

### Execution evidence

```
 token_version | has_previous
---------------+--------------
             2 | t
(1 row)
```

**Result:** EXECUTED — PASS
**Verdict:** token_version is 2 after one refresh (1 → 2) and the previous hash
was stored, so the grace window has something to check against.
~~~

`run_sql` and `run_sql_formatted` are the harness helpers in
`{{PIPELINE_ROOT}}/harness/lib/test-helpers.sh`. Both take one argument, the
query, and both read the credentials from `harness/config/test-config.env`
through `run_psql`. Use `run_sql` when you want the bare value to compare
against, and `run_sql_formatted` when the column headers are part of the
evidence, as above. Never put credentials in a suite.

---

## Templates

Three templates ship with the pipeline, under
`{{PIPELINE_ROOT}}/core/templates/testing/`. Their shapes are below so that you
can recognise a correct document without opening the template.

### Template 1 — test harness document

~~~markdown
# WO-XXXX API Test Harness — copy/paste execution guide

**Work order:** WO-XXXX — [Title]
**Purpose:** executable test commands for manual verification
**Environment:** rendered from harness/config/test-config.env
**Application:** {{API_BASE_URL}}

> USAGE: copy/paste each command block into your terminal.
> Compare actual output with expected output.
> Record results in WO-XXXX-VERIFICATION.md.

---

## Setup commands

### 1. Start the application

```bash
# from the project root
<the project's start command>
```

### 2. Verify the data store is reachable

```bash
run_sql "SELECT version();"
```

### 3. Create the test account

```bash
curl -X POST "${API_BASE}/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Password123!"}'
```

---

## Test 1: [Category name]

### Test 1.1: [Test name]

**Goal:** what this verifies

**Request:**
```bash
[command]
```

**Expected response:**
```
[expected output]
```

**State verification:**
```sql
[query]
```

**Expected state:**
```
[expected rows]
```

---

[repeat for every test]

---

## Cleanup commands

```bash
run_sql "DELETE FROM users WHERE email LIKE 'test%';"
```

---

END OF HARNESS
~~~

### Template 2 — verification report

~~~markdown
# WO-XXXX Verification Report — [feature] behavioral verification

<!--
[WO-XXXX] YYYY-MM-DD
WO-XXXX [feature] behavioral verification
Reason: validate [feature] against the live schema and runtime behavior.
-->

**Status:** COMPLETE | IN PROGRESS | NOT STARTED
**Date:** YYYY-MM-DD
**Environment:** local | staging | production
**Related work orders:** [list]

> NOTE: tests start at NOT EXECUTED. Execute the harness, capture real output,
> update the status.

---

## Executive summary

[what is being verified and why]

**Verification status:**
- Executed: X/Y tests
- Passed: X/X
- Failed: 0

---

## Test matrix

| Test ID | Category | Description | Status | Evidence |
|---------|----------|-------------|--------|----------|
| 1.1 | [Category] | [Description] | NOT EXECUTED — PLAN ONLY | Section X |

---

## Detailed test suite

### Test 1.1: [Name]

**Goal:** what this verifies

**Status:** NOT EXECUTED — PLAN ONLY

**Request:** [from the harness]

**Expected response:** [from the harness]

**Execution evidence:**
```
[paste the real output here after execution]
```

**Result:** NOT EXECUTED — PLAN ONLY
**Verdict:** [fill in after execution]

---

[repeat for every test]

---

## Security validation

[the security-specific checks and their evidence]

---

## Build and lint status

```bash
<the project's build command>
<the project's lint command>
```

**Output:**
```
[paste the real output]
```

---

## Out of scope / future work

[found but not implemented, each with a reason]

---

## Closure statement

**Implementation status:** COMPLETE | PARTIAL
**Behavioral verification:** X/Y executed, all passed
**Production readiness:** the verdict, with the evidence it rests on

**Next steps:**
1. [action]
2. [action]
~~~

### Template 3 — execution results summary

~~~markdown
# WO-XXXX Test Execution Results — real evidence

**Date:** YYYY-MM-DD
**Executor:** [name or role]
**Status:** X/X TESTS PASSED

---

## Test summary

| Test | Status | Result |
|------|--------|--------|
| [Name] | EXECUTED | PASS |

---

## Test X: [Name]

**Response:**
```
[actual response captured]
```

**State output:**
```
[actual rows captured]
```

**Verdict:** PASS
**Reason:** [why it passed]

---

[repeat for each critical test]

---

## Final verdict

**Production ready:** YES | NO
**Evidence:** [summary of what was proven]
~~~

---

## Common Patterns

These five cover most of what a behavioral suite needs to do. Use the harness
helpers where one exists; the shapes below are what those helpers do.

### 1. Sign in and extract the token

```bash
RESPONSE=$(curl -s -X POST "${API_BASE}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"'"$TEST_PASSWORD"'"}')

ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token')
```

Credentials come from the test configuration, never written into the suite.

### 2. Compare state before and after

The single most useful pattern, and the one that catches an endpoint that
answers 200 and writes nothing.

```bash
BEFORE=$(run_sql "SELECT value FROM table WHERE id = '$ID';")
curl -s -X POST "${API_BASE}/action" -H "Authorization: Bearer $ACCESS_TOKEN" >/dev/null
AFTER=$(run_sql "SELECT value FROM table WHERE id = '$ID';")

if [ "$BEFORE" != "$AFTER" ]; then
    test_pass
else
    test_fail "Value unchanged after the request: still '$BEFORE'"
fi
```

### 3. Verify a counter moved

```bash
BEFORE=$(get_metric_value "metric_name")
curl -s -X POST "${API_BASE}/action" >/dev/null
AFTER=$(get_metric_value "metric_name")

# Expected: AFTER - BEFORE == 1
```

### 4. Time-based behavior — grace periods, expiries, timeouts

```bash
curl -s -X POST "${API_BASE}/setup" >/dev/null
START=$(date +%s)

sleep "$GRACE_WINDOW_SECONDS"     # from configuration, not a literal

curl -s -X POST "${API_BASE}/test"
ELAPSED=$(( $(date +%s) - START ))
# Assert both the response and that the wait really was long enough
```

Take the window from the same configuration the application reads. A test that
hardcodes 31 because the code says 30 breaks the day the window changes.

### 5. Loop to a threshold — lockout, rate limits, quotas

```bash
run_sql "UPDATE table SET counter = 0 WHERE id = '$ID';"   # known starting state

for i in $(seq 1 "$THRESHOLD"); do
    curl -s -X POST "${API_BASE}/action" >/dev/null
done

run_sql "SELECT counter, locked FROM table WHERE id = '$ID';"
# Expected: counter = THRESHOLD, locked = true
```

Reset the counter first. A threshold test that starts from whatever the last
run left behind passes and fails at random.

---

## Best Practices

### 1. Derive dynamic values; never hardcode an identifier

Read the id back out of the response or the database and use the variable. A
suite with a pasted identifier in it works once, on one machine.

```bash
# Good
USER_ID=$(run_sql "SELECT id FROM users WHERE email = 'test@example.com';")
curl -X POST "${API_BASE}/endpoint/$USER_ID"

# Bad
curl -X POST "${API_BASE}/endpoint/3f1c9a22-0000-4a11-8c3d-hardcoded"
```

### 2. Show both before and after state

State the starting value, act, state the ending value. That is the proof; a
status code is not.

```bash
# Before
run_sql "SELECT status FROM orders WHERE id = '$ORDER_ID';"

# Act
curl -X POST "${API_BASE}/orders/$ORDER_ID/submit"

# After
run_sql "SELECT status FROM orders WHERE id = '$ORDER_ID';"

# Expected: the two values differ, and the second is 'submitted'
```

### 3. Compare inline and fail loudly

Print what was expected and what came back, in the same line, so a failure
explains itself in the log.

```bash
RESULT=$(curl -s "${API_BASE}/endpoint" | jq -r '.field')

if [ "$RESULT" = "expected_value" ]; then
  echo "PASS"
else
  echo "FAIL: got '$RESULT', expected 'expected_value'"
fi
```

### 4. Document negative tests

For every "valid input is accepted", write "invalid input is refused, with this
status". Most security defects live in the branch nobody asserted on.

```bash
# Test: an invalid token must be rejected
curl -s -o /dev/null -w '%{http_code}\n' -X POST "${API_BASE}/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "invalid_token"}'

# Expected: 401
# Actual:   [paste the real status]
# Result:   PASS if 401
```

### 5. Time-based tests need explicit waits

Sleep the configured window, then measure that the time really passed before
asserting on it. For a grace period, a replay window, or an expiry, the wait is
part of the test and belongs in the record.

```bash
GRACE_SECONDS="${GRACE_SECONDS:-30}"
echo "Waiting $((GRACE_SECONDS + 1)) seconds..."
sleep $((GRACE_SECONDS + 1))
# Then assert that the old token is refused
```

### 6. Clean up, or start from a known state

Either delete what the suite created or reset the rows it depends on. A suite
that is not rerunnable is not a suite.

```bash
trap 'run_sql "DELETE FROM users WHERE email LIKE '"'"'test-%@example.com'"'"';"' EXIT
```

---

## Workflow Summary

### For a new work order

1. **Read the spec** — identify the critical behaviors
2. **Create the test matrix** — every test with an ID
3. **Write the harness** — every request and state query, copy-pasteable
4. **Mark everything `NOT EXECUTED — PLAN ONLY`**
5. **Execute when the environment is ready** — run the commands
6. **Capture evidence** — the real responses and the real rows
7. **Update the status** — `EXECUTED — PASS` or `EXECUTED — FAIL`
8. **Write the summary** — counts, findings, measurements
9. **Sign off** — production ready, or not, and why

```bash
wo new "Feature name" --size standard
wo suite <number>
wo verify <number> --run {{TESTING_DIR}}/suites/wo-<number>-feature-name.sh
wo close <number>
```

### Daily testing workflow

1. Start the application and its data store
2. Open the harness document
3. Copy a command
4. Paste it into the terminal
5. Capture the output
6. Paste it into the evidence block
7. Mark it executed
8. Repeat for every test
9. Write the summary

### Post-deployment validation

1. Use the harness that already exists, from the implementation phase
2. Execute it against the deployed environment, by pointing
   `harness/config/test-config.env` at it — not by editing the suite
3. Verify there are no regressions
4. Document any difference between environments
5. Update the verification report

```bash
TEST_ENV=staging {{PIPELINE_ROOT}}/harness/runners/run-all-critical-tests.sh --standard
```

---

## Test Categories by Feature Type

What to cover when the feature is of a given kind. Adapt the names to the
project; the categories are what matters.

### Authentication and session features

1. Schema and entity alignment — the stored shape matches the declared shape
2. The flows: register, sign in, refresh, sign out
3. Token issuance and validation
4. Session lifecycle: creation, renewal, revocation, expiry
5. Security behavior: lockout, rotation, cross-site request protection
6. Latency against a stated budget

#### Critical tests

- The stored credential and the stored token are hashed, never plaintext
- A revoked session is actually refused, not merely marked revoked
- An expired token is refused at the boundary that checks tokens
- The measured latency is recorded against its budget, not assumed

### Authorization features

1. The request context is established as the code expects
2. A permitted action succeeds
3. An unpermitted action is refused with the right status
4. Isolation: one account cannot read another account's data
5. Any documented bypass for elevated roles behaves exactly as documented
6. Context does not leak between requests

#### Critical tests

- An authenticated request carrying the privilege succeeds
- An authenticated request without it is refused with the documented status
- A request across an isolation boundary returns no rows at all
- A public route performs no privilege check, and says so in the evidence

### Scheduled and cleanup features

1. The routine exists where it is supposed to exist
2. Running it returns what it claims to return
3. Row counts before and after show the rows really went
4. Anything that should be archived before deletion actually was
5. The schedule is registered, with the interval that was specified

#### Critical tests

- The routine deletes the rows it is supposed to delete, proven by counts
- The archive receives the rows before the deletion, not after
- The routine returns the counts it claims to return
- The schedule is registered at the specified interval, read back from the
  scheduler rather than from the configuration that was meant to set it

### Data migration and schema features

1. The migration applies to a database at the previous state
2. The resulting shape matches what the migration claimed
3. Existing rows survive with their values intact
4. The reverse path runs, and leaves the previous shape
5. The application starts and serves requests against the migrated database

#### Critical tests

- The migration is applied to a copy of the previous state, not to an empty
  database, because an empty database hides every data-preserving defect
- Row counts and spot-checked values match before and after
- The reverse path runs cleanly and leaves the previous shape
- The application boots against the migrated database and serves a request

---

## Real-World Examples

Three work orders, three different shapes of verification. The point of the set
is that "behavioral" does not always mean "send a request": it means execute
something real and read the real answer.

### A schema alignment work order — state-only verification

**Approach:** query-first. No request is sent at all, because the claim under
test is about shape, not behavior.

- Query the database catalogue for the declared shape
- Compare it against the models the application declares
- Document every mismatch
- Change the models to match the database, or migrate the database, and rerun

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions'
ORDER BY ordinal_position;
```

```sql
-- Every foreign key on the table, and what it points at
SELECT tc.constraint_name, kcu.column_name,
       ccu.table_name AS references_table, ccu.column_name AS references_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'sessions';
```

This is a legitimate verification mode and it still produces evidence: the
statuses, the queries, and their real output all go into the record exactly as
they would for a request test. What it must not do is claim behavior. A schema
that looks right is not a feature that works.

### An authorization work order — request and state combined

**Approach:** both halves, every time.

- Request: call the protected endpoint with a token that carries the privilege
- State: verify the request context the application set for the data layer
- Request: call it again with a token that lacks the privilege, expect a refusal
- State: verify tenant isolation — only the caller's own rows are visible

**Execution required:** real calls with real tokens. A mock cannot fail this
test the way the real authorization layer can.

### An authentication engine work order — the full set

**Approach:** every technique in this document at once.

- Requests: register, sign in, refresh several times in a row
- State: the stored hash, the rotation, the version counter
- Time-based: the grace window below the threshold, replay above it
- Metrics: the counters and histograms the feature claims to emit
- Loop-based: repeated failures up to the lockout threshold

**Execution required:** the application, the data store, and real elapsed time.

---

## Tools Required

### Minimum Toolset

| Tool | For | Note |
|---|---|---|
| An HTTP client (`curl`) | Requests | Any modern version |
| The project's database client | State verification | Matching the engine the project runs |
| `jq` | Reading fields out of JSON responses | Optional but worth having |
| `bash` | The suites themselves | Present on any development machine |

Nothing else is required, and that is deliberate: a suite anybody can run is a
suite that gets run.

Check them before starting, so a missing tool is not mistaken for a failure:

```bash
curl --version
```

```bash
<the project's database client> --version
```

```bash
jq --version
```

```bash
bash --version
```

### Optional Helpers

Not required, and never assumed by a suite — a suite that depends on one of
these is not runnable by everyone, which defeats the point. Useful at a
terminal while writing tests:

| Tool | For |
|---|---|
| `httpie` | Friendlier request syntax while exploring an endpoint |
| A rich database CLI (`pgcli`, `mycli`, and the like) | Completion and readable result tables while writing state queries |
| `watch` | Re-running a state query on an interval to see a value move |
| `entr` | Re-running a suite whenever the file changes |

---

## Good Examples

Two complete suites ship with the pipeline, in the shape every behavioral suite has:

- `{{PIPELINE_ROOT}}/core/templates/testing/examples/crud-with-state-verification.sh` — create,
  read, update, refuse, delete; every check on the actual value returned, then on the actual row
- `{{PIPELINE_ROOT}}/core/templates/testing/examples/auth-flow.sh` — register, sign in, use the
  token, refuse the wrong password and a forged token, sign out, confirm the token is dead

Then find the precedent that matches what you are testing:

```bash
playbook suite "<term>"     # behavioral suites across every installed playbook
playbook search "<problem>" # the work order and bug behind them
```

Failing that, read the newest suite in `{{TESTING_DIR}}/suites/` and follow it.

---

## Validation Checklist

Before a suite counts as complete:

### Structure

- [ ] The file is in `{{TESTING_DIR}}/suites/` and executable
- [ ] It follows the naming convention
- [ ] Its header states what it covers and what it needs
- [ ] It sources the shared configuration and helpers; it hardcodes nothing

### Execution

- [ ] Every test has a description a stranger could read
- [ ] Every test asserts on the response *and* on the state that changed
- [ ] Every test has pass, fail, and skip paths
- [ ] Negative cases are covered, not only the happy path
- [ ] The suite is rerunnable: it cleans up, or resets what it depends on
- [ ] The summary reports totals and the exit code reflects failures

### Evidence

- [ ] Everything marked PASS has real captured output
- [ ] Everything marked FAIL has the error text
- [ ] Everything marked PRECONDITION FAILED names the precondition that failed
- [ ] Nothing is left at RUNNING; an interrupted run was rerun, not reported

---

## Anti-Patterns in the Record

### Do not simulate a result

Wrong:

```markdown
**Result:** EXECUTED — PASS
**Evidence:** the endpoint should return {"status": "ok"}
```

"Should return" means it was not executed. Right:

```markdown
**Result:** EXECUTED — PASS
**Evidence:**
{"status": "ok"}
```

### Do not mark PASS without evidence

A heading, a status, and nothing between them is not a test result. Wrong:

```markdown
## Test 1.1: sign-in works
**Result:** PASS
```

Nothing was shown, so nothing was proven. Right:

```markdown
## Test 1.1: sign-in works
**HTTP response:**
{"access_token": "eyJ..."}
**Result:** EXECUTED — PASS
```

### Do not quietly drop a failing test

Wrong — the test disappears from the matrix, or is re-marked SKIP:

```markdown
## Test 2.1: token rotation
[test skipped because it failed]
```

Right — it stays, with the error captured, the reason, and the action
required:

```markdown
## Test 2.1: token rotation
**HTTP response:**
{"error": "Internal server error"}
**Result:** EXECUTED — FAIL
**Reason:** the server returned 500 where 200 was expected; rotation is broken.
**Action required:** file a defect, do not promote to production.
```

A failing test that is recorded is doing its job. A failing test that was
deleted is a defect that shipped.

### Do not write a goal that cannot be checked

"Verify the system works" is not a test. "Verify the refresh endpoint returns
200 and a token different from the one sent, given a valid refresh token" is.

---

## Instructions for Agents

When asked to create or run behavioral tests:

1. Read this file first
2. Start from the templates in `{{PIPELINE_ROOT}}/core/templates/testing/`
3. Execute for real; mark PASS only from evidence you saw
4. Use the exact status vocabulary
5. Paste actual output, never a paraphrase
6. Never invent a result

### Creating a New Test Suite

```bash
touch {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
chmod +x {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
# fill in from the skeleton above, then:
{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
```

Or let the driver scaffold it, so the naming and the header are right by
construction:

```bash
wo suite <number>
```

### Documenting Test Results

```bash
# follow TEST-TEMPLATE-EXECUTION.md into:
{{TESTING_DIR}}/results/behavioral-test-report_$(date +%Y%m%d_%H%M%S).md
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

## Running in CI

Two arrangements work, and the choice is about how much the change can hurt.

### Option 1: Manual Gate

**Manual gate.** The pipeline pauses and a person runs the harness, records the
results, and approves. Use this for changes to authentication, authorization,
payments, and anything irreversible.

```yaml
# A manual gate: the pipeline stops and waits for a person.
jobs:
  deploy:
    steps:
      - name: Wait for behavioral verification
        uses: trstringer/manual-approval@v1
        with:
          instructions: |
            Run the behavioral tests from:
              {{WORKORDERS_DIR}}/WO-XXXX-<name>/WO-XXXX-VERIFICATION.md
            Record the results in that document, then approve.
```

### Option 2: Scripted Execution

**Scripted run.** The pipeline starts the application, runs
`{{PIPELINE_ROOT}}/harness/scripts/run-behavioral-tests.sh`, and publishes
`{{TESTING_DIR}}/results/` as a build artifact so the evidence survives the
job. Use this for everything else.

```yaml
# A scripted run: the suites run in the job and the evidence is kept.
jobs:
  behavioral-tests:
    steps:
      - name: Start the application
        run: <the project's start command> &

      - name: Wait for it to answer
        run: |
          . {{PIPELINE_ROOT}}/harness/lib/test-helpers.sh
          wait_for_server "$API_BASE_URL"

      - name: Run the harness
        run: |
          chmod +x {{PIPELINE_ROOT}}/harness/scripts/run-behavioral-tests.sh
          {{PIPELINE_ROOT}}/harness/scripts/run-behavioral-tests.sh

      - name: Upload the evidence
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-evidence
          path: {{TESTING_DIR}}/results/
```

Either way the evidence is archived. A CI run whose output is discarded proves
nothing a week later, which is when someone asks.

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

## What This Catches

The case for the method is the defects it has found before a release, which a
mocked suite had been passing over:

- An endpoint that required a privilege in the design and did not check it in
  the code: the suite called it without the privilege, expected 403, got 200.
- A write path that answered 200 while writing nothing, because the failure was
  swallowed: the response assertion passed, the state query found no row.
- A token that was accepted after the session had been revoked, because
  revocation wrote to one place and the check read another.

Each was invisible to a suite that trusted a substitute, and obvious to a suite
that read the real row.

---

## Recorded Outcomes

Two runs from the record this methodology came out of, kept because they are
what the argument rests on.

### An authorization work order

**Result:** a privilege bypass was caught during verification, not in
production.

- Test: a user without the privilege called the protected endpoint
- Expected: a refusal
- Actual: the request succeeded — the guard was not wired to that route
- Fix: the guard was corrected and the suite reran before the release

**Effect:** the defect was found by the suite instead of by a customer.

### An authentication engine work order

**Result:** every blocking fix in the work order was verified with real
evidence before close.

- 10/10 tests `EXECUTED — PASS`
- Refresh latency 157ms mean, 412ms at p99, against a 500ms budget
- Token rotation observed across four consecutive refreshes
- Grace-window reuse under 1% of refreshes, as designed
- Account lockout: 10 consecutive failures produced a 30-minute lock, read
  back off the account row
- Metrics: all 8 counters the feature declares were observed moving

**Effect:** the release went out on measurements rather than on confidence.

---

## FAQ

### Q: Why not use the unit runner for everything?

It is the right tool for pure logic. For integration it is slower to run,
harder to read when it fails, and only as truthful as its mocks. Behavioral
tests are faster to iterate on, show the actual exchange, and work unchanged
against local, staging, or production.

### Q: Isn't this just manual testing?

No. The commands are scripted, the evidence is recorded, the status is
tracked, and the same harness reruns on demand. Think of it as executable
documentation rather than manual QA.

### Q: What if a test genuinely cannot be executed here?

Mark it honestly: `NOT EXECUTED — PLAN ONLY`, with the reason — an environment
that does not exist locally, a data volume that cannot be produced, an external
service with no sandbox. Incomplete testing that is labelled as incomplete is
useful. Fake results are not.

### Q: Can this be used for frontend work?

Yes, with the same rules:

- Use the browser's network panel instead of the command-line client
- Capture the actual network responses
- Verify the resulting state from the browser console
- Document screenshots for UI tests

The evidence is the same three parts: what was done, what came back, what
changed.

~~~markdown
**Action:** clicked "Save" on the profile form

**Network evidence:**
```
PATCH /api/v1/users/me → 200
{"id":"...","display_name":"New Name"}
```

**State verification:**
```sql
SELECT display_name FROM users WHERE email = 'test@example.com';
```

**State output:**
```
 display_name
--------------
 New Name
(1 row)
```

**Result:** EXECUTED — PASS
~~~

See `{{PIPELINE_ROOT}}/core/methodology/SCENARIO-TESTING-METHODOLOGY.md` for the
longer form.

### Q: How do I run behavioral tests in CI?

Two ways, both in [Running in CI](#running-in-ci): a manual gate where the
pipeline waits for a person, or a scripted run of the harness with the evidence
published as a build artifact. Use the manual gate for critical deployments —
authentication, authorization, payments — and the scripted run for the rest.

### Q: What about performance claims?

Measure and paste the number with its budget. "Fast enough" is not a result.

---

## Conclusion

Behavioral testing is the standard for integration and behavioral verification
here because of five properties, none of which a mocked suite has:

1. **Transparency** — you see exactly what happened
2. **Trust** — no hidden mocks, no framework magic
3. **Debuggability** — copy the failing command and run it yourself
4. **Simplicity** — a request client and a database client
5. **Honesty** — execution cannot be faked in a record that carries its output

Use it for every work order verification, every bug fix verification,
post-deployment validation, smoke tests after a release, integration testing,
and behavioral regression testing.

Three templates are provided and live in
`{{PIPELINE_ROOT}}/core/templates/testing/`: the harness, the verification
report, and the execution results summary.

And the clause the whole thing rests on:

> If you did not run it, do not mark it PASS.

---

## If This Is Not Followed

The tests are rejected, real evidence is requested, the closeout is incomplete
and cannot be produced, and defects reach production that this process exists
to catch.

---

No exceptions. This is the standard.
