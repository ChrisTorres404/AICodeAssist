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

## Code Comment Standards (MANDATORY)

**Every code change carries a header comment naming the work order.** This is
how a reader six months later learns why a line exists without guessing, and
how a change is traced back to the decision that produced it.

```
/**
 * WO-XXXX: [Work order title]
 * DATE: YYYY-MM-DD
 * WHAT: [what is being added or changed]
 * WHY: [the business or technical reason]
 * DATA: [which fields, tables, or records are affected]
 * IMPACT: [who or what is affected by this change]
 */
```

Use the comment syntax of the language you are in; the six fields do not
change. Example:

```
# WO-XXXX: Social sign-in — external identity provider
# DATE: YYYY-MM-DD
# WHAT: Added an external identity provider strategy to the auth module
# WHY: Users can sign in with an existing account instead of a new password
# DATA: Creates linked-identity records, joined to the existing user record
# IMPACT: All users — adds an alternative sign-in path; no change to existing sessions
```

A bug fix adds the bug number alongside the original work order. That form is
in `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-BUG-METHODOLOGY.md`.

---

## UI Component Standards (MANDATORY)

Every UI component produced by a work order:

1. **Uses the project's component primitives** — the existing button, input,
   card, dialog, and table components — rather than new one-off markup.
2. **Uses the project's styling system** and its design tokens. No ad-hoc
   values, no parallel stylesheet.
3. **Is reusable**: takes props, hardcodes nothing a caller should decide.
4. **Follows the patterns already in the codebase.** Find the nearest existing
   component of the same kind and follow it. Name it in the SPEC.
5. **Carries the `WO-XXXX` comment block** from the section above.
6. **Is accessible**: labelled controls, keyboard reachable, meaningful roles.
7. **Supports every theme the project ships**, dark mode included.
8. **Handles loading, empty, and error states**, not only the success path.

---

## Correct Folders (Always Use These)

Everything a work order produces lives under one configured root. The paths
below are rendered from `pipeline.config.sh` at install time, so they are the
real paths in this project, not an example.

### Active work orders (current work)

```
{{WORKORDERS_DIR}}/
```

**Purpose:** the working record; this is where an agent reads for context on
current work.
**When to use:** all active work, and anything in progress.

### Completed work orders (closed)

```
{{WORKORDERS_DIR}}/           # the folder stays put; the state changes
```

**Purpose:** historical reference for work that is finished.
**When to use:** after `wo close`. A closed work order is not moved to another
directory and not archived by hand — `wo close` records the state in the
work order itself, and `wo list --closed` retrieves it. The folder keeps its
number forever so that every commit message, comment, and suite that cites it
still resolves.

### Archive (legacy records, reference only)

```
{{WORKORDERS_DIR}}/           # adopted records carry status: migrated
```

**Purpose:** engineering records that predate this pipeline.
**When to use:** historical reference only. Bring one in with
`wo adopt <file.md> --number N --status migrated`, which records it as history
and marks it never verified. Do not retro-fit evidence onto it.

### Do not use

Any other directory. A work order outside `{{WORKORDERS_DIR}}` is invisible to
`wo list`, to the commit-traceability hook, and to `wo stats`, which means it
is invisible to everyone but its author.

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

`standard` is the default size, and it is exactly the four mandatory documents
below: SPEC, CHECKLIST, TASK-BREAKDOWN, and Prompt. That is the baseline this
methodology asks for, and `wo new "<title>"` with no `--size` produces it.

`trivial` and `small` are an explicit, recorded reduction in ceremony, chosen
by the person opening the work order and visible in the work order itself. They
are not a default that quietly applies to small-looking work, and they are not
a way to skip the spec on work that turns out not to be trivial — if the scope
grows, open it at the right size rather than closing it at the wrong one.

The closeout guard applies at every size without exception. `trivial` still
needs a VERIFICATION document before `wo close` will produce a closeout, and
the verification still has to be a real execution.

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

Any promoted work order in your playbooks with a complete `SCTPVC` lifecycle. `playbook index` lists them by completeness.

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

1. **Search first.** `playbook search "<problem>"`. A solved, tested, closed-out
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

At `standard` size the driver renders these four, each from its named template.
Check them by name before calling the work order created:

