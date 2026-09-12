---
name: status-matrix
description: Produce an honest implementation-status matrix for every capability found in an analysis — badges with definitions, a code reference behind every implemented claim, documented limitations behind every partial, summary statistics, and a readiness assessment. Use when asked how complete a platform is, what is really shipped, or to reconcile optimistic documentation with the code.
---

# Feature Status Matrix

The status matrix is the document that stops a team from planning a quarter
around a capability that does not exist. It is also the document most likely
to be softened under pressure, which is why the rules below are mechanical:
a badge is earned by a code reference, not by a folder, an intention, or a
roadmap slide.

It is the reconciliation point for everything else. FAQ answers, integration
guidance and executive briefs all carry status claims, and every one of them
must agree with this matrix. When they disagree, the matrix wins or the matrix
is wrong — never "both are sort of right".

## When to Use

- After `/analyze-repo`, as the first artifact built on the feature inventory
- Before any integration kit, PM brief, or executive document is written
- When a document claims a capability and a reader asks "is that actually
  live?"
- When two documents disagree about whether something ships

Run it with `/status-matrix`.

## The Badges

| Badge | Status | Definition |
|---|---|---|
| `IMPLEMENTED` | Live | The code path exists end to end, is reachable in the running system, and is cited by file and line. |
| `PARTIAL` | Core exists, with limits | The main path works; at least one named limitation is documented with a source reference. |
| `IN DEVELOPMENT` | Being built now | Code is present and actively changing, but a consumer cannot rely on it yet. |
| `PLANNED` | On the roadmap | No implementation has started. The evidence is a plan, not a file. |
| `NOT AVAILABLE` | Absent | Not implemented, and no current intention to. |

Use a consistent visual marker per badge across every document in the set, and
define it in a legend on each one. A reader who meets a badge without a legend
has to guess, and guessing is what the matrix exists to eliminate.

### The Two Non-Negotiables

> **No `IMPLEMENTED` badge without a code reference.**
> The reference is a path plus a line range in the source-reference index. Not
> a module name, not "see the auth service" — a citation a reader can open.

> **Every `PARTIAL` lists its limitations.**
> A partial with no stated limit is an implemented claim wearing a hedge. Name
> what does not work, in the same row or a footnote the row points to.

Together these two rules do most of the work. Almost every over-claim this
pipeline catches is either an uncited `IMPLEMENTED` or an unexplained
`PARTIAL`.

## Building the Matrix

### Step 1 — Extract

Take every feature from phase 2 of the analysis. Every one gets a row; none
are dropped for being uninteresting. Group rows by the capability domains from
phase 7 so the matrix reads in the same order as the profiles.

### Step 2 — Assess each feature against source

For each feature, in this order:

1. **Does the code exist?** Open the file. A directory is not evidence.
2. **Is it reachable?** A service method nothing calls is not implemented; it
   is dead code, and that is a `NOT AVAILABLE` with a note.
3. **Is it complete?** Trace the path to its end. A handler that accepts a
   request and writes a row but never triggers the downstream effect the
   feature is named for is `PARTIAL`, and the missing effect is the limitation.
4. **Is it exercised?** Tests, or usage elsewhere in the repository, raise
   confidence. Their absence does not by itself demote a badge, but it does set
   the confidence level recorded alongside it — see
   [factuality-check](../factuality-check/SKILL.md).
5. **Assign the badge and write the note.** The note is one line: for
   `IMPLEMENTED`, what it covers; for anything else, what it does not.

Depth of implementation is the claim. "The file exists" is the most common
route to a false `IMPLEMENTED`, and the reviewer's job is to catch it.

### Step 3 — Row format

| Feature | Status | Notes | Source |
|---|---|---|---|
| Scheduled job retries | `IMPLEMENTED` | Exponential backoff, ceiling from config | `src/jobs/retry.*` L22-L74 |
| Job run history | `PARTIAL` | Retained 7 days; no export endpoint | `src/jobs/history.*` L15-L40 |
| Cron expression editor | `PLANNED` | No implementation; roadmap item only | — |

The `Source` column is empty only for `PLANNED` and `NOT AVAILABLE`. Any other
badge with an empty source is a defect in the matrix, not a shortcut.

### Step 4 — Summary statistics

| Status | Count | Percentage |
|---|---|---|

