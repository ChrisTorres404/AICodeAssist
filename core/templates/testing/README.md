# Behavioral Testing Templates

> **Use these templates when creating test documentation.**

---

## Available Templates

Everything in this directory, one line each.

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `TEST-TEMPLATE-HARNESS.md` | Test harness document | Creating test plans before execution |
| `TEST-TEMPLATE-EXECUTION.md` | Execution results | Recording test run outcomes |
| `TEST-TEMPLATE-VERIFICATION.md` | Verification report | WO closeout verification evidence |
| `TEST-TEMPLATE-VERIFICATION-UI.md` | Verification report for browser-rendered evidence | Closing a UI work order, where the evidence is what rendered |
| `UI-TEST-TEMPLATE.md` | Browser test suite document — steps, assertions, execution record | Planning and recording a UI suite driven through a browser |
| `SUITE-TEMPLATE.sh` | Executable behavioural suite scaffold | What `wo suite <n>` renders; a suite that starts the service itself |
| `INTEGRATION-SUITE-TEMPLATE.sh` | Executable suite scaffold for a boundary crossing | A suite against a third party, a queue, or a webhook |
| `examples/` | Two worked suites and their README | Reading a finished suite before writing your first one |

---

## Template Usage Guide

### TEST-TEMPLATE-HARNESS.md

Use this when creating a new test plan for a work order. This template:
- Lists all tests with descriptions
- Provides copy-pasteable request commands
- Has placeholders for evidence

**When to use:** Before test execution, when planning what to test.

**Output file naming:** `wo-XXXX-test-harness.md`

---

### TEST-TEMPLATE-EXECUTION.md

Use this when documenting test execution results. This template:
- Records timestamp and environment
- Captures actual command outputs
- Tracks pass/fail status with evidence

**When to use:** During/after test execution.

**Output file naming:** `wo-XXXX-execution-YYYYMMDD.md`

---

### TEST-TEMPLATE-VERIFICATION.md

Use this when creating verification evidence for WO closeouts. This template:
- Links test results to WO requirements
- Provides summary status
- References detailed execution logs

**When to use:** When closing out a work order.

**Output file naming:** `WO-XXXX-VERIFICATION.md`, inside the work-order folder

---

### TEST-TEMPLATE-VERIFICATION-UI.md

The same document for a work order whose evidence is what the browser rendered:
an element present, text matching, a route reached, a control reachable from the
keyboard, contrast, no console errors, a screenshot kept. `wo verify` picks it
over the shared one for a UI work order.

**When to use:** Closing out a UI work order.

**Output file naming:** `WO-XXXX-VERIFICATION.md`, inside the work-order folder

---

### UI-TEST-TEMPLATE.md

The browser-driven counterpart of the harness document: numbered steps with the
browser command for each, assertions, an execution record per run, and error
scenarios.

**When to use:** Planning a UI suite, and recording each run of it.

**Output file naming:** `ui-<feature-slug>.md`

---

### SUITE-TEMPLATE.sh and INTEGRATION-SUITE-TEMPLATE.sh

The executable scaffolds. `wo suite <n>` renders `SUITE-TEMPLATE.sh` into
`{{TESTING_DIR}}/suites/`; the integration variant is for a suite that crosses a
boundary. Both start the service themselves when nothing is listening and create
their own fixtures, so the suite runs for anyone and not only for its author.

**When to use:** Whenever a work order or bug needs behavioural evidence.

**Output file naming:** `wo-XXXX-<feature>.sh` or `bug-XXXX-<slug>.sh`

---

### examples/

Two finished suites — an authentication flow and a CRUD path with state
verification — plus a README explaining what each demonstrates. Read one before
writing your first suite.

---

## How to Use Templates

1. **Copy the template** to the appropriate location
2. **Replace all placeholders** marked with `[PLACEHOLDER]` or `XXXX`
3. **Fill in all sections** - no empty sections allowed
4. **Update status** as tests are executed

---

## Critical Rules

1. **NEVER mark tests PASS without real evidence**
2. **ALWAYS include actual command output**
3. **USE the three-status system:**
   - `EXECUTED — PASS` (with evidence)
   - `EXECUTED — FAIL` (with error details)
   - `NOT EXECUTED — PLAN ONLY` (placeholder)

---

## CRITICAL: Tests Passing ≠ Done

> **Passing tests do NOT mean the code is production-ready.**

After all tests pass, you MUST also verify code quality:

### Code Quality Checklist (Before Declaring Done)

- [ ] **Read through ALL changed files** — Line by line review
- [ ] **No debug logging** — no `console.log` or its equivalent in this stack; uses the project's logger
- [ ] **No magic numbers** — Extracted to configuration
- [ ] **No dev fallbacks** — Removed temporary code
- [ ] **Proper typing and validation** — No `any` types
- [ ] **Error handling complete** — Clear messages
- [ ] **Follows existing patterns** — Consistent with codebase

### Anti-Patterns to Avoid

1. **Test-Driven Tunnel Vision** — Tests pass → "I'm done!"
2. **Incremental Patching** — Fixed bug, left debug code
3. **Expedience Over Quality** — Hardcoded values, copied code
4. **Ignoring Standards** — Skipped self-review

**See:** `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` for the full form.

---

## Example Workflow

```bash
TEMPLATES={{PIPELINE_ROOT}}/core/templates/testing

# 1. Plan: create the test harness document
cp $TEMPLATES/TEST-TEMPLATE-HARNESS.md \
   {{WORKORDERS_DIR}}/WO-0101-<name>/wo-0101-test-harness.md

# 2. Fill in the real requests, expected responses, and state checks

# 3. Write and run the suite, capturing the real output
{{TESTING_DIR}}/suites/wo-0101-<feature>.sh

# 4. Record the run
cp $TEMPLATES/TEST-TEMPLATE-EXECUTION.md \
   {{TESTING_DIR}}/results/wo-0101-execution-YYYYMMDD.md

# 5. Let the driver stamp the verification from the suite's exit code
wo verify 0101 --run {{TESTING_DIR}}/suites/wo-0101-<feature>.sh
```

Step 5 is the one that matters: `wo verify --run` writes the status from what
actually happened, so nobody types `PASS`. The verification template describes
the document it produces; do not hand-write one to get around a failing suite.

---

## Template Maintenance

These templates should be updated when:
- New testing patterns are established
- Common sections are identified
- Better evidence formats are developed

**Do not modify templates without team review.**
