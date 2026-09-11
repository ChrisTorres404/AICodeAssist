# Behavioral Testing Templates

> **Use these templates when creating test documentation.**

---

## Available Templates

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `TEST-TEMPLATE-HARNESS.md` | Test harness document | Creating test plans before execution |
| `TEST-TEMPLATE-EXECUTION.md` | Execution results | Recording test run outcomes |
| `TEST-TEMPLATE-VERIFICATION.md` | Verification report | WO closeout verification evidence |

---

## Template Usage Guide

### TEST-TEMPLATE-HARNESS.md

Use this when creating a new test plan for a work order. This template:
- Lists all tests with descriptions
- Provides copy/paste curl commands
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

**Output file naming:** `wo-XXXX-verification-report.md`

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
- [ ] **No console.log statements** — Uses Logger service
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

**See:** `MANDATORY-TESTING-METHODOLOGY.md` for full details.

---

## Example Workflow

```bash
# 1. Create test harness from template
cp _TEMPLATES/TEST-TEMPLATE-HARNESS.md ../docs/wo-0101-test-harness.md

# 2. Edit with actual test details
# Fill in curl commands, expected responses, etc.

# 3. Execute tests and capture evidence
# Run curl commands, paste actual output

# 4. Create execution report
cp _TEMPLATES/TEST-TEMPLATE-EXECUTION.md ../test-results/wo-0101-execution-YYYYMMDD.md

# 5. For WO closeout, create verification report
cp _TEMPLATES/TEST-TEMPLATE-VERIFICATION.md ../docs/wo-0101-verification-report.md
```

---

## Template Maintenance

These templates should be updated when:
- New testing patterns are established
- Common sections are identified
- Better evidence formats are developed

**Do not modify templates without team review.**
