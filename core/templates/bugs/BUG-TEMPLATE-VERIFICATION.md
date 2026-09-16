# BUG-XXXX: [Title] - Verification Report

**Bug:** BUG-XXXX
**Defect:** [One line: what went wrong]
**Verification Date:** YYYY-MM-DD
**Verified By:** [Name/Agent]

---

## Verification Summary

A bug is verified when three things are true, in this order: it reproduced
before the fix, it stops reproducing after it, and something now fails if the
defect ever comes back.

| Claim | Checks | Status |
|-------|--------|--------|
| Reproduction confirmed before the fix | 1.1 | VERIFIED |
| Reproduction no longer reproduces after the fix | 2.1, 2.2 | VERIFIED |
| Regression check added | 3.1 | VERIFIED |
| Nothing adjacent broke | 4.1 | PARTIAL |

**Overall Status:** [VERIFIED / PARTIAL / BLOCKED]

---

## Reproduction Traceability

Every claim below names where it came from and what was run. When the suite
prints a line per check, the driver keeps those lines in the Execution Record
and the mapping is read straight off them; when it prints only a verdict, the
mapping is traced from the suite's source and this section must say so.

### 1. Reproduction confirmed before the fix

**Source:** BUG-XXXX issue document, Steps to Reproduce

**Checks:**
- Check 1.1: [What was run against the unfixed code] — REPRODUCED

**Evidence Summary:**
- Observed: [the wrong behaviour, quoted from real output]
- Expected: [what should have happened]
- [Where the defect was reached from — entry point, input, state]

**Status:** VERIFIED — the defect was real and observable

---

### 2. Reproduction no longer reproduces after the fix

**Source:** the fix in [file or component]

**Checks:**
- Check 2.1: [The same steps, re-run against the fixed code] — PASS
- Check 2.2: [The boundary case the fix turns on] — PASS

**Evidence Summary:**
- Observed after the fix: [real output]
- [Underlying state is now correct: what was inspected and what it showed]

**Status:** VERIFIED

---

### 3. Regression check added

**Source:** `{{TESTING_DIR}}/suites/bug-XXXX-[slug].sh`

**Checks:**
- Check 3.1: [The check that fails if the defect returns] — PASS

**Evidence Summary:**
- The check was seen to fail against the unfixed code: [how that was shown]
- It is listed in the manifest under tier `[tier]`, type `[type]`, so a
  regression run executes it

**Status:** VERIFIED

---

### 4. Nothing adjacent broke — PARTIAL

**Source:** [The behaviour nearest the change]

**Checks:**
- Check 4.1: [What was run] — FAIL

**Issue:**
- [What failed]
- [Related bug, if one was filed]

**Remediation:** [What still has to happen]

**Status:** PARTIAL — Requires follow-up

---

## Root Cause

**Cause:** [Why the code behaved that way — the mechanism, not the symptom]

**Why it was not caught:** [The gap that let it ship]

**Blast radius:** [Everything else reached by the same code path, and whether
each was checked]

---

## Test Execution References

| Document | Location |
|----------|----------|
| Bug report | `{{BUGS_DIR}}/BUG-XXXX-<slug>/BUG-XXXX-<slug>.md` |
| Execution results | `{{TESTING_DIR}}/results/bug-XXXX-execution-YYYYMMDD.md` |
| Regression suite | `{{TESTING_DIR}}/suites/bug-XXXX-<slug>.sh` |

---

## Security Verification

<!-- Every row is [status] until something ran. Write N/A where a check does not apply; never leave a PASS you did not execute. -->

| Check | Status | Evidence |
|-------|--------|----------|
| Fix introduces no new authentication gap | [status] | [evidence, or N/A] |
| Authorization still enforced on the changed path | [status] | [evidence, or N/A] |
| Input validation unchanged or tightened | [status] | [evidence, or N/A] |
| No data exposed that was not exposed before | [status] | [evidence, or N/A] |

---

## Performance Verification

Only when the defect or its fix touches cost. Otherwise write N/A.

| Metric | Before the fix | After the fix | Status |
|--------|----------------|---------------|--------|
| [Metric that mattered] | [measured, or N/A] | [measured, or N/A] | [status] |

---

## Outstanding Items

### Blockers

None — the defect no longer reproduces and a regression check covers it.

### Known Limitations

1. [Limitation accepted with the fix]

### Follow-Up Required

1. [Item requiring follow-up]
   - Owner: [Name]
   - Target: [Date/BUG or WO]

---

## Verification Checklist

### Defect Verification
- [ ] The reproduction was observed before the fix, not assumed
- [ ] The same reproduction was re-run after the fix
- [ ] A regression check exists and was seen to fail without the fix
- [ ] The regression check is listed in the suite manifest
- [ ] Underlying state verified where applicable, not only the response
- [ ] Root cause named — a symptom suppressed is not a bug fixed
- [ ] Behaviour adjacent to the change was checked

### Code Quality Verification (MANDATORY)

> Per `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-BUG-METHODOLOGY.md`:
> a passing check is not a finished fix.

- [ ] **Read through ALL changed files** — Line by line review completed
- [ ] **No debug logging left from the hunt** — uses the project's logger
- [ ] **No magic numbers** — Extracted to configuration or constants
- [ ] **Proper typing** — No `any` types, proper validation
- [ ] **Error handling complete** — Clear messages, proper exception types
- [ ] **Follows existing codebase patterns** — Consistent with project conventions

### Anti-Pattern Check
- [ ] **Not a suppressed symptom** — the cause was addressed
- [ ] **Not a local patch** — the whole code path was reviewed, not one branch
- [ ] **Would deploy to production now** — No bandaids or workarounds

### Ready for Closeout
- [ ] All checklist items above completed
- [ ] Fix quality meets production standards

---

## Sign-Off

**Verification Status:** [COMPLETE / PARTIAL / BLOCKED]

**Notes:**
[Any final notes for the closeout]

**This verification report confirms that BUG-XXXX was reproduced, fixed, and
covered against return, according to the Behavioral Testing Methodology. Every
PASS represents captured execution evidence, not an assumption. `bug verify
--run` writes the status from the suite's exit code; a status typed by hand is
not evidence.**