Percentages are of the total feature count, rounded to whole numbers and
summing to 100. Publish the total alongside them: "62 features" gives the
percentages meaning, and a matrix over a subset of the system must say which
subset.

### Step 5 — Readiness assessment

Statistics do not answer "can we start?". The readiness assessment does, per
audience:

| Audience | Readiness | Justification |
|---|---|---|
| Integrating teams | Ready / Ready with caveats / Not ready | Which capability domains are green, which are the caveats |
| Security and compliance review | Ready / Ready with caveats / Not ready | Which controls have evidence, which do not |
| Day-2 operations | Ready / Ready with caveats / Not ready | What can be monitored, configured and recovered today |

Each rating carries a justification naming the specific rows that drove it.
"Ready with caveats" without the caveats named is not an assessment.

Where the project has a named compliance target, add a row per framework and
justify it from the matrix rows — never from the framework's own checklist.
Where it has none, leave compliance out entirely rather than inventing a
standard to be measured against.

## Reconciling With Everything Else

The matrix is the source of truth for status. Reconcile in both directions:

| Other artifact | What must agree | Who checks |
|---|---|---|
| FAQ answers | The badge on each answer equals the badge on the matching row | `critical-reviewer` |
| Integration docs | Guidance tone follows the badge: ready, caveated, hold | `critical-reviewer` |
| PM brief and decision matrix | "Ready now" lists contain only `IMPLEMENTED` and `PARTIAL` rows | `product-strategist` |
| Executive brief | Maturity claims trace to badge counts, not adjectives | `factuality-validator` |

Guidance by badge:

- `IMPLEMENTED` — "Ready to integrate. Follow the standard path."
- `PARTIAL` — "Available with caveats: <the limitation>. Plan around it."
- `IN DEVELOPMENT` — "Under active development. Talk to the owning team before
  you build against it."
- `PLANNED` — "Not available. On the roadmap."
- `NOT AVAILABLE` — "Not available. <Alternative>, if there is one."

When a mismatch is found, fix the *downstream document*, then re-check the
matrix row against source. Two edits, both recorded. Never quietly upgrade a
badge to match a nicer sentence someone already wrote.

## Quality Gates

- [ ] Every feature in the analysis inventory has exactly one row
- [ ] Every `IMPLEMENTED` row carries a file and line reference
- [ ] Every `PARTIAL` row names at least one limitation
- [ ] Every `IN DEVELOPMENT` row says what a consumer cannot yet rely on
- [ ] `PLANNED` and `NOT AVAILABLE` rows cite a plan, not a file
- [ ] Rows are grouped by the analysis's capability domains
- [ ] Summary statistics sum to 100% and state the total
- [ ] Readiness assessed per audience, each with a justification naming rows
- [ ] Every status claim in every sibling document matches its row
- [ ] The legend defining every badge appears on the document

## Anti-Patterns

- **Folder-as-evidence.** A path named after a feature is not the feature.
- **The generous partial.** Using `PARTIAL` as a polite `NOT AVAILABLE`
  misleads worse than an honest absence, because it invites planning.
- **Badge drift.** Marking something implemented because it was implemented in
  another repository, another branch, or a demo.
- **Unlisted limitations.** "Partial (see docs)" points at nothing.
- **Percentage theatre.** "87% implemented" with no denominator and no domain
  breakdown is a number designed not to be checked.
- **Compliance cosplay.** Rating against a framework nobody has asked for,
  from the framework's checklist rather than from the code.
- **Softening under pressure.** If a reader dislikes a badge, the response is
  to re-read the source, not to re-read the room.
- **A matrix nobody reconciles.** An accurate matrix beside an optimistic FAQ
  is worse than no matrix: it proves someone knew.

## In this pipeline

- The matrix is a work order: `wo new "<repo> status matrix" --area analysis`,
  built in the work-order folder under `{{WORKORDERS_DIR}}` and distributed
  from `{{DOCS_DIR}}`.
- Template: `{{PIPELINE_ROOT}}/core/templates/docs/feature-status-matrix.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `repo-analyst` extracts the rows; `critical-reviewer` assigns and defends the
  badges; `factuality-validator` verifies the citations.
- Close with evidence: `wo verify <n> --run <suite>` over the citation check.
  `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Command: `/status-matrix`. Required input for `/docs-faq`,
  `/integration-kit`, `/docs-brief`.
