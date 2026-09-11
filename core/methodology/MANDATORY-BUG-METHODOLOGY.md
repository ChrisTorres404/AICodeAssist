# MANDATORY Bug Tracking Methodology

> **THIS IS NON-NEGOTIABLE. ALL AI AGENTS MUST FOLLOW THIS METHODOLOGY.**

---

## CRITICAL: Production-Quality Fixes Only

> **ALL BUG FIXES MUST BE PRODUCTION-LEVEL. NO HALLUCINATIONS. NO PLACEHOLDER CODE.**

This is the most important rule in this entire project:

1. **NO HALLUCINATED FIXES** - Never write code that you assume will work without verification
2. **NO PARTIAL FIXES** - Every fix must be complete and address the root cause
3. **NO FAKE VERIFICATION** - Never claim bugs are fixed without real test evidence
4. **NO ASSUMPTIONS** - If you're unsure about the cause, investigate first
5. **VERIFY THE FIX** - Test against the live system, not just in your head

### What "Production-Level" Means for Bug Fixes

- Fix addresses the actual root cause, not symptoms
- All edge cases are handled
- No new issues introduced
- Regression tests prove the fix works
- Fix can be verified by real system execution

### What We Will NOT Accept

- `// HACK: workaround for BUG-XXXX`
- Fixes that assume they work without testing
- Fixes that break other functionality
- "This should fix it" without verification
- Closeouts without test execution evidence

**If you cannot reproduce the bug, investigate further before attempting a fix.**

---

## Core Rule

**Every Bug MUST have its own folder containing ALL required documents.**

Loose `.md` files in the parent directory are NOT acceptable. This is lazy and violates project standards.

---

## Required Documents (ALL MANDATORY)

When documenting ANY bug, you MUST create ALL of these files:

### Core Documents (ALWAYS REQUIRED)

| File | Purpose | Required |
|------|---------|----------|
| `BUG-XXXX-[slug].md` | Bug issue document with analysis | **YES** |
| `BUG-XXXX-[slug]-CLOSEOUT.md` | Closeout report | **YES (on fix completion)** |
| `BUG-XXXX-VERIFICATION.md` | Test verification evidence | **YES (before closeout)** |

### Specialized Documents (REQUIRED when applicable)

| File | Purpose | Required |
|------|---------|----------|
| `BUG-XXXX-Prompt.md` | AI fix implementation prompt | **YES (for complex bugs)** |
| `BUG-XXXX-TESTPLAN.md` | Detailed test plan | **YES (if extensive testing)** |
| `BUG-XXXX-ADDENDUM.md` | Additional notes/known behaviors | **If needed** |

---

## Folder Structure

```
{{BUGS_DIR}}/
├── BUG-XXXX-[slug]/
│   ├── BUG-XXXX-[slug].md                # Bug issue document (REQUIRED)
│   ├── BUG-XXXX-[slug]-CLOSEOUT.md       # Closeout report (on completion)
│   ├── BUG-XXXX-Prompt.md                # AI prompt (for complex bugs)
│   ├── BUG-XXXX-TESTPLAN.md              # Test plan (if extensive testing)
│   └── BUG-XXXX-ADDENDUM.md              # Additional notes (if needed)
```

---

## Templates Location

All templates are in:
```
{{PIPELINE_ROOT}}/core/templates/bugs/
├── README.md                             # Template usage guide
├── BUG-TEMPLATE-ISSUE.md                 # Bug issue template
├── BUG-TEMPLATE-CLOSEOUT.md              # Closeout template
└── BUG-TEMPLATE-PROMPT.md                # AI prompt template
```

---

## Gold Standard Examples

When in doubt, reference these properly structured bug reports:

1. **BUG-0001-login-analytics-timezone-mismatch/** - Complete with issue + closeout
2. **BUG-0007-rate-limit-forced-logout/** - Complete with issue + closeout
3. **BUG-0006-health-check-pool-saturation/** - Includes addendum for known behavior

---

## Bug Severity Levels

| Severity | Description | Response Time |
|----------|-------------|---------------|
| **Critical** | System down, data loss, security breach | Immediate |
| **High** | Major feature broken, significant user impact | Same day |
| **Medium** | Feature degraded, workaround exists | Within sprint |
| **Low** | Minor issue, cosmetic, edge case | Backlog |

---

## Bug Status Workflow

```
Open → In Progress → Fixed → Verified → Closed
                  ↓
              Won't Fix / Duplicate / By Design
```

| Status | Description |
|--------|-------------|
| **Open** | Bug reported, awaiting triage |
| **In Progress** | Developer actively working on fix |
| **Fixed** | Code changes complete, awaiting verification |
| **Verified** | QA confirmed fix works |
| **Closed** | Bug resolved and closeout complete |
| **Won't Fix** | Intentionally not fixing (documented reason) |
| **Duplicate** | Same as another bug (link to original) |
| **By Design** | Behavior is intentional (documented reason) |

---

## Validation Before Creating a Bug Report

Before you consider a bug report "created", you MUST verify:

### Core Documents (ALWAYS)
1. [ ] Created folder: `BUG-XXXX-[slug]/`
2. [ ] Created issue document: `BUG-XXXX-[slug].md`
3. [ ] Metadata table filled in completely
4. [ ] Reproduction steps documented
5. [ ] Expected vs actual behavior documented

### Content Quality
6. [ ] Root cause analysis (if known)
7. [ ] Related WO(s) identified
8. [ ] Files to modify identified
9. [ ] Impact assessment complete
10. [ ] Screenshots/logs included (if applicable)

---

## What Happens If You Don't Follow This

1. Bug fix will be rejected
2. You will be asked to document it properly
3. Time wasted for everyone
4. Audit trail is incomplete

---

## Why This Matters

1. **Traceability** - Every bug is linked to work orders
2. **Reproducibility** - Any developer can reproduce the issue
3. **Quality** - Root cause analysis prevents recurrence
4. **Auditability** - Closeouts prove bugs were properly fixed
5. **Consistency** - All bugs follow the same pattern
6. **Prevention** - Post-mortems help prevent future bugs

---

## AI Agent Instructions

When asked to document or fix a bug:

1. **FIRST**: Create the folder: `BUG-XXXX-[slug]/`
2. **THEN**: Create `BUG-XXXX-[slug].md` using `BUG-TEMPLATE-ISSUE.md`
3. **IF COMPLEX**: Create `BUG-XXXX-Prompt.md` using `BUG-TEMPLATE-PROMPT.md`
4. **ON COMPLETION**: Create `BUG-XXXX-[slug]-CLOSEOUT.md` using `BUG-TEMPLATE-CLOSEOUT.md`
5. **USE**: The templates in `_TEMPLATES/`
6. **NEVER**: Create loose `.md` files in parent directories
7. **ALWAYS**: Fill in all sections - no placeholders left behind
8. **ALWAYS**: Link to related Work Order(s)

---

## Bug Numbering

| Range | Theme |
|-------|-------|
| 0001-0099 | Auth & Session bugs |
| 0100-0199 | API & SDK bugs |
| 0200-0299 | Database & Migration bugs |
| 0300-0399 | UI & Frontend bugs |
| 0400-0499 | Observability & Metrics bugs |
| 0500-0599 | Security bugs |
| 0600-0699 | Performance bugs |
| 0700-0799 | Integration bugs |
| 0800-0899 | Configuration bugs |
| 0900-0999 | Documentation bugs |
| 1000+ | Overflow / Misc |

**Current highest bug number:** Check existing bugs and increment.

---

## Relationship to Work Orders

Every bug fix should reference the original Work Order that introduced the behavior:

```
BUG-XXXX → references → WO-YYYY (original implementation)
BUG-XXXX → may spawn → WO-ZZZZ (if fix requires significant work)
```

### When to Create a New Work Order for a Bug Fix

Create a WO if the fix:
- Requires architectural changes
- Takes more than 4 hours
- Affects multiple modules
- Needs stakeholder approval
- Introduces new features as part of the fix

---

## Code Annotation Standard

After fixing a bug, add comments linking both the original WO and the bug:

```typescript
// WO-XXXX: Original feature implementation
// BUG-YYYY: Fixed [brief description of what was fixed]
// Summary: [one line explaining the fix or constraint]
```

---

## MANDATORY: Testing Before Closeout

> **NO BUG FIX CAN BE CLOSED WITHOUT BEHAVIORAL TEST VERIFICATION.**

Before ANY closeout can be completed:

### Testing Requirements

1. **Reproduce the Bug**
   - Document reproduction steps with actual execution
   - Capture error state before fix
   - Evidence must be real, not assumed

2. **Verify the Fix**
   - Execute the same steps after fix
   - Capture successful state as evidence
   - Prove the bug no longer occurs

3. **Regression Testing**
   - Verify related functionality still works
   - Run affected test suites
   - Document any side effects

4. **Create Verification Document**
   - Include before/after evidence
   - Reference test execution output
   - Use: `{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-VERIFICATION.md`

### Closeout Blockers

A bug closeout WILL BE REJECTED if:

- [ ] No reproduction evidence captured
- [ ] No fix verification evidence
- [ ] Verification was assumed, not executed
- [ ] Regression tests not run
- [ ] Evidence is hallucinated (not real execution)

### Testing Documentation Location

```
{{TESTING_DIR}}/
├── MANDATORY-TESTING-METHODOLOGY.md   # READ THIS FIRST
├── _TEMPLATES/                         # Test templates
├── suites/                             # Test suites
└── test-results/                       # Execution reports
```

---

**NO EXCEPTIONS. THIS IS THE STANDARD.**