| Order | Document | Rendered from |
|---|---|---|
| 1 | `WO-XXXX-SPEC.md` | `WO-TEMPLATE-SPEC.md` |
| 2 | `WO-XXXX-CHECKLIST.md` | `WO-TEMPLATE-CHECKLIST.md` |
| 3 | `WO-XXXX-TASK-BREAKDOWN.md` | `WO-TEMPLATE-TASK-BREAKDOWN.md` |
| 4 | `WO-XXXX-Prompt.md` | `WO-TEMPLATE-PROMPT.md` |

And when they apply:

| Condition | Document | Rendered from |
|---|---|---|
| The work has an SDK layer | `WO-XXXX-sdk-implementation.md` | `WO-TEMPLATE-SDK-IMPLEMENTATION.md` |
| The work has a UI layer | `WO-XXXX-ui-implementation.md` | `WO-TEMPLATE-UI-IMPLEMENTATION.md` |

Always use the templates in `{{PIPELINE_ROOT}}/core/templates/workorders/`.
Never create loose `.md` files in a parent directory. Always fill in every
section — no placeholders left behind.

---

## Numbering and Series

### Series work orders

When a body of work is large enough to be broken into several work orders that
share a theme, it becomes a SERIES. The rules for a series are:

1. Give the series its own numbered band and theme name, for example a
   `WO-1200 Series`.
2. Create a series index that lists every work order in the band, its status,
   and the dependencies between them.
3. **Each individual work order in the series still gets its own folder with
   its own full document set.** A series is not an excuse to put five work
   orders' worth of content into one file.

```
WO-1200-Series-Usage-Reporting/
├── WO-1200-SERIES-INDEX.md
├── WO-1201-Unified-Usage-Data-Model/
│   ├── WO-1201-SPEC.md
│   ├── WO-1201-CHECKLIST.md
│   ├── WO-1201-TASK-BREAKDOWN.md
│   └── WO-1201-Prompt.md
├── WO-1202-Usage-Ingestion-Service/
│   ├── WO-1202-SPEC.md
│   ├── WO-1202-CHECKLIST.md
│   └── ...
```

### How the driver does it

`wo` implements that rule without the nesting and without a hand-maintained
index file. Work orders are numbered by the driver: `wo new` takes the next
free number, and `--series N` starts or continues the numbered band, so related
work stays together by number:

```bash
wo new "Report data model"        --series 1200     # becomes WO-1201
wo new "Report ingestion service" --series 1200     # becomes the next free 12xx
wo list --active                                    # the band, in order
```

Every work order remains a sibling directory with its own number and its own
complete document set — the rule above, unchanged. What the driver removes is
the index file: `wo list` and `wo stats` derive the index from the work orders
themselves, so it cannot drift from what actually exists. If a written index is
wanted for a reader outside the repository, generate it rather than maintaining
it:

```bash
wo list --active > {{WORKORDERS_DIR}}/WO-1200-SERIES-INDEX.md
```

For a batch of series work orders that has to land together, open the
integration work order that covers them and close it last:

```bash
wo integrate "Usage reporting integration" --covers 1201,1202,1203
```

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

## Work Order Workflow (Mandatory)

Four requests, four exact sequences. Every state change goes through the
driver, so the record is produced by the act rather than written about it
afterwards.

### When the request is: "create a work order to [task]"

1. **Analyse first.** Budget real time for this — ten minutes of reading beats
   an hour of rework. Search the codebase for what already exists, read the
   data model, find the related endpoints and their handlers, list the
   dependencies the project already has installed, and map what other work
   orders this one depends on or blocks.

   ```bash
   playbook search "<problem>"     # has this been solved and closed before
   playbook suite "<term>"         # and was it tested
   ```

2. **Write detailed content.** A real work order runs to 700+ lines. That is
   not a formatting target, it is what it takes to write down the current
   state, the implementation plan, the dependencies, the risks, and the
   acceptance criteria in enough detail that someone else could execute it
   without asking you a question. A 40-line work order is a ticket, and a
   ticket is not a work order.

   Include, at minimum: Current State, Implementation Plan, Dependencies,
   Risks, and Acceptance Criteria.

3. **Create it with the driver.**

   ```bash
   wo new "<Title>" --size standard --area <area> --priority P1 --paths <a,b>
   ```

