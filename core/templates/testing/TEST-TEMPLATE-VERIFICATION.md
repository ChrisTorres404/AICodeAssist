# WO-XXXX: [Feature Name] - Verification Report

**Work Order:** WO-XXXX
**Feature:** [Feature Name]
**Verification Date:** YYYY-MM-DD
**Verified By:** [Name/Agent]

---

## Verification Summary

| Requirement | Tests | Status |
|-------------|-------|--------|
| [Req 1 from WO spec] | 1.1, 1.2 | VERIFIED |
| [Req 2 from WO spec] | 2.1, 2.2, 2.3 | VERIFIED |
| [Req 3 from WO spec] | 3.1 | VERIFIED |
| [Req 4 from WO spec] | 4.1 | PARTIAL |

**Overall Status:** [VERIFIED / PARTIAL / BLOCKED]

---

## Requirements Traceability

When the suite prints a line per check, the driver keeps those lines in the
Execution Record and the mapping below is read straight off them; when it
prints only a verdict, the mapping is traced from the suite's source and this
section must say so.

### Requirement 1: [Requirement Description]

**Source:** WO-XXXX-SPEC.md, Section X

**Tests:**
- Test 1.1: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]
- Test 1.2: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]

**Evidence Summary:**
- HTTP 200 returned with expected payload
- Database record created correctly
- Activity recorded for the event

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED]

---

### Requirement 2: [Requirement Description]

**Source:** WO-XXXX-SPEC.md, Section Y

**Tests:**
- Test 2.1: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]
- Test 2.2: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]
- Test 2.3: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]

**Evidence Summary:**
- Error handling returns correct status codes
- Validation rejects invalid input
- Rate limiting applied correctly

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED]

---

### Requirement 3: [Requirement Description]

**Source:** WO-XXXX-SPEC.md, Section Z

**Tests:**
- Test 3.1: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]

**Evidence Summary:**
- [Summary of evidence]

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED]

---

### Requirement 4: [Requirement Description] — PARTIAL

**Source:** WO-XXXX-SPEC.md, Section W

**Tests:**
- Test 4.1: [Description] — FAIL

**Issue:**
- [Description of what failed]
- [Related bug: BUG-XXXX]

**Remediation:** [What needs to be done]

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED] — [what still needs follow-up]

---

## Test Execution References

| Document | Location |
|----------|----------|
| Test Harness | `{{WORKORDERS_DIR}}/WO-XXXX-<name>/wo-XXXX-test-harness.md` |
| Execution Results | `{{TESTING_DIR}}/results/wo-XXXX-execution-YYYYMMDD.md` |
| Test Suite Script | `{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh` |

---

## Critical Path Verification

### Happy Path: [Primary Use Case]

1. User performs [action] — VERIFIED
2. System responds with [response] — VERIFIED
3. Database updated with [state] — VERIFIED
4. Activity recorded for [event] — VERIFIED

### Error Path: [Error Scenario]

1. User provides invalid [input] — VERIFIED
2. System returns [error code] — VERIFIED
3. No database changes occur — VERIFIED

---

## Security Verification

<!-- Every row is [status] until something ran. Write N/A where a check does not apply; never leave a PASS you did not execute. -->

| Check | Status | Evidence |
|-------|--------|----------|
| Authentication required | [status] | [evidence, or N/A] |
| Authorization enforced | [status] | [evidence, or N/A] |
| Input validation | [status] | [evidence, or N/A] |
| Injection prevented | [status] | [evidence, or N/A] |
| XSS prevented | [status] | [evidence, or N/A] |

---

## Performance Verification

| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| Response time (p50) | [target] | [measured, or not measured] | [status] |
| Response time (p99) | [target] | [measured, or not measured] | [status] |
| Throughput | [target] | [measured, or not measured] | [status] |

---

## Outstanding Items

### Blockers

None — All critical requirements verified.

### Known Limitations

1. [Limitation 1 — accepted per WO spec]
2. [Limitation 2 — to be addressed in future WO]

### Follow-Up Required

1. [Item requiring follow-up]
   - Owner: [Name]
   - Target: [Date/WO]

---

## Verification Checklist

### Functional Verification
- [ ] All requirements from WO spec have tests
- [ ] All tests executed with real evidence
- [ ] PASS/FAIL status accurate for each test
- [ ] Database state verified where applicable
- [ ] Security checks completed
- [ ] Performance acceptable
- [ ] Issues filed for any failures

### Code Quality Verification (MANDATORY)

> Per `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-WO-METHODOLOGY.md`:
> passing tests are not production readiness.

- [ ] **Read through ALL changed files** — Line by line review completed
- [ ] **No debug logging** — no `console.log` statements or the equivalent in this stack; uses the project's logger
- [ ] **No magic numbers** — Extracted to configuration or constants
- [ ] **Proper typing** — No `any` types, proper validation
- [ ] **Error handling complete** — Clear messages, proper exception types
- [ ] **No dev fallbacks or debug code** — Cleaned up after implementation
- [ ] **Follows existing codebase patterns** — Consistent with project conventions

### Anti-Pattern Check
- [ ] **Not just "tests passing"** — Reviewed actual implementation quality
- [ ] **Reviewed whole implementation** — Not just incremental patches
- [ ] **Would deploy to production now** — No bandaids or workarounds

### Ready for Closeout
- [ ] All checklist items above completed
- [ ] Code quality meets production standards

---

## Sign-Off

Counts first, in this shape, so the tally can be read without reading the
document. Every number comes from a run; `Y` is the number of tests planned.

```
**Verification Status:**
- EXECUTED: X/Y tests
- PASSED: X/X tests
- FAILED: 0 tests
- Production Ready: YES/NO
```

**Verification Status:** [COMPLETE / PARTIAL / BLOCKED]

**Notes:**
[Any final notes for the closeout]

**This verification report confirms that WO-XXXX was tested according to the
Behavioral Testing Methodology. Every PASS represents captured execution
evidence, not an assumption. `wo verify --run` writes the status from the
suite's exit code; a status typed by hand is not evidence.**
