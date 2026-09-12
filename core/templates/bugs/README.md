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

### Core Templates (REQUIRED for all bugs)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `BUG-TEMPLATE-ISSUE.md` | Bug issue document with full analysis | Always |
| `BUG-TEMPLATE-CLOSEOUT.md` | Closeout report with verification | On fix completion |

### Specialized Templates (Use when applicable)

| Template | Purpose | When to Use |
|----------|---------|-------------|
| `BUG-TEMPLATE-PROMPT.md` | AI implementation prompt for fix | Complex bugs requiring AI assistance |

---

## How to Create a New Bug Report

Do not copy these templates by hand. The driver picks the number from the
category's series, creates the folder, renders the issue document, and writes
the routing at the top of it.

```bash
pack bug "<symptom>"                              # has this happened before?
bug new "<title>" --category <category>           # add --prompt for a complex one
```

The slug is derived from the title, so give it a real one: short, lowercase,
and specific about the symptom.

- `report-totals-off-by-timezone`
- `client-health-path-missing-prefix`
- `dashboard-count-always-zero`

Then:

1. **Reproduce it first.** An investigation with no reproduction is a guess.
2. **Fill in every `[placeholder]`** with verified content.
3. **Link the work order** that introduced the behavior.
4. **Close with evidence**: `bug verify <n> --run <suite>` then
   `bug close <n>`, which is refused without a verification document.

---

## Good Examples

There is no canonical list. Search for the nearest precedent:

```bash
pack bug "<symptom>"        # bug investigations across every installed pack
pack search "<symptom>"     # everything, including the work order behind it
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

| Category | Series |
|---|---|
| `auth` | 0001 |
| `api` | 0100 |
| `database` (`db`) | 0200 |
| `ui` (`frontend`) | 0300 |
| `observability` | 0400 |
| `security` | 0500 |
| `performance` (`perf`) | 0600 |
| `integration` | 0700 |
| `config` (`deployment`) | 0800 |
| `docs` (`documentation`) | 0900 |
| *(none given)* | 1000 — decide the routing before investigating |

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
