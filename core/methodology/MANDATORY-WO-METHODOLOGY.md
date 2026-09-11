# MANDATORY Work Order Methodology

> **THIS IS NON-NEGOTIABLE. ALL AI AGENTS MUST FOLLOW THIS METHODOLOGY.**

---

## CRITICAL: Production-Quality Code Only

> **ALL WORK MUST BE PRODUCTION-LEVEL. NO HALLUCINATIONS. NO PLACEHOLDER CODE.**

This is the most important rule in this entire project:

1. **NO HALLUCINATED CODE** - Never write code that you assume will work without verification
2. **NO PLACEHOLDER IMPLEMENTATIONS** - Every function must be complete and functional
3. **NO FAKE OUTPUTS** - Never claim tests pass without real execution evidence
4. **NO ASSUMPTIONS** - If you're unsure, investigate the codebase first
5. **VERIFY EVERYTHING** - Check that files, tables, and methods exist before referencing them

### What "Production-Level" Means

- Code is complete and handles all edge cases
- Error handling is implemented (not TODOs)
- Types are correct and complete
- Database queries reference real tables/columns
- Imports reference real files that exist
- Tests can actually execute against the real system

### What We Will NOT Accept

- `// TODO: implement this later`
- `throw new Error('Not implemented')`
- Code that references non-existent files/tables
- Test results that were not actually executed
- "Should work" without verification

**If you cannot verify something exists, ASK or INVESTIGATE first.**

---

## MANDATORY: Pre-Implementation Quality Checklist

> **Before writing ANY code, verify these requirements:**

### Configuration & Patterns
- [ ] **Using configuration/settings instead of hardcoded values** - No magic numbers
- [ ] **Following existing patterns in the codebase** - Consistency matters
- [ ] **Using proper Logger service** - Not console.log
- [ ] **Error handling with proper exception types** - Clear error messages

### Production Mindset Questions
- [ ] "Would I deploy this to production right now?"
- [ ] "Would a code reviewer approve this?"
- [ ] "Does this match the quality of the existing codebase?"

---

## MANDATORY: Self-Review Before Declaring Done

> **Complete ALL items before marking ANY work as complete:**

### Code Quality Review
- [ ] **Read through ALL changed files** - Line by line review
- [ ] **Removed ALL console.log statements** - Use Logger service instead
- [ ] **No magic numbers** - Extracted to configuration or constants
- [ ] **Proper typing** - No `any` types, proper validation
- [ ] **Error handling complete** - Clear messages, proper exception types

### Anti-Pattern Check (Lessons Learned)
- [ ] **Not just "tests passing"** - Reviewed actual implementation quality
- [ ] **Didn't just patch the immediate problem** - Reviewed whole implementation
- [ ] **Removed all debug/dev code** - After fixing issues
- [ ] **Followed project standards** - In CLAUDE.md

### Production Readiness
- [ ] Would deploy this to production right now
- [ ] Code reviewer would approve this
- [ ] Matches quality of existing codebase

---

## Anti-Patterns to Avoid (Documented Lessons)

These mistakes have caused rework on this project. **Do not repeat them:**

### 1. Test-Driven Tunnel Vision
- Tests passing ≠ production-ready code
- Don't stop when tests pass; review the implementation quality
- A passing test with bad code still ships bad code

### 2. Incremental Patching
- Don't just fix the immediate problem and move on
- Step back and review the whole implementation after changes
- Each fix should improve the overall quality, not just solve one issue

### 3. Expedience Over Quality
- Don't leave debug logging (console.log) in place
- Don't copy-paste values; abstract them properly
- Don't skip cleanup after fixing bugs

### 4. Ignoring Project Standards
- Re-read CLAUDE.md requirements before declaring work complete
- Follow the mandatory checklists in this document
- Production quality is non-negotiable

---

## Core Rule

**Every Work Order MUST have its own folder containing ALL required documents.**

Loose `.md` files in the parent directory are NOT acceptable. This is lazy and violates project standards.

---

