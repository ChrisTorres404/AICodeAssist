---
wo: WO-XXXX
title: "[Repository name] — Feature Status Matrix"
version: 1.0
status: DRAFT
created: YYYY-MM-DD
last-modified: YYYY-MM-DD
reviewed-by: N/A
---

# [Repository name] — Feature Status Matrix

**Scope:** [which system, and which subset of it, this matrix covers]
**Total features assessed:** [N]

---

## Status Legend

| Badge | Status | Definition |
|---|---|---|
| `IMPLEMENTED` | Live | Code path exists end to end, reachable in the running system, cited by file and line |
| `PARTIAL` | Core exists, with limits | Main path works; at least one named limitation documented |
| `IN DEVELOPMENT` | Being built | Code present and changing; a consumer cannot rely on it yet |
| `PLANNED` | On the roadmap | No implementation started |
| `NOT AVAILABLE` | Absent | Not implemented, no current intention to |

<!-- Two rules govern every row below:
     - No IMPLEMENTED badge without a file-and-line reference.
     - Every PARTIAL names at least one limitation. -->

---

## Domain: [domain name]

| Feature | Status | Notes | Source |
|---|---|---|---|
|  |  |  |  |

<!-- Repeat one section per capability domain from the analysis, in the same
     order the Feature Profiles use. Every feature in the inventory gets
     exactly one row; none are dropped for being uninteresting. -->

---

## Summary Statistics

<!-- Computed from the rows above, not estimated. Percentages are of the total
     feature count and sum to 100. -->

| Status | Count | Percentage |
|---|---|---|
| `IMPLEMENTED` |  |  |
| `PARTIAL` |  |  |
| `IN DEVELOPMENT` |  |  |
| `PLANNED` |  |  |
| `NOT AVAILABLE` |  |  |

---

## Readiness Assessment

<!-- WRITING PROMPT: Each justification names the specific rows that drove the
     rating. "Ready with caveats" without the caveats named is not an
     assessment. -->

| Audience | Readiness | Justification |
|---|---|---|
| Integrating teams |  |  |
| Security and compliance review |  |  |
| Day-2 operations |  |  |

<!-- Add a row per compliance framework ONLY where the project has a named
     target, and justify it from the rows above rather than from the
     framework's own checklist. Where there is no target, delete nothing —
     simply add no rows. -->

---

## Reconciliation

<!-- WRITING PROMPT: List the sibling documents whose status claims were
     checked against this matrix, and the date. A mismatch found later means
     the downstream document is fixed and the row re-checked against source —
     never a quiet badge upgrade. -->

| Document | Checked on | Mismatches found | Resolved |
|---|---|---|---|
|  |  |  |  |
