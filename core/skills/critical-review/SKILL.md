---
name: critical-review
description: Run an adversarial five-phase review over generated documentation — contradictions between sections, over-claims and absolute language, ambiguous status, optional compliance mapping, and customer-safe remediation with before and after wording. Use before any documentation set is published, quoted to a customer, or attached to a due-diligence response.
---

# Critical Review

Documentation is a contract with the reader. Every claim in it is either
verifiable or it is an over-claim, and the reader cannot tell the difference
from the page. This review exists to find the difference before someone else
does — in a procurement review, a security questionnaire, or an incident
post-mortem that starts "but the docs said".

The reviewer's stance is adversarial and specific. Not "is this good writing?"
but "which sentence here would I attack if I were being paid to?".

## When to Use

- Mandatory before an FAQ package is complete — see
  [faq-package](../faq-package/SKILL.md)
- Before any integration kit, executive brief, or reference set is published
- When documentation will be quoted externally
- When two documents in a set disagree and nobody knows which is right

Run it with `/review-docs`.

## The Five Questions

Every review answers these, in writing:

1. Is every implemented claim actually verifiable in source?
2. Does any section contradict another section?
3. Does any claim use absolute language without structural proof?
4. Is any partial or planned capability dressed as a finished one?
5. Would a reviewer with a reason to be sceptical flag anything here?

## Phase 1 — Contradiction Detection

Cross-read the whole set against itself. A contradiction inside one document
is embarrassing; a contradiction across two documents in the same set is what
destroys trust in all of them.

| Type | Shape |
|---|---|
| Direct | One section claims isolation is enforced by the data store; another says it is applied by application filtering |
| Scope | A profile says "every request"; the quick reference shows it applies only to authenticated routes |
| Status | An FAQ answer carries the implemented badge; the status matrix row says in development |
| Quantitative | One document says deliveries retry five times; another says three |

Record each as a row: what section A claims, what section B says, and the
verdict — which one the source supports. A contradiction with no verdict is
just a note.

## Phase 2 — Over-Claim Identification

Absolute language promises what no architecture delivers. Flag every instance
and propose the safer wording.

| Risky | Why | Safer |
|---|---|---|
| "never" | Implies a total guarantee | "by design, <mechanism> prevents …" |
| "always" | No system is continuously available | "under normal operation …" |
| "impossible" | True of mathematics, not of software | "structurally prevented by <mechanism>" |
| "guarantees" | Reads as a contractual commitment | "enforces" / "validates" |
| "there is no way to" | Invites "what about …" | "the current design does not expose …" |
| "fully automated" | One manual step falsifies it | "automated except for <step>" |
| "real time" | Means milliseconds to some readers | "typically within <measured latency>" |
| "unlimited" | Something is always the limit | "limited by <the actual constraint>" |
| "seamless", "effortless" | Unfalsifiable; nothing is verified | Describe the actual number of steps |

Then the second class of over-claim, harder to catch because the words are
modest: **claims that imply more than is implemented**. "Supports directory
synchronisation" when what exists is an endpoint that accepts a payload and
stores it. Record the quote and what actually exists beside it.

## Phase 3 — Status Ambiguity Audit

Every capability must carry an explicit badge. Vague phrasing is a status
claim in disguise, and readers resolve it optimistically every time.

| Ambiguous | Correct |
|---|---|
| "we are working on it" | `IN DEVELOPMENT` |
| "planned enhancement", "on our roadmap" | `PLANNED` |
| "being finalised", "nearly complete" | `IN DEVELOPMENT` |
| "evaluating", "under consideration" | `PLANNED` |
| "available in the next release" | `IN DEVELOPMENT`, plus what a consumer cannot rely on today |
| "supported" with no badge | Whatever the status matrix row says |

Cross-check every badge against the status matrix. Where they differ, the
review records both and names which the source supports.

## Phase 4 — Compliance Mapping (Optional)