## Required Documents (ALL MANDATORY)

When creating ANY work order, you MUST create ALL of these files:

### Core Documents (ALWAYS REQUIRED)

| File | Purpose | Required |
|------|---------|----------|
| `WO-XXXX-SPEC.md` | Technical specification with code | **YES** |
| `WO-XXXX-CHECKLIST.md` | Implementation checklist | **YES** |
| `WO-XXXX-TASK-BREAKDOWN.md` | Task breakdown with estimates | **YES** |
| `WO-XXXX-Prompt.md` | AI implementation prompt | **YES** |
| `WO-XXXX-CLOSEOUT.md` | Closeout report | **YES (on completion)** |
| `WO-XXXX-VERIFICATION.md` | Test verification report | **YES (before closeout)** |

### Specialized Documents (REQUIRED when applicable)

| File | Purpose | Required |
|------|---------|----------|
| `WO-XXXX-sdk-implementation.md` | SDK resource/method design | **YES (if SDK work)** |
| `WO-XXXX-ui-implementation.md` | UI component specifications | **YES (if UI work)** |

---

## Folder Structure

```
{{WORKORDERS_DIR}}/
├── WO-XXXX-[Descriptive-Name]/
│   ├── WO-XXXX-SPEC.md                 # Technical spec (REQUIRED)
│   ├── WO-XXXX-CHECKLIST.md            # Checklist (REQUIRED)
│   ├── WO-XXXX-TASK-BREAKDOWN.md       # Task breakdown (REQUIRED)
│   ├── WO-XXXX-Prompt.md               # AI prompt (REQUIRED)
│   ├── WO-XXXX-CLOSEOUT.md             # Closeout (on completion)
│   ├── WO-XXXX-sdk-implementation.md   # SDK design (if SDK work)
│   └── WO-XXXX-ui-implementation.md    # UI design (if UI work)
```

---

## Templates Location

All templates are in:
```
{{PIPELINE_ROOT}}/core/templates/workorders/
├── README.md                           # Template usage guide
├── WO-TEMPLATE-SPEC.md                 # Technical specification template (PREFERRED)
├── WO-TEMPLATE-MAIN.md                 # High-level spec (alternative for simple WOs)
├── WO-TEMPLATE-CHECKLIST.md            # Checklist template
├── WO-TEMPLATE-TASK-BREAKDOWN.md       # Task breakdown template
├── WO-TEMPLATE-PROMPT.md               # AI prompt template
├── WO-TEMPLATE-CLOSEOUT.md             # Closeout template
├── WO-TEMPLATE-SDK-IMPLEMENTATION.md   # SDK design template
└── WO-TEMPLATE-UI-IMPLEMENTATION.md    # UI design template
```

---

## Gold Standard Examples

When in doubt, reference these properly structured work orders:

Any promoted work order in your pack with a complete `SCTPVC` lifecycle. `pack index` lists them by completeness.

---

## Validation Before Creating a Work Order

Before you consider a work order "created", you MUST verify:

### Core Documents (ALWAYS)
1. [ ] Created folder: `WO-XXXX-[Descriptive-Name]/`
2. [ ] Created technical spec: `WO-XXXX-SPEC.md`
3. [ ] Created checklist: `WO-XXXX-CHECKLIST.md`
4. [ ] Created task breakdown: `WO-XXXX-TASK-BREAKDOWN.md`
5. [ ] Created prompt: `WO-XXXX-Prompt.md`

### Specialized Documents (when applicable)
6. [ ] Created SDK implementation: `WO-XXXX-sdk-implementation.md` (if SDK work)
7. [ ] Created UI implementation: `WO-XXXX-ui-implementation.md` (if UI work)

### Content Quality
8. [ ] All placeholders filled in with real content
9. [ ] Dependencies documented
10. [ ] Success criteria defined
11. [ ] File locations specified

---

## What Happens If You Don't Follow This

1. Work will be rejected
2. You will be asked to redo it properly
3. Time wasted for everyone

---

## Why This Matters