4. **Result.** The folder exists under `{{WORKORDERS_DIR}}` with every document
   the size requires, the number is allocated and will not collide with a
   concurrent creator, and the routing is recorded. Publish it when others
   need to see it:

   ```bash
   wo publish <number>
   ```

### When the request is: "start WO-####"

1. **Read the current work order.**

   ```bash
   wo show <number>
   ```

2. **If it is thin** — a stub, a template with unfilled sections, or an
   imported issue body — do the deep analysis now and replace the placeholder
   sections with real content before writing any code. An unanalysed work
   order is not ready to start.

3. **If it is already detailed**, read the implementation plan, confirm the
   scope with whoever asked, and mark it in progress:

   ```bash
   wo start <number>
   ```

### When the request is: "update WO-####"

```bash
wo note <number> "<what happened>"
wo block <number> "<why it is blocked>"
```

`wo note` appends a dated entry to the work order's record. `wo sync` pushes
the current spec and status to the published issue, so the shared view matches
the local record.

### When the request is: "complete WO-####"

```bash
wo verify <number> --run {{TESTING_DIR}}/suites/wo-<number>-feature-name.sh
wo close <number>
```

`wo verify --run` executes the suite and writes the status from its exit code.
`wo close` refuses to produce a closeout when there is no verification, when
the last run was interrupted, or when it could not establish its preconditions.
That refusal is the point of the whole methodology; do not route around it.

---

## Finding Work Orders

### List active work orders

```bash
wo list --active        # everything not closed
wo list --open          # not yet started
wo list --closed        # the historical record
```

### Look at a specific work order

```bash
wo show <number>        # the primary document
wo status <number>      # which documents exist, which are missing
```

### View on GitHub

```bash
gh issue list --repo {{GITHUB_REPO}} --state open
```

### Filter by phase

```bash
gh issue list --repo {{GITHUB_REPO}} --label "phase-1"
```

Labels are applied by `wo publish`; add your own phase labels to the issue and
they survive `wo sync`.

---

## Master Index

There is no hand-maintained master index file, because one drifts from reality
the day it is written. The index is derived:

```bash
wo list                 # every work order, with document completeness
wo stats                # cycle time, evidence rate, drift
```

Between them these give what a master index was for: every work order, its
phase band, its progress, and its dependencies. When a written index is needed
for an audience outside the repository, generate it rather than maintaining it:

```bash
wo list > {{DOCS_DIR}}/WORK-ORDER-INDEX.md
```

---

## Critical Rules

### DO NOT

- Create a loose `.md` file beside the work-order directory
- Assemble a work-order folder by hand instead of using `wo new`
- Skip the codebase analysis when creating a work order
- Reference a file, table, column, or method you have not verified exists
- Skip the `WO-XXXX` comment block on a code change
- Build one-off UI components instead of the project's primitives
- Mark anything `PASS` that you did not run and watch pass
- Route around the verification guard on `wo close`

### ALWAYS

- Search the playbooks before writing a new work order
- Do the analysis first, then write the spec, then write the code
- Use the driver for every state change, so the record stays true
- Fill in every placeholder with real, verified content
- Follow the patterns already in the codebase
- Record dependencies and what this work blocks
- Add the `WO-XXXX` comment block to every change
- Close with executed evidence, or do not close

---

## Quick Commands

```bash
# Search precedent before anything else
playbook search "<problem>"

# Create, after analysis
wo new "<title>" --size standard --area backend --priority P1

# Progress
wo start <number>
wo note <number> "<what happened>"
wo block <number> "<reason>"

# State of things
wo list                 # index, with document completeness per work order
wo status <number>      # which documents exist, which are missing
wo show <number>        # the work order's primary document
wo stats                # cycle time, evidence rate, drift

# Verify and close
wo suite <number>
wo verify <number> --run {{TESTING_DIR}}/suites/wo-XXXX-feature.sh
wo close <number>
wo promote <number>

# Shared work (needs an authenticated GitHub CLI)
wo publish <number>     # open an issue carrying the work order
wo sync <number>        # push spec and status to the issue
wo import <issue>       # work order from an existing issue
```

Step-by-step operating instructions for each of the workflows above are in
`{{PIPELINE_ROOT}}/core/instructions/01-create-work-orders.md`.

---

**NO EXCEPTIONS. THIS IS THE STANDARD.**
