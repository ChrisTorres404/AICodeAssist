---
name: faq-package
description: Build a complete FAQ package from a repository analysis — domains discovered from the feature inventory rather than a fixed list, ten questions each, seven-part codebase-grounded answers, a master index with coverage statistics, and a mandatory critical review. Use when asked for an FAQ, a due-diligence questionnaire, an evaluation Q&A, or answers to a security or integration review.
---

# FAQ Package

An FAQ package is the artifact a platform gets asked for by every team
evaluating it: security architects, integrating leads, compliance reviewers.
It is also where over-claiming does the most damage, because an FAQ answer is
quoted in procurement documents and treated as a commitment.

The engine here does not ask a canned list of questions. It reads the feature
inventory and derives the questions that this system actually raises.

## When to Use

- After `/analyze-repo` and `/status-matrix`, when a team needs evaluation
  answers
- When a due-diligence questionnaire arrives and the answers must be grounded
  rather than remembered
- When existing FAQ content has drifted from the code

Run it with `/docs-faq`.

## The Pipeline

```
analysis output → domain discovery → question design → grounded answers
                → critical review → index and statistics
```

| Phase | Input | Output |
|---|---|---|
| Domain discovery | Feature inventory, capability domains | 10-20 FAQ domains |
| Question design | Domains, Feature Profiles | 10 questions per domain |
| Answer generation | Questions, source files | Seven-part answers |
| Critical review | Draft package | Findings and a remediated package |
| Index | Answers, status matrix | Master index with coverage statistics |

## Phase 1 — Dynamic Domain Discovery

Domains are derived, never reused from a previous project.

1. Read the feature inventory and the capability domains from the analysis.
2. Cluster features by **function**, not by directory. Two features in the same
   folder often belong in different domains, and two in different folders often
   belong together.
3. Target **10 to 20 domains**. Fewer than ten means the clustering is too
   coarse to be useful; more than twenty means you have made a domain per
   feature and the reader cannot navigate it.
4. Merge any cluster with fewer than three features into its nearest neighbour.
5. Give every domain exactly **ten questions**. The constraint is the point: it
   forces you to choose the ten that matter instead of listing forty that do
   not.

A worked derivation, on a system with scheduling, delivery and access control:

| Feature cluster | Derived domain |
|---|---|
| Credential validation, session issue and renewal, step-up checks | Authentication and Sessions |
| Roles, permission checks, policy evaluation | Authorization and Access Control |
| Organisation isolation, per-organisation configuration | Tenancy and Isolation |
| Event subscriptions, delivery, retries, dead-letter handling | Events and Webhooks |
| Schedules, run history, failure handling | Background Jobs and Scheduling |
| Request limits, input validation, abuse handling | API Protection |
| Structured logs, traces, metrics, health endpoints | Observability and Operations |
| Client libraries, keys, sandbox, reference docs | Developer Experience |
| Audit trail, retention, export | Audit and Data Governance |
| Settings, provisioning, administrative surfaces | Configuration and Management |

The same repository analysed twice should produce the same domains. A
different repository should not.

## Phase 2 — Question Design

Questions must be ones a real evaluator asks, not ones the system answers
comfortably.

| Level | Example |
|---|---|
| Bad | "Does the platform have rate limiting?" — yes or no, reveals nothing |
| Good | "How does rate limiting work across dimensions, and can limits be set per organisation tier?" — reveals architecture |
| Best | "If our traffic arrives from one shared outbound address for five thousand employees, how does the limiter distinguish that from an attack?" — reveals edge cases and design intent |

Each domain's ten questions cover this spread:

| Category | Questions | Purpose |
|---|---|---|
| Architecture | 2-3 | How is this built? |
| Capabilities | 2-3 | What can it do? |
| Edge cases | 1-2 | What happens when things go wrong? |
| Integration | 1-2 | How does my system hook into this? |
| Gaps and limitations | 1-2 | What can it *not* do yet? |

The last category is mandatory. A domain with no gap questions is marketing.
Number questions continuously across the whole package (Q1-Q10 in domain one,
Q11-Q20 in domain two) so cross-references stay stable.

## Phase 3 — The Seven-Part Answer

Every answer, every time.

**1. Status badge.** Exactly the badge from the status matrix row. Not a
synonym, not a hedge. See [status-matrix](../status-matrix/SKILL.md).