Run this phase **only when the project has a named compliance or assurance
target**. Where there is none, skip it and say so — mapping a system against a
framework nobody is being audited for produces gaps that are not gaps and
alarm that is not warranted.

Where there is one:

- Take the controls the project's own target actually names.
- For each, cite the documentation section and the source reference that
  evidence it, or record that no evidence exists.
- Report the absence of evidence as exactly that. "No audit-retention setting
  was found in the source" is a finding. "This fails control X" is a judgement
  a reviewer of a different kind gets to make.

Never import a framework's checklist wholesale as a scoring rubric.

## Phase 5 — Customer-Safe Remediation

For every finding, write the fix. A review that lists problems without
proposing wording gets argued with; a review that proposes wording gets
applied.

```
### <Claim or feature name>

**Current:**
> "<the original sentence, quoted exactly>"

**Recommended:**
> "<the accurate replacement, in the same voice and length>"

**Rationale:** <why the change is needed, in one sentence>
```

The replacement must be usable as-is. "Soften this" is not a remediation. And
it must be *accurate*, not merely weaker: demoting a working capability to
avoid argument is its own failure, and it makes the next honest badge harder
to defend.

## Review Output Format

```
# Critical Review — <document or set>

Reviewer role, date, documents under review.

## Executive Summary
Two or three sentences: overall quality and the key concerns.
Overall risk assessment: LOW | MEDIUM | MEDIUM-HIGH | HIGH

## 1. Critical Contradictions
## 2. Overstated or Risky Claims
     2a. Absolute language
     2b. Claims that imply more than is implemented
## 3. Ambiguous Implementation Status
## 4. Compliance Gaps            (omit entirely when phase 4 was skipped)
## 5. Recommended Downgrades
## 6. Overall Risk Assessment
## 7. Recommendations, prioritised: immediate, short-term, medium-term
```

The risk rating is justified by the findings above it. A HIGH with three
cosmetic findings, or a LOW with an unresolved direct contradiction, means the
rating was chosen before the review ran.

## Quality Gates

- [ ] Every document in the set was read, not sampled
- [ ] Every contradiction carries a verdict backed by source
- [ ] Every absolute-language instance is quoted and has a proposed replacement
- [ ] Every status claim was cross-checked against the status matrix
- [ ] Phase 4 either ran against the project's real target or is explicitly
      recorded as not applicable
- [ ] Every finding has a remediation that can be pasted in as written
- [ ] The overall risk rating is justified by the findings listed
- [ ] Remediated claims were re-verified against source afterwards
- [ ] Findings that were rejected are recorded with the reason, not deleted

## Anti-Patterns

- **Rubber stamp.** Approving without opening a source file. A review that
  finds nothing on a large document set did not happen.
- **Aggressive downgrade.** Demoting working capabilities to look rigorous.
  This is the mirror image of over-claiming and just as dishonest.
- **Style notes in a factual review.** Passive voice is a narrative concern;
  send it to `narrative-curator` and keep this review about truth.
- **Findings without wording.** They get debated instead of applied.
- **Compliance mapping by reflex.** Frameworks the project is not being
  measured against generate noise that buries the real findings.
- **Reviewing your own draft.** The reviewer is never the author. If the same
  person must do both, review against the source, never against memory.
- **Remediating without re-verifying.** New wording is a new claim.
- **Silent deletion.** Removing a flagged sentence rather than replacing it
  leaves the reader with a gap where an answer used to be.

## In this pipeline

- The review is part of the documentation work order it reviews, or its own
  `wo new "<set> critical review" --area docs`; it lives in the work-order
  folder under `{{WORKORDERS_DIR}}`.
- Template: `{{PIPELINE_ROOT}}/core/templates/docs/critical-review.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `critical-reviewer` runs all five phases; `factuality-validator` re-verifies
  every remediated claim; `documentation-expert` applies the wording and
  re-places the documents.
- Close with evidence: `wo verify <n> --run <suite>` over the consistency
  checks. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Command: `/review-docs`. Mandatory inside `/docs-faq` and `/integration-kit`.
