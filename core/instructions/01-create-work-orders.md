# System Instructions — Creating and Running Work Orders

**Read this before any work order operation.**

These are the operating instructions for the work-order lifecycle. They are
language- and framework-neutral: substitute the project's own build, test, and
database commands, which the project `CLAUDE.md` records.

The authority on what a work order must contain is
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-WO-METHODOLOGY.md`. This file is
the operational half: what to do when the user asks for one.

---

## 1. Where Work Orders Live

Work orders live in the directory the pipeline config names, one folder per
work order, never a loose `.md` file:

```
{{WORKORDERS_DIR}}/
├── WO-XXXX-[Descriptive-Name]/
│   ├── WO-XXXX-SPEC.md
│   ├── WO-XXXX-CHECKLIST.md
│   ├── WO-XXXX-TASK-BREAKDOWN.md
│   ├── WO-XXXX-Prompt.md
│   ├── WO-XXXX-VERIFICATION.md     # before closeout
│   └── WO-XXXX-CLOSEOUT.md         # on completion
```

There is no separate "active" and "completed" directory to move files between,
and no archive folder to keep in sync. State lives in the work order itself and
is set by the driver; `wo list` is the index.

```bash
wo list                  # every work order, with its document map and state
wo list --active         # everything not closed
wo list --closed
```

Do not create a work-order folder by hand. The driver owns naming, numbering,
and the routing line at the top of each document, and `playbook` and the index
depend on both.

### Archive (legacy — reference only)

A project that ran a work-order process before this pipeline usually has a pile
of older work orders somewhere else:

```
{{DOCS_DIR}}/work-orders/archive/
```

Read them for history — what was tried, what the numbering meant, why a
decision was made. Do not modify them, do not renumber them, and do not import
them into `{{WORKORDERS_DIR}}`. They are a record of what happened, not part of
the live index, and `wo list` deliberately does not read them.

---

## 2. When the User Says: "Create a work order to [task]"

### Step 1 — Search for precedent (first, always)

```bash
playbook search "<the problem>"
```

A solved, tested, closed-out work order beats a blank template, and its
pitfalls are already written down. If one covers this, read it before writing
anything.

### Step 2 — Analyse the codebase before writing the spec

Budget 5 to 10 minutes of real analysis before a word of the spec is written. A
work order written without it is a wish list. Establish, with evidence:

- Where the relevant code lives, and what already exists
- The data model: which tables, columns, and entities are involved, read from
  the schema rather than remembered
- The existing entry points — endpoints, handlers, commands — that this work
  touches or resembles
- Which dependencies are already installed, so nothing new is added by reflex
- Which other work orders this depends on or blocks

Delegate the search when the codebase is large. Investigators return
`file:line`; do not grep your way through by hand.

Verify everything you intend to reference actually exists. A spec that names a
table, file, or method that is not there is a hallucination that will be
implemented as one.

### Step 3 — Open the work order with the driver

```bash
wo new "<title>" --size trivial|small|standard|large --area <area> --priority P0|P1|P2|P3
```

- `--size` sets the ceremony. State the size you chose and why. `trivial` is a
  typo or a config flip; `small` is one file and one function; `standard` is
  the full document set; `large` adds the SDK and UI implementation documents.
- `--area` routes the work to the right specialist and records who validates
  it. Areas: `backend`, `api`, `database`, `auth`, `rbac`, `frontend`, `ui`,
  `styling`, `testing`, `cicd`, `docker`, `security`, `performance`, `docs`,
  `analysis`, `integration`.
- `--series N` starts or continues a numbered band so related work stays
  together.
- `--sdk` and `--ui` add the specialized implementation documents.

The driver creates the folder, takes the next free number, renders every
document the size requires, and prints the delegation.

### Step 4 — Fill in the SPEC before writing any code

A spec written afterwards is a description, not a specification, and it will
not catch the design problem you are about to ship. Replace every placeholder
with real, verified content: real paths, real signatures, real table names,
success criteria someone else could test.

**Write a detailed work order — 700+ lines is normal.** That is not a
formatting target; it is what it takes to write the analysis down so that
somebody else could execute the work without asking you a question. A 40-line
work order is a ticket, and a ticket gets implemented by guesswork.

Five sections are mandatory in every SPEC, whatever the work is:

| Section | What it must contain |
|---|---|
| **Current State** | What exists today, read from the code and the schema, with paths. Not what you remember exists. |
| **Implementation Plan** | The change, step by step, in dependency order, naming the files that will be created or modified. |
| **Dependencies** | What this work needs — other work orders, migrations, libraries, environment — and what it blocks. |
| **Risks** | What can go wrong, what it would break, and how it would be detected and rolled back. |
| **Acceptance Criteria** | Statements that are true or false about the running system, each mapped to the test that will prove it. |

Acceptance criteria that cannot be tested are not acceptance criteria. If a
criterion cannot be expressed as something a suite could assert, rewrite it
until it can.

### Step 5 — Confirm it counts as created

```bash
wo status <number>
```

This prints which documents exist and which are missing. Use it; do not eyeball
the folder. A folder of unfilled template headings is not a work order.

---

## 3. When the User Says: "Start WO-XXXX"

### Step 1 — Read the work order

```bash
wo show <number>
```

### Step 2 — Judge whether the spec is real

If the SPEC is still mostly placeholders, or was opened as a stub to hold a
number, spend 10 minutes on the deep codebase analysis from section 2 now,
rewrite the spec against what you found, and replace every placeholder section
with real analysis. Do not start implementing against a spec that has not been
filled in.

If the SPEC is detailed, read the implementation plan end to end, confirm its
assumptions still hold against the current code, and confirm with the user
before changing anything.

### Step 3 — Mark it in progress

```bash
wo start <number>
```

### Step 4 — Implement in dependency order

Follow the order the project's `CLAUDE.md` records for its stack — the data
layer before the service layer, the service layer before the client library,
the client library before the UI. Never build a layer against an interface that
does not exist yet.

Every code change carries the comment block in section 6.

---

## 4. When the User Says: "Update WO-XXXX"

Record progress on the work order itself, not in chat:

```bash
wo note <number> "<what happened, what is next>"    # dated session note
wo block <number> "<what is blocking it>"           # blocked, reason recorded
wo start <number>                                   # unblocked, back in progress
```

If the work order is shared with teammates:

```bash
wo sync <number>      # push the current spec and status to its issue
```

Notes are for facts: what was changed, what was measured, what was discovered.
A note saying "made good progress" is worth nothing to the next session.

---

## 5. When the User Says: "Complete WO-XXXX"

Completion is verification followed by closeout. Nothing else counts.

### Step 1 — Have a behavioral suite

```bash
wo suite <number>      # scaffold one, or --wrap '<cmd>' around the project's runner
```

Suite path: `{{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh`. Method:
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md`.

### Step 2 — Verify by running it

```bash
wo verify <number> --run {{TESTING_DIR}}/suites/wo-XXXX-feature-name.sh
```

`--run` executes the suite and writes `EXECUTED — PASS` or `EXECUTED — FAIL`
into the VERIFICATION document from the exit code. Nobody types a status by
hand. Without `--run` the document says `NOT EXECUTED — PLAN ONLY`, which is an
honest status and not a closeable one.

Map every success criterion in the SPEC to the test that proves it.

### Step 3 — Close it

```bash
wo close <number>
```

This refuses to run without a VERIFICATION document. That guard is the only
thing making evidence non-optional. If you are tempted to route around it, the
correct move is to run the tests.

### Step 4 — Promote it if it is worth carrying forward

```bash
wo promote <number>
```

Copies the work order into the playbooks with a catalog entry. Then edit the
**Pitfalls** lines by hand — that is the part that saves the next person a
week. Promotion refuses unverified work.

---

## 5a. Working With Others: the GitHub Issue

The work-order folder is the record; the issue is the shared view of it. The
two are kept in step by explicit commands, not by a background sync — nothing
happens to a work order that you did not ask for.

All of these need the `gh` CLI, authenticated (`gh auth login`), and a
repository the CLI can resolve.

| Step | Command | What actually happens |
|---|---|---|
| Publish the work order | `wo publish <number>` | Opens an issue titled `WO-XXXX: <title>` carrying the spec, and labels it `work-order`, `size:<size>`, and the priority. Records the issue URL and number in the work order. |
| Push a change or a status | `wo sync <number>` | Replaces the issue body with the current spec, then comments the status line and the document map. |
| Record a verification run | `wo verify <number> --run <suite>` | Runs the suite, writes the status into the VERIFICATION document, and comments the result and the last lines of the log on the issue. |
| Close the issue | `wo close <number>` | Produces the closeout **and closes the issue** with a comment naming the closeout file. No separate command is needed. |
| Start from an existing issue | `wo import <issue-number>` | Creates a work order numbered from the issue, so the two numbers match, with the issue body appended to the primary document. |

If a work order was never published, `wo close` closes nothing remote and says
so; the local closeout is unaffected. To close an issue that is not tracked by
a work order, use the CLI directly:

```bash
gh issue close <issue-number> --repo {{GITHUB_REPO}} --comment "<why>"
```

### View on GitHub

```bash
gh issue list --repo {{GITHUB_REPO}} --state open --label work-order
```

### Filter by phase

Phase labels are applied to the issue, not to the work order, and they survive
`wo sync`:

```bash
gh issue list --repo {{GITHUB_REPO}} --label "phase-1"
```

### Master index

There is no hand-maintained index file. `wo list` derives the index from the
work orders that exist, so it cannot drift:

```bash
wo list                 # every work order, its state, its document map
wo list --active        # everything not closed
wo stats                # cycle time, evidence rate, drift
```

Between them these answer what a master index was for: what exists, which phase
band it is in, how far along it is, and what depends on what. If a written index
is needed for readers outside the repository, generate it rather than maintain
it:

```bash
wo list > {{DOCS_DIR}}/WORK-ORDER-INDEX.md
```

---

## 6. Code Comment Standards (mandatory)

**Every code change carries a header comment naming the work order.** This is
how a reader six months later finds out why a line exists without guessing.

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

A bug fix adds the bug number alongside the original work order:

```
// WO-XXXX: original feature implementation
// BUG-YYYY: fixed [what was wrong]
// Summary: [one line on the fix or the constraint it now respects]
```

---

## 7. UI Component Standards (mandatory)

Every UI component:

1. Uses the project's component primitives — the existing button, input, card,
   dialog, and table components — rather than new one-off markup.
2. Uses the project's styling system and its design tokens. No ad-hoc values
   and no parallel stylesheet.
3. Is reusable: takes props, hardcodes nothing a caller should decide.
4. Follows the patterns already in the codebase. Find the nearest existing
   component of the same kind and follow it.
5. Carries the `WO-XXXX` comment block from section 6.
6. Is accessible: labelled controls, keyboard reachable, meaningful roles.
7. Supports every theme the project ships, dark mode included.
8. Handles loading, empty, and error states — not only the success path.

Before building a new component, name the existing one you are following. If
there isn't one, say so in the SPEC.

---

## 8. Critical Rules

### Do not

- Create a loose `.md` file beside the work-order directory
- Assemble a work-order folder by hand instead of using `wo new`
- Skip the codebase analysis when creating a work order
- Reference a file, table, column, or method you have not verified exists
- Skip the `WO-XXXX` comment block on a code change
- Build one-off UI components instead of the project's primitives
- Mark anything `PASS` that you did not run and watch pass
- Route around `wo close`'s verification guard

### Always

- Search the playbooks before writing a new work order
- Do the analysis first, then write the spec, then write the code
- Use the driver for every state change, so the record stays true
- Fill in every placeholder with verified content
- Follow the patterns already in the codebase
- Record dependencies and what this work blocks
- Close with executed evidence, or do not close

---

## 9. Quick Commands

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

---

## 10. Related Instructions

| File | What it covers |
|---|---|
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-WO-METHODOLOGY.md` | What a work order must contain, and why |
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-BUG-METHODOLOGY.md` | The same lifecycle for bugs, via the `bug` driver |
| `{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` | What counts as evidence |
| `{{PIPELINE_ROOT}}/core/instructions/03-e2e-test-fix-rules.md` | Recovering a suite that fails at scale |

**NO EXCEPTIONS. THIS IS THE STANDARD.**