1. **Traceability** - Every piece of work is documented
2. **Reproducibility** - Any AI agent can pick up the work
3. **Quality** - Checklists ensure nothing is missed
4. **Auditability** - Closeouts prove work was completed
5. **Consistency** - All work follows the same pattern

---

## AI Agent Instructions

When asked to create a work order:

1. **FIRST**: Create the folder: `WO-XXXX-[Descriptive-Name]/`
2. **THEN**: Create `WO-XXXX-SPEC.md` using `WO-TEMPLATE-SPEC.md`
3. **THEN**: Create `WO-XXXX-CHECKLIST.md` using `WO-TEMPLATE-CHECKLIST.md`
4. **THEN**: Create `WO-XXXX-TASK-BREAKDOWN.md` using `WO-TEMPLATE-TASK-BREAKDOWN.md`
5. **THEN**: Create `WO-XXXX-Prompt.md` using `WO-TEMPLATE-PROMPT.md`
6. **IF SDK WORK**: Also create `WO-XXXX-sdk-implementation.md` using `WO-TEMPLATE-SDK-IMPLEMENTATION.md`
7. **IF UI WORK**: Also create `WO-XXXX-ui-implementation.md` using `WO-TEMPLATE-UI-IMPLEMENTATION.md`
8. **USE**: The templates in `_TEMPLATES/`
9. **NEVER**: Create loose `.md` files in parent directories
10. **ALWAYS**: Fill in all sections - no placeholders left behind

---

## Series Work Orders

For work order SERIES (e.g., WO-3200 Series):

1. Create a series folder: `WO-1200-Series-[Theme]/`
2. Create a series index: `WO-1200-SERIES-INDEX.md`
3. **EACH individual WO still needs its own folder within:**

```
WO-1200-Series-Reporting/
├── WO-1200-SERIES-INDEX.md
├── WO-1201-Report-Data-Model/
│   ├── WO-1201-Report-Data-Model.md
│   ├── WO-1201-CHECKLIST.md
│   ├── WO-1201-TASK-BREAKDOWN.md
│   └── WO-1201-Prompt.md
├── WO-1202-Report-Ingestion-Service/
│   ├── WO-1202-Report-Ingestion-Service.md
│   ├── WO-1202-CHECKLIST.md
│   └── ...
```

---

## MANDATORY: Testing Before Closeout

> **NO WORK ORDER CAN BE CLOSED WITHOUT BEHAVIORAL TEST VERIFICATION.**

Before ANY closeout can be completed:

### Testing Requirements

1. **Create Behavioral Tests**
   - Create test suite: `{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh`
   - Follow the Behavioral Testing Methodology
   - Reference: `{{TESTING_DIR}}/MANDATORY-TESTING-METHODOLOGY.md`

2. **Execute Tests**
   - Run tests against live system (API + database)
   - Capture real output as evidence
   - Document in execution report

3. **Create Verification Report**
   - Use template: `{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-VERIFICATION.md`
   - Map test results to WO requirements
   - Include in WO folder as `WO-XXXX-VERIFICATION.md`

4. **All Tests Must Pass**
   - `EXECUTED — PASS` with real evidence
   - No `NOT EXECUTED — PLAN ONLY` for critical paths
   - No `EXECUTED — FAIL` without remediation

### Closeout Blockers

A closeout WILL BE REJECTED if:

- [ ] No behavioral tests created
- [ ] Tests not executed (PLAN ONLY status)
- [ ] Tests failed without remediation
- [ ] No verification report in WO folder
- [ ] Evidence is hallucinated (not real execution)

### Testing Documentation Location

```
{{TESTING_DIR}}/
├── MANDATORY-TESTING-METHODOLOGY.md   # READ THIS FIRST
├── _TEMPLATES/                         # Test templates
├── suites/                             # Test suites
│   └── wo-XXXX-feature-name.sh        # Your WO test suite
└── test-results/                       # Execution reports
```

---

**NO EXCEPTIONS. THIS IS THE STANDARD.**