**2. Technical answer.** Grounded in source. Name the components and describe
the mechanism, not just the capability. Numbered steps for anything
sequential. No absolute language without structural proof — see
[critical-review](../critical-review/SKILL.md) for the substitution table.

**3. Code reference.** File paths with line ranges, drawn from the
source-reference index. An answer without one is an opinion.

**4. Integration guidance.** How a consuming team actually uses this:
the specific calls or configuration, in order; what to expect back; the
common patterns; and one gotcha — the mistake teams make here. This part is
what separates an FAQ from a brochure, and it is the part most often skipped.

**5. Customer summary.** Three to five sentences a non-technical reader can
act on, with no code references and no undefined acronyms. It must stand alone:
assume it will be copied out of the document without the technical answer
attached, because it will be.

**6. Gap analysis.** Required whenever the badge is anything but implemented.
What is missing, the rough effort, the priority, and the approach that would
close it. For an implemented answer, write `N/A` rather than deleting the
heading.

**7. Cross-references.** At least one link to a related question, by number
and domain. Cross-references are what make the package one document instead of
twenty.

## Phase 4 — Critical Review (Mandatory)

**The package is not complete until the critical review has run and its
findings have been remediated.** This is not optional polish; it is the step
that catches the contradiction between the answer in domain 3 and the answer in
domain 11. Run the full five-phase protocol in
[critical-review](../critical-review/SKILL.md), then re-verify every changed
answer against source with
[factuality-check](../factuality-check/SKILL.md).

A package that ships without the review has a known defect rate and nobody
knows what it is.

## Phase 5 — The Master Index

One index for the whole package:

- A domain table: number, name, question range, count per badge, link to file.
- **Coverage statistics** across all questions: how many answers carry each
  badge, as counts and percentages of the total question count.
- Key findings: the genuine strengths, and the gaps that need attention, each
  with a priority.
- Readiness by audience, carried from the status matrix rather than
  re-derived.
- Links to the status matrix and the critical review.

Statistics are computed from the answers, not estimated. If the index says 63
implemented and the domain files say 61, the index is wrong and so is the
reader's trust.

## Quality Gates

- [ ] Domains derived from this repository's inventory, 10-20 of them
- [ ] No domain with fewer than three underlying features
- [ ] Exactly ten questions per domain, numbered continuously
- [ ] Every domain has at least one gap-or-limitation question
- [ ] Every answer has all seven parts (`N/A` where genuinely not applicable)
- [ ] Every answer's badge matches its status-matrix row
- [ ] Every answer carries at least one code reference
- [ ] Every answer's integration guidance names a concrete call or setting
- [ ] Every customer summary stands alone without the technical answer
- [ ] Every answer cross-references at least one other question
- [ ] Critical review executed and findings remediated
- [ ] Index statistics recomputed after remediation

## Anti-Patterns

- **Cheerleader answers** — describing a partial capability in the language of
  a finished one.
- **Hardcoded domains** — reusing the last project's twenty categories.
- **Orphan answers** — no code reference, no cross-reference, no way to check.
- **Status ambiguity** — "we are working on that" instead of a badge.
- **Missing integration guidance** — what it does, with no how to use it.
- **The customer summary that needs the technical answer** — it will be
  separated from it; write it to survive that.
- **Gap analysis theatre** — "effort: TBD, priority: TBD" is not an analysis.
- **Shipping before the review** — the one rule in this skill with no
  exceptions.
- **Index drift** — statistics computed once, then never recomputed after
  remediation changed a dozen badges.

## In this pipeline

- The package is a work order: `wo new "<repo> FAQ package" --area docs`, with
  domain files in a subfolder of the work order under `{{WORKORDERS_DIR}}` and
  the distribution copy under `{{DOCS_DIR}}`.
- Templates: `{{PIPELINE_ROOT}}/core/templates/docs/faq-domain.md` and
  `faq-index.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `repo-analyst` grounds the answers, `documentation-expert` owns structure and
  placement, `critical-reviewer` runs phase 4, `factuality-validator` verifies
  citations after remediation.
- Close with evidence: `wo verify <n> --run <suite>` over the reference and
  badge-consistency checks. A typed `PASS` is not evidence.
- Command: `/docs-faq`. Requires `/analyze-repo` and `/status-matrix` first;
  feeds `/review-docs`.
