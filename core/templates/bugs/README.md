# Bug Templates

## MANDATORY: Bug Tracking Methodology

**ALL bugs in the {{PROJECT_NAME}} MUST follow this structure. No exceptions.**

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

### Step 1: Determine Bug Number
Check existing bugs in `{{BUGS_DIR}}/` and use the next available number.

### Step 2: Create the Folder
```bash
mkdir -p {{BUGS_DIR}}/BUG-XXXX-[slug]
```

Use a short, descriptive slug (lowercase, hyphens):
- `login-analytics-timezone-mismatch`
- `sdk-health-paths-missing-prefix`
- `dashboard-session-count-zero`

### Step 3: Copy Core Template (REQUIRED)
Copy the template file to the new folder and rename:
- `BUG-TEMPLATE-ISSUE.md` → `BUG-XXXX-[slug].md`

### Step 4: Copy Specialized Templates (if applicable)
If the bug requires AI assistance:
- `BUG-TEMPLATE-PROMPT.md` → `BUG-XXXX-Prompt.md`

### Step 5: Fill In Details
Replace all `[placeholders]` with actual content.

### Step 6: On Fix Completion
Create closeout using:
- `BUG-TEMPLATE-CLOSEOUT.md` → `BUG-XXXX-[slug]-CLOSEOUT.md`

---

## Gold Standard Examples

Reference these completed bug reports for best practices:

- `BUG-0001-login-analytics-timezone-mismatch/` - Complete with issue + closeout
- `BUG-0007-rate-limit-forced-logout/` - Complete with issue + closeout
- `BUG-0006-health-check-pool-saturation/` - Includes addendum for known behavior
- `BUG-0018-sdk-missing-usage-module/` - Recent example with proper structure

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
