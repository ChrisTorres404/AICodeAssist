# WO-XXXX: [Feature Name] - Verification Report (UI)

**Work Order:** WO-XXXX
**Feature:** [Feature Name]
**Verification Date:** YYYY-MM-DD
**Verified By:** [Name/Agent]

---

## Verification Summary

Evidence here is what the browser rendered: an element that is present, text
that matches, a route that was reached, a control that took focus from the
keyboard, a screenshot that was kept. A component that compiles is not a
component that renders.

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
- The confirmation panel is visible once the form is submitted
- Its heading text matches the copy the spec asks for
- Screenshot recorded beside the run

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED]

---

### Requirement 2: [Requirement Description]

**Source:** WO-XXXX-SPEC.md, Section Y

**Tests:**
- Test 2.1: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]
- Test 2.2: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]
- Test 2.3: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]

**Evidence Summary:**
- Submitting an empty required field renders the field-level error
- The invalid field is marked so assistive technology announces it
- Nothing is submitted and the route does not change

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED]

---

### Requirement 3: [Requirement Description]

**Source:** WO-XXXX-SPEC.md, Section Z

**Tests:**
- Test 3.1: [Description] — [EXECUTED — PASS | EXECUTED — FAIL | NOT EXECUTED — PLAN ONLY]

**Evidence Summary:**
- Activating the primary control lands on the route the spec names
- The view for that route rendered: [what proves it, not just the URL]

**Status:** [VERIFIED | PARTIAL | NOT VERIFIED]

---

### Requirement 4: [Requirement Description] — PARTIAL

**Source:** WO-XXXX-SPEC.md, Section W

**Tests:**
- Test 4.1: [Description] — FAIL

**Issue:**
- [What rendered instead, or what never rendered]
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
| Screenshots | `{{TESTING_DIR}}/results/wo-XXXX-screens/` |

---

## Critical Path Verification

### Happy Path: [Primary Use Case]

1. User opens `[route]` and the view renders — VERIFIED
2. User performs [interaction] — VERIFIED
3. The interface shows [the expected change] — VERIFIED
4. Reloading the page keeps that state — VERIFIED

### Error Path: [Error Scenario]

1. User provides invalid [input] — VERIFIED
2. The message [expected copy] is shown next to the field — VERIFIED
3. Nothing else on the page changes — VERIFIED

---

## Rendering and Accessibility Verification

<!-- Every row is [status] until something ran. Write N/A where a check does not apply; never leave a PASS you did not execute. -->

| Check | Status | Evidence |
|-------|--------|----------|
| Every interactive control is keyboard reachable, in visual order | [status] | [evidence, or N/A] |
| Text contrast meets the target ratio | [status] | [evidence, or N/A] |
| Controls carry accessible names | [status] | [evidence, or N/A] |
| No console errors or warnings during the flow | [status] | [evidence, or N/A] |
| Renders at the narrowest supported width | [status] | [evidence, or N/A] |

---

## Security Verification

| Check | Status | Evidence |
|-------|--------|----------|
| Authenticated routes redirect when signed out | [status] | [evidence, or N/A] |
| Controls absent for roles that may not use them | [status] | [evidence, or N/A] |
| User-supplied content renders as text, not markup | [status] | [evidence, or N/A] |
| No secrets or internal detail in the shipped bundle | [status] | [evidence, or N/A] |

---

## Performance Verification

| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| First render of the view | [target] | [measured, or not measured] | [status] |
| Interaction to visible response | [target] | [measured, or not measured] | [status] |

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
- [ ] All tests executed against a running build, with real evidence
- [ ] PASS/FAIL status accurate for each test
- [ ] Rendered output asserted, not only that the component mounted
- [ ] Keyboard and contrast checks completed
- [ ] No console errors during any verified flow
- [ ] Screenshots kept for anything a reviewer would want to see
- [ ] Issues filed for any failures

### Code Quality Verification (MANDATORY)

> Per `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-WO-METHODOLOGY.md`:
> passing tests are not production readiness.

- [ ] **Read through ALL changed files** — Line by line review completed
- [ ] **No debug logging** — uses the project's logger
- [ ] **No magic numbers** — spacing, breakpoints and colours come from the design tokens
- [ ] **Proper typing** — No `any` types, props and state typed
- [ ] **Error and empty states handled** — loading, empty, and failure all render
- [ ] **No dev fallbacks or placeholder copy** — Cleaned up after implementation
- [ ] **Follows existing component patterns** — Consistent with project conventions

### Anti-Pattern Check
- [ ] **Not just "it compiles"** — Reviewed what the browser actually renders
- [ ] **Reviewed whole implementation** — Not just incremental patches
- [ ] **Would deploy to production now** — No bandaids or workarounds

### Ready for Closeout
- [ ] All checklist items above completed
- [ ] Code quality meets production standards

---

## Sign-Off

**Verification Status:** [COMPLETE / PARTIAL / BLOCKED]

**Notes:**
[Any final notes for the closeout]

**This verification report confirms that WO-XXXX was tested according to the
Behavioral Testing Methodology. Every PASS represents captured execution
evidence, not an assumption. `wo verify --run` writes the status from the
suite's exit code; a status typed by hand is not evidence.**
