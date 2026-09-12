# WO-XXXX: [Title]

**Priority:** P2
**Effort:** [X hours]
**Target:** `[path to the repository or directory being analysed]` — **read-only**; nothing is written into it and no build, test, or git command runs against it.
**Dependencies:** [WO-<other> or None]

---

## Purpose

[Who needs to understand what, and what they will do with it: onboard, integrate, evaluate, document.]

## Questions This Work Order Must Answer

1. [A question a reader has, in their words]
2. [...]
3. [...]

## Scope

**In:** [modules, services, or capabilities to cover]
**Out:** [what is deliberately not covered, and why]

## Deliverables

Every deliverable lives in this folder, carries the document frontmatter, and traces every claim with `<!-- SOURCE: path:L12 -->`.

- [ ] `WO-XXXX-repo-analysis.md` — the eight-phase analysis (structure, features, API surface, data models, auth, dependencies, profiles, cross-feature map)
- [ ] `WO-XXXX-feature-profile-<name>.md` — one nine-part Feature Profile per feature in the inventory
- [ ] `WO-XXXX-source-references.md` — every file read, its lines, and what it established
- [ ] [status matrix, FAQ package, integration kit, feasibility analysis — whichever this work order is for]

## Acceptance Criteria

- [ ] `narrative-curator` scores every Feature Profile complete (all nine parts, two-sentence test passed)
- [ ] `factuality-validator` reports at least 95% of claims VERIFIED and zero discrepancies on critical claims
- [ ] `critical-reviewer` finds no contradictions or unqualified absolute claims
- [ ] Verification: `wo verify` records the validator and reviewer runs (their reports are the evidence)

## Cross-Cutting Checks

- **Confidence:** every domain carries HIGH / MEDIUM / LOW / NONE, and LOW or NONE is never documented as available
- **Status badges:** IMPLEMENTED only with a code reference; every PARTIAL lists its limitations
- **Audience:** which tier reads this, and does the language match it
- **Empty shelves:** what the target does not have is stated as absent, not filled in from expectation
