# Bug Templates

## MANDATORY: Bug Tracking Methodology

**Every bug in {{PROJECT_NAME}} follows this structure. No exceptions.**

---

## Required Folder Structure

Every bug MUST have its own folder with the following files:

```
BUG-XXXX-[slug]/
├── BUG-XXXX-[slug].md                 # Bug issue document (REQUIRED)
├── BUG-XXXX-[slug]-CLOSEOUT.md        # Closeout report (REQUIRED on fix)
├── BUG-XXXX-Prompt.md                 # AI fix prompt (for complex bugs)
├── BUG-XXXX-TESTPLAN.md               # Test plan (if extensive testing)
└── BUG-XXXX-ADDENDUM.md               # Additional notes (if needed)
```

---

## Template Files

Everything in this directory, one line each.

### Core Templates (REQUIRED for all bugs)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `BUG-TEMPLATE-ISSUE.md` | Bug issue document with full analysis | Always |
| `BUG-TEMPLATE-CLOSEOUT.md` | Closeout report with verification | On fix completion |

### Specialized Templates (Use when applicable)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `BUG-TEMPLATE-PROMPT.md` | AI implementation prompt for fix | Complex bugs requiring AI assistance |
| `BUG-TEMPLATE-VERIFICATION.md` | Verification report shaped for a defect: reproduced before the fix, not reproducible after, regression check | Before closing — `bug verify` renders it |

---

## How to Create a New Bug Report

Do not copy these templates by hand. The driver does steps 1 to 4 for you; you
do 5 and 6. The steps are written out so you can tell whether the driver did
what it should, and so the shape is clear if you ever have to build one by hand.

### Step 1: Determine Bug Number

The driver picks the next free number from the category's series in
`{{BUGS_DIR}}`. Do not pick one yourself — two people choosing by hand collide.

```bash
playbook bug "<symptom>"                          # has this happened before?
```

### Step 2: Create the Folder

```bash
bug new "<title>" --category <category>           # add --prompt for a complex one
```

This creates `{{BUGS_DIR}}/BUG-XXXX-[slug]/`. The slug is derived from the
title, so give it a real one: short, lowercase, and specific about the symptom.

- `report-totals-off-by-timezone`
- `client-health-path-missing-prefix`
- `dashboard-count-always-zero`

### Step 3: Copy Core Template (REQUIRED)

The driver renders the issue document into the new folder under its final name:

- `BUG-TEMPLATE-ISSUE.md` → `BUG-XXXX-[slug].md`

### Step 4: Copy Specialized Templates (if applicable)

With `--prompt`, for a bug that will be handed to an agent:

- `BUG-TEMPLATE-PROMPT.md` → `BUG-XXXX-Prompt.md`

### Step 5: Fill In Details

Replace all `[placeholders]` with verified content. Before any of it:

1. **Reproduce it first.** An investigation with no reproduction is a guess.
2. **Fill in every `[placeholder]`** with verified content.
3. **Link the work order** that introduced the behavior.

### Step 6: On Fix Completion

Close with evidence — `bug verify <n> --run <suite>` renders
`BUG-TEMPLATE-VERIFICATION.md` from the suite's exit code, and `bug close <n>`
is refused without it. The closeout is rendered from:

- `BUG-TEMPLATE-CLOSEOUT.md` → `BUG-XXXX-[slug]-CLOSEOUT.md`

```bash
bug verify <n> --run {{TESTING_DIR}}/suites/bug-XXXX-<slug>.sh
bug close <n>
```

---

## Gold Standard Examples

A gold standard bug is one a later reader can act on without asking anyone
anything: a reproduction that still reproduces, a root cause rather than a
symptom, the fix with its before and after, and a verification that failed
before the fix and passes after. Keep a short list of yours here as you close
them — one per category is enough — and point new investigations at the nearest.

| Category | Gold standard in this project |
|---|---|
| `auth` | `[BUG-XXXX-<slug>]` |
| `api` | `[BUG-XXXX-<slug>]` |
| `database` | `[BUG-XXXX-<slug>]` |
| `ui` | `[BUG-XXXX-<slug>]` |
| `security` | `[BUG-XXXX-<slug>]` |

Until that list exists, there is no canonical one. Search for the nearest
precedent instead:

```bash
playbook bug "<symptom>"    # bug investigations across every installed playbook
playbook search "<symptom>" # everything, including the work order behind it
```

A promoted bug carries its reproduction, root cause, fix, and the pitfall that
allowed it. Failing that, read the most recently closed bug in `{{BUGS_DIR}}`.

---

## Non-Negotiable Rules

1. **Every bug gets its own folder** - No loose `.md` files in the parent directory
2. **Issue document must exist** - `BUG-XXXX-[slug].md` is always required
3. **Closeout on fix completion** - Every fixed bug must have a closeout report
4. **Consistent naming** - `BUG-XXXX-[slug].md` format always
5. **Link to Work Orders** - Always reference the WO that introduced the behavior
6. **No shortcuts** - This methodology ensures quality and traceability

---

## Bug Numbering by Category

`--category` picks the series and records the routing. This is the driver's
table; do not pick a number yourself.

| Category | Range | Theme |
|---|---|---|
| `auth` | 0001-0099 | Auth & session bugs |
| `api` | 0100-0199 | API & client-library bugs |
| `database` (`db`) | 0200-0299 | Database & migration bugs |
| `ui` (`frontend`) | 0300-0399 | UI & frontend bugs |
| `observability` | 0400-0499 | Observability & metrics bugs |
| `security` | 0500-0599 | Security bugs |
| `performance` (`perf`) | 0600-0699 | Performance bugs |
| `integration` | 0700-0799 | Integration bugs |
| `config` (`deployment`) | 0800-0899 | Configuration & deployment bugs |
| `docs` (`documentation`) | 0900-0999 | Documentation bugs |
| *(none given)* | 1000+ | Overflow / misc — decide the routing before investigating |

Each series holds 99 numbers. A series that fills up is a signal, not a
problem: split the category before you spill into the next band.

Who investigates, who fixes, and who validates each category:
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-BUG-METHODOLOGY.md` and
`{{PIPELINE_ROOT}}/core/rules/common/troubleshooting.md`.

---

## Validation Checklist

Before considering a bug report "created", verify:

- [ ] Folder exists with correct name (`BUG-XXXX-[slug]/`)
- [ ] Issue document exists (`BUG-XXXX-[slug].md`)
- [ ] Metadata table is complete (severity, status, dates, etc.)
- [ ] Reproduction steps are clear and actionable
- [ ] Expected vs actual behavior documented
- [ ] Related Work Order(s) identified
- [ ] Root cause analysis (if known)
- [ ] Impact assessment complete
- [ ] All placeholders replaced with real content
