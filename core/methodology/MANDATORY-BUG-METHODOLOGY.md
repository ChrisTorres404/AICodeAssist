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

The `bug` driver creates the folder, numbers it in the right series, and
records who investigates, who fixes, and who validates:

```bash
bug new "<title>" --category <category> [--prompt]
bug verify <number> --run <suite.sh>
bug close <number>            # refuses without a VERIFICATION document
bug promote <number>          # carry the investigation into a pack
```

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

## Good Examples

There is no canonical list. Find the nearest precedent before writing a new
investigation:

```bash
pack bug "<symptom>"        # bug investigations across every installed pack
pack search "<symptom>"     # everything, including the work order behind it
```

A promoted bug carries its reproduction, its root cause, its fix, and the
pitfall that made it possible. That is worth far more than a blank template.
Failing that, read the most recently closed bug in `{{BUGS_DIR}}` and follow it.

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

1. **Search for precedent**: `pack bug "<symptom>"`. The same failure has
   often been investigated before.
2. **Open it with the driver**: `bug new "<title>" --category <category>`,
   adding `--prompt` for a complex investigation. This creates the folder,
   picks the number from the category's series, renders the issue document,
   and writes the routing at the top of it.
3. **Reproduce before theorising.** An investigation with no reproduction is
   a guess.
4. **Investigate, then fix, as separate steps.** Investigators return findings
   with `file:line` references and what would disprove their theory; they do
   not edit. The fix is a separate delegation, and a third agent validates it.
5. **Fill in every section** with verified content.
6. **Never create a loose `.md`** beside the bug directory.
7. **Link the related work order(s).**

---

## Bug Numbering and Routing

The number is not decorative: `--category` picks the series *and* records who
investigates, who fixes, and who validates. This is the driver's table.

| Category | Series | Investigate with | Fix with | Validate with |
|---|---|---|---|---|
| `auth` | 0001 | `support-engineer-expert` + `jwt-expert` | `jwt-expert`, `oauth-oidc-expert`, or `iam-rbac-expert` | `owasp-top10-expert`, then `project-validator-expert` |
| `api` | 0100 | `support-engineer-expert` + `rest-expert` | the stack's backend specialist | `project-validator-expert` |
| `database` (`db`) | 0200 | `database-validator-expert` + `postgres-expert` | `postgres-expert` or `typeorm-expert` | `database-validator-expert` |
| `ui` (`frontend`) | 0300 | `support-engineer-expert` + `react-expert` | the stack's UI specialist | `frontend-validator-expert` |
| `observability` | 0400 | `support-engineer-expert` + `prometheus-expert` | `prometheus-expert` or `grafana-expert` | `project-validator-expert` |
| `security` | 0500 | `owasp-top10-expert` + `support-engineer-expert` | `jwt-expert`, `iam-rbac-expert`, or `owasp-top10-expert` | `owasp-top10-expert`, then `project-validator-expert` |
| `performance` (`perf`) | 0600 | `performance-optimizer` + `postgres-expert` | `nodejs-expert`, `postgres-expert`, or `redis-expert` | `project-validator-expert` |
| `integration` | 0700 | `support-engineer-expert` + `rest-expert` | the stack's backend specialist or `websocket-expert` | `project-validator-expert` |
| `config` (`deployment`) | 0800 | `support-engineer-expert` + `docker-expert` | `docker-expert` or `github-actions-expert` | `project-validator-expert` |
| `docs` (`documentation`) | 0900 | `documentation-expert` | `documentation-expert` | `documentation-expert` |
| *(no category given)* | 1000 | decide the routing before investigating | — | — |

"The stack's specialist" is resolved from the detected stack when the bug is
opened, so the routing printed on the bug names a real agent. The validator is
never the agent that wrote the fix.

The next free number in the series is chosen by the driver. Do not pick one.

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

```
// WO-XXXX: original feature implementation
// BUG-YYYY: fixed [brief description of what was fixed]
// Summary: [one line explaining the fix or the constraint it now respects]
```

Use the comment syntax of the language you are in.

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

4. **Let the driver record the verification**

   ```bash
   bug verify <number> --run {{TESTING_DIR}}/suites/bug-XXXX-<slug>.sh
   ```

   It executes the suite and writes `EXECUTED — PASS` or `EXECUTED — FAIL`
   from the exit code. Include the before and after evidence in the document;
   format: `{{PIPELINE_ROOT}}/core/templates/testing/TEST-TEMPLATE-VERIFICATION.md`.

### Closeout Blockers

`bug close` refuses to produce a closeout without a VERIFICATION document. A
closeout is also rejected in review if:

- [ ] No reproduction evidence was captured
- [ ] No fix verification evidence exists
- [ ] Verification was assumed rather than executed
- [ ] Regression tests were not run
- [ ] The evidence was written rather than captured

### Where testing material lives

```
{{TESTING_DIR}}/
├── suites/                             # test suites
└── test-results/                       # execution reports
```

Methodology and templates come from the pipeline:
`{{PIPELINE_ROOT}}/core/methodology/MANDATORY-TESTING-METHODOLOGY.md` and
`{{PIPELINE_ROOT}}/core/templates/testing/`.

---

**NO EXCEPTIONS. THIS IS THE STANDARD.**