---
name: doc-lifecycle
description: Govern generated documents through their life — YAML frontmatter, version bumps, the DRAFT to REVIEW to VALIDATED to FINAL status flow with who moves a document between statuses, and the seven quality gates every document passes. Use when creating, versioning, reviewing, or promoting any analysis or documentation artifact.
---

# Document Lifecycle

Generated documentation rots faster than code, because nothing fails when it
becomes wrong. This skill is the machinery that gives a document a version, a
status, an owner for each transition, and a set of gates it cannot skip.

Every artifact produced by [repo-analysis](../repo-analysis/SKILL.md),
[faq-package](../faq-package/SKILL.md),
[integration-kit](../integration-kit/SKILL.md),
[developer-docs](../developer-docs/SKILL.md),
[executive-docs](../executive-docs/SKILL.md) and
[feasibility-analysis](../feasibility-analysis/SKILL.md) obeys it.

## When to Use

- Creating any generated document — the frontmatter goes on before the content
- Editing an existing one — the version and date change with the content
- Moving a document toward publication
- Auditing a documentation set: which documents are validated, which are stale

## Frontmatter

Every generated document opens with it. A document without frontmatter has no
version, no owner, and no way to tell whether anyone checked it.

```yaml
---
wo: WO-0412
title: Webhook Delivery — Integration Playbook
version: 1.0
status: DRAFT
created: 2026-01-14
last-modified: 2026-01-14
reviewed-by: N/A
---
```

| Field | Holds |
|---|---|
| `wo` | The work order this document belongs to. Every document has one; a document with no work order is an orphan and will not be found again. |
| `title` | The document's own title, matching its first heading. |
| `version` | `major.minor`, starting at `1.0`. |
| `status` | `DRAFT`, `REVIEW`, `VALIDATED`, or `FINAL`. Exactly one of those four words. |
| `created` | The date first written. Never changes. |
| `last-modified` | The date of the most recent content change. |
| `reviewed-by` | The role that performed the most recent review, or `N/A`. |

Consumer-facing documents keep the frontmatter in the work-order copy and drop
the `wo` and `reviewed-by` fields from the published copy — internal
identifiers are internal terminology, and
[developer-docs](../developer-docs/SKILL.md) forbids them on the page. The
placement manifest records the mapping.

Add fields where a document type genuinely needs one — `audience` on
consumer-facing documents, `tier` where a set is tiered. Do not add a field
that duplicates a work-order field; the work order is the record.

## Version Bumps

| Bump | When | Example |
|---|---|---|
| **Major** (1.4 → 2.0) | Structural change: sections added or removed, the document reorganised, the audience changed, a rewrite | Splitting one playbook into a quickstart and a task guide |
| **Minor** (1.0 → 1.1) | Content change within the existing structure: corrections, additions, updated figures, remediated wording | A retry count corrected from three to five |

Every bump updates `last-modified`. A content change with no version bump is
the defect that makes versions meaningless — a reader who compares 1.2 against
1.2 and sees different text stops trusting the field.

A major bump resets the status to `REVIEW` at best, and to `DRAFT` where the
structure changed enough that the previous review no longer applies. A minor
bump keeps the status unless a claim changed; a changed claim always returns
the document to `REVIEW`, because
[factuality-check](../factuality-check/SKILL.md) must run again over it.

When a versioned document changes substantially, record what changed and why
in the work order's session notes: `wo note <n> "<what changed>"`. The
document carries the current truth; the work order carries the history.

## Status Flow

```
DRAFT  →  REVIEW  →  VALIDATED  →  FINAL
```

| Status | Meaning | Who moves it here |
|---|---|---|
| `DRAFT` | Being written. Incomplete sections are expected and acceptable. | The author role: `repo-analyst`, `narrative-curator`, `developer-experience-writer`, `api-reference-writer`, or `product-strategist` |
| `REVIEW` | Complete enough to be checked. Structure and narrative reviewed; adversarial review run. | `critical-reviewer`, after the five-phase protocol, with findings remediated |
| `VALIDATED` | Every claim verified against source: 95% or better, zero discrepancies. | `factuality-validator`, and never the document's own author |
| `FINAL` | Approved for distribution. | The work-order owner, after `wo verify` has produced executed evidence |

Rules that make the flow mean something:

- **No status skipping.** A document cannot go DRAFT to VALIDATED. The review
  is what makes validation tractable.
- **The validator is never the author.** This mirrors the pipeline's rule that
  the validating role is never the implementing role.
- **Backward moves are normal.** A discrepancy found at VALIDATED sends the
  document back to DRAFT or REVIEW. Recording that is healthy; hiding it is
  how a wrong document keeps a validated badge.
- **FINAL is not permanent.** When the code changes, the document is no longer
  final — it is stale. Re-verify and re-stamp, or mark it superseded.

## The Seven Quality Gates

A document passes all seven before it reaches FINAL. The reviewing role runs
the gate that belongs to it.

### Gate 1 — Structural Completeness
- [ ] Every section the document type requires is present
- [ ] Frontmatter complete: `wo`, `title`, `version`, `status`, both dates
- [ ] Heading levels are consistent and none are skipped
- [ ] No empty sections, no bracketed placeholders, no `TODO`

### Gate 2 — Factual Accuracy
- [ ] Every technical claim cites a source path
- [ ] Endpoints verified against route declarations
- [ ] Data shapes verified against schema or type definitions
- [ ] Configuration items verified against config or environment declarations
- [ ] A factuality report exists: 95% or better, zero discrepancies

### Gate 3 — Naming and Location
- [ ] The document lives in its work-order folder under `{{WORKORDERS_DIR}}`
- [ ] Its filename matches the convention for its type
- [ ] Cross-references name the work order they point into
- [ ] The distribution copy is placed under `{{DOCS_DIR}}` per the placement
      manifest

### Gate 4 — Readability
- [ ] Written at the right tier for its stated audience
- [ ] Terminology consistent throughout
- [ ] Every acronym defined on first use
- [ ] Structured data is in tables, not paragraphs

### Gate 5 — Narrative Depth
- [ ] Every feature named has a Feature Profile, or references one
- [ ] No name-only feature references anywhere past DRAFT
- [ ] A narrative paragraph precedes every summary table
- [ ] Profiles pass the two-sentence test
- [ ] Every feature answers "so what?" for at least one named audience

### Gate 6 — Integration Guidance
- [ ] FAQ answers carry integration guidance
- [ ] Feature Profiles carry use-case scenarios and edge cases
- [ ] Profiles use the full nine-part structure
- [ ] Consumer-facing documents pass the consumer perspective test

### Gate 7 — Planning Artifacts
- [ ] The work order has its SPEC before generation began
- [ ] It has its CHECKLIST, TASK-BREAKDOWN, and Prompt as its size requires
- [ ] It has a VERIFICATION document before closeout — `wo close` refuses
      without one

Gate 7 is the pipeline's own rule applied to documentation: a documentation
work order is a work order, and its evidence requirement does not relax
because the deliverable is prose.

## Anti-Patterns

- **Frontmatter added at the end.** It becomes decoration instead of a record,
  and the `created` date is a guess.
- **Status as aspiration.** Marking a document VALIDATED because it is finished
  rather than because it was verified.
- **The author validating their own work.** They verify against the same
  assumption that produced the error.
- **Silent edits.** Content changed, version untouched, `last-modified`
  untouched. Now no two readers are reading the same document.
- **Skipping REVIEW under deadline.** Validation without review means checking
  the accuracy of claims nobody asked whether the document should be making.
- **FINAL forever.** A document stamped final two releases ago is not final;
  it is unmaintained with a badge.
- **Placeholders past DRAFT.** A bracketed placeholder in a REVIEW document
  reads as a real claim to everyone who did not write it.
- **Separate version histories.** The document carries the version; the work
  order carries the history. Two histories diverge.

## In this pipeline

- Every document belongs to a work order: `wo new "<title>" --area analysis`
  or `--area docs`, and lives in that folder under `{{WORKORDERS_DIR}}`;
  distribution copies go to `{{DOCS_DIR}}` per the placement manifest.
- Templates under `{{PIPELINE_ROOT}}/core/templates/docs/` all ship with this
  frontmatter already in place; use them rather than typing it.
- The shared rule is `core/rules/common/documentation.md`; this skill is its
  lifecycle half.
- `documentation-expert` owns gate 3, `narrative-curator` gate 5,
  `critical-reviewer` the move to REVIEW, `factuality-validator` the move to
  VALIDATED, the work-order owner the move to FINAL.
- FINAL requires executed evidence: `wo verify <n> --run <suite>` writes the
  status from the exit code, and `wo close <n>` refuses without it.
  `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Commands: every documentation command stamps DRAFT on creation;
  `/review-docs` moves documents through REVIEW and VALIDATED.
