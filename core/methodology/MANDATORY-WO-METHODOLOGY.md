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
- [ ] **Using the project's logger** - No debug printing left in source
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
- [ ] **Removed ALL debug logging** - Use the project's logger at the right level
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
- Don't leave debug logging in place
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

The `wo` driver creates the folder and every document the work order's size
requires. Do not assemble one by hand:

```bash
wo new "<title>" --size trivial|small|standard|large --area <area> --priority P1
```

---

## Size Sets the Ceremony

A two-line fix does not need four documents. State the size you chose and why.

| Size | Created at open | Always required to close |
|---|---|---|
| `trivial` | one document | VERIFICATION |
| `small` | SPEC | VERIFICATION |
| `standard` (default) | SPEC, CHECKLIST, TASK-BREAKDOWN, Prompt | VERIFICATION |
| `large` | the standard set plus the SDK and UI implementation documents | VERIFICATION |

The verification requirement never relaxes at any size.

---

## Required Documents (ALL MANDATORY)

At `standard` size, all of these exist:

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

## Validation Before a Work Order Counts as Created

`wo status <number>` prints which documents exist and which are missing. Use
it; do not eyeball the folder.

### Structure
1. [ ] Folder exists: `WO-XXXX-[Descriptive-Name]/`
2. [ ] Every document the chosen size requires is present
3. [ ] The SDK implementation document exists, if the work has an SDK layer
4. [ ] The UI implementation document exists, if the work has a UI layer

### Content quality
5. [ ] Every placeholder is replaced with real content
6. [ ] Dependencies are named
7. [ ] Success criteria are stated in terms someone else could test
8. [ ] File locations are real paths that exist, or are explicitly new
9. [ ] The area, priority, and owner are recorded

A folder full of unfilled template headings is not a work order. It is a
folder.

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

1. **Search first.** `pack search "<problem>"`. A solved, tested, closed-out
   work order beats a blank template, and its pitfalls are already written
   down.
2. **Open it with the driver.** `wo new "<title>" --size <size> --area <area>`
   creates the folder, numbers it, renders every required document, and
   records the routing. Never hand-assemble the folder.
3. **Fill in the SPEC before writing any code.** A spec written afterwards is
   a description, not a specification.
4. **Add the specialized documents** when the work has an SDK layer
   (`--sdk`) or a UI layer (`--ui`).
5. **Replace every placeholder** with real, verified content.
6. **Never create a loose `.md`** beside the work-order directory.
7. **Track state with the driver**: `wo start`, `wo block <n> "<reason>"`,
   `wo note <n> "<text>"`, `wo status <n>`.

---

## Numbering and Series

Work orders are numbered by the driver. `wo new` takes the next free number;
`--series N` starts or continues a numbered band, so related work stays
together without any index file to maintain:

```bash
wo new "Report data model"        --series 1200
wo new "Report ingestion service" --series 1200    # becomes the next 12xx
```

`wo list` and `wo stats` are the index. There is no separate series document
to keep in sync, and no folder nests inside another — every work order is a
sibling directory with its own number.

Bugs work the same way, except that the band is chosen for you by the
category, which also records the routing. See
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-BUG-METHODOLOGY.md`.

---

## MANDATORY: Testing Before Closeout

> **NO WORK ORDER CAN BE CLOSED WITHOUT BEHAVIORAL TEST VERIFICATION.**

Before ANY closeout can be completed:

### Testing Requirements

1. **Create behavioral tests**
   - Suite path: `{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh`
   - Follow `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`

2. **Execute them**
   - Against the running system and its real data store
   - Capture the real output as evidence

3. **Let the driver record the result**

   ```bash
   wo verify <number> --run {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
   ```

   `wo verify --run` executes the suite and writes `EXECUTED — PASS` or
   `EXECUTED — FAIL` into `WO-XXXX-VERIFICATION.md` from the exit code, so
   nobody types a status by hand. Format:
   `{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-VERIFICATION.md`.

4. **Map results to requirements.** Every success criterion in the SPEC points
   at the test that proves it.

5. **All tests pass**
   - `EXECUTED — PASS` with real evidence
   - No `NOT EXECUTED — PLAN ONLY` on a critical path
   - No `EXECUTED — FAIL` left unremediated

### Closeout Blockers

`wo close` refuses to produce a closeout without a VERIFICATION document. Do
not route around the guard — it is the only thing making evidence
non-optional. A closeout is rejected in review if:

- [ ] No behavioral tests were created
- [ ] Tests were never executed (PLAN ONLY)
- [ ] Tests failed and nothing was done about it
- [ ] There is no verification document in the folder
- [ ] The evidence was written rather than captured

### Where testing material lives

```
{{TESTING_DIR}}/
├── suites/                             # test suites
│   └── wo-XXXX-feature-name.sh
└── results/                            # execution reports
```

Methodology, templates, and the shared framework come from the pipeline:
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`,
`{{PIPELINE_ROOT}}/core/templates/testing/`, and
`{{PIPELINE_ROOT}}/harness/`.

---

**NO EXCEPTIONS. THIS IS THE STANDARD.**
