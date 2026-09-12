---
name: repo-analysis
description: Run a deep, read-only, eight-phase analysis of a repository and produce a structured analysis document, Feature Profiles, and a source-reference index inside a work order. Use when asked to analyse, audit, inventory, or map an unfamiliar codebase before writing documentation, an FAQ, an integration kit, or a feasibility answer.
---

# Repository Analysis

A repository analysis is the foundation every other documentation artifact
stands on. The FAQ package, the status matrix, the integration kit and the
executive brief all read *this* document rather than re-reading the code — so
if this document guesses, every downstream artifact inherits the guess.

This is deeper than the `codebase-onboarding` skill. Onboarding answers "how
do I start working in this repo?" in two minutes of reading. Repo analysis
answers "what does this system do, completely, with a source citation for
every claim?" and produces work-order artifacts that survive the session.

## When to Use

- Before `/docs-faq`, `/integration-kit`, `/docs-brief`, `/docs-reference`, or
  `/feasibility` — all of them require a completed analysis as input
- When a team needs a capability inventory of a system nobody owns any more
- When evaluating a platform someone else built, before integrating with it
- When a system's documentation has drifted and you need ground truth

Run it with `/analyze-repo`.

## Read-Only Discipline

Analysis observes. It does not change, advise, or grade.

| Permitted | Forbidden |
|---|---|
| Read any file in the target repository | Modify any file in the target repository |
| Quote source with a path and line range | Create files inside the target repository |
| Record structure, contracts, and data shapes | Run builds, migrations, or deploys against it |
| Record what exists | Recommend refactors or rate code quality |

Write every artifact into the work-order folder under `{{WORKORDERS_DIR}}`,
never into the repository being analysed. If the analysis target *is* the
current project, the same rule holds: analysis output goes to the work order.

### The Critical-Findings Exception

The one case where analysis may say something should change: a **serious
security vulnerability** or a **defect that can cause data loss, unauthorised
access, or system failure**. Record it in a dedicated `## Critical Findings`
section at the end of the analysis document, with:

- A classification: `CRITICAL-SECURITY` or `CRITICAL-DEFECT`
- The exact file and line range
- A factual description of what was observed — not a prescription
- Nothing else. No severity theatre, no remediation plan. A critical finding
  is a pointer for the owning team, and it belongs in a bug, not in a
  documentation deliverable. Open one with `bug new --category security`.

Everything below that bar stays out. "This could be cleaner" is not a finding.

## The Eight Phases

Each phase is time-boxed. The box is a budget, not a target: if a phase runs
long, the repository is bigger than one work order and you should split it by
subsystem rather than skim. Record the phase timings in the work order — they
are the honest estimate for the next repository of that size.

### Phase 1 — Structural Survey (10 min)

Understand the shape before reading any logic.

1. Read the manifest and the README: the dependency file, the workspace
   layout, the declared scripts.
2. Map the directory tree, three levels deep, excluding vendored and build
   directories.
3. Identify the stack: language and version, framework, data store, migration
   tool, background-job runner, authentication libraries.
4. Identify build and deploy configuration: container files, CI workflows,
   task runners, environment templates.
5. Count what there is to count: route handlers, services, models, tests,
   migrations. Counts set the scope of every later phase.

Produces section 1 of the analysis document.

### Phase 2 — Feature Inventory (20 min)

Catalogue every capability the system provides.

1. Read the route or controller layer and list every entry point.
2. Read the service layer and name the functional capabilities behind them.
3. Read the user-facing layer, if there is one, and list the user journeys.
4. Split every feature into **internal** (things the system does for itself:
   logging, migrations, health checks) and **consumer-facing** (things another
   team or a user invokes).
5. For each feature record: what it does, where it lives, what it requires,
   what it exposes.

| Feature | Type | Location | Requires | Exposes |
|---|---|---|---|---|
| Scheduled job execution | Internal | `src/jobs/runner.*` | Data store, clock | Job lifecycle events |
| Webhook delivery | Consumer-facing | `src/webhooks/*` | Outbound network, retry queue | `POST /webhooks/subscriptions` |

Produces section 2. This table is the input to domain discovery in
`faq-package` and to the status matrix, so make it complete rather than
elegant.

### Phase 3 — API Surface (15 min)

Every externally reachable entry point, exactly as it is declared.

For each: method and path as written in the source, authentication
requirement, request shape from the actual schema or type, response shape for
success and for each error, and any rate or size limit applied to it. Group by
module. Do not normalise paths into what they "should" be — record what is
routed. A path recorded from memory is a fabricated endpoint.

Produces section 3.

### Phase 4 — Data Models (15 min)

For every entity or table: its storage name, fields with declared types,
relationships, constraints and indexes. Then the migration history, and a
read/write map showing which services touch which entities. The read/write map
is what makes a later "what breaks if this changes?" question answerable.

Produces section 4.

### Phase 5 — Authentication and Security (15 min)

Middleware, guards and interceptors in the order they execute. Credential and
token types, and their lifetimes. The role, permission or policy model, and
whether it is role-based, attribute-based, or both. Session handling. Transport
and origin configuration. Encryption at rest and in transit, where declared.

Produces section 5.

### Phase 6 — Dependencies and Integrations (10 min)

Libraries with pinned versions, external services called, internal services
depended on, required environment variables, required secrets, and the health
and telemetry integrations. Note for each external call whether a failure is
fatal or degraded — that single column answers most operational questions.

Produces section 6.

### Phase 7 — Narrative Enrichment (20 min)

The inventory from phases 1 to 6 is a spreadsheet. This phase turns it into
something a human can learn from.

1. Write a **Feature Profile** for every consumer-facing feature and every
   internal feature another team could trip over. Use the nine-part structure
   in the [feature-profile](../feature-profile/SKILL.md) skill and the
   `feature-profile.md` template.
2. Group the profiles into **capability domains** — coherent clusters of three
   or more features that a reader would think of as one area.
3. Hand the profiles to `narrative-curator` for a quality pass before the
   analysis leaves DRAFT.

Produces section 7, usually as a separate profiles document in the same work
order when there are more than a dozen features.

### Phase 8 — Cross-Feature Mapping (10 min)

For every feature: its upstream dependencies (what must work for this to
work), its downstream consumers (what breaks when this stops), and its
position in the request lifecycle. Then mark the critical path — the features
whose failure takes the system down — and separate them from the rest.

Produces section 8. This is the section that stops an integration team from
scheduling work in an impossible order.

## Output Document Structure

One document, in this order, with YAML frontmatter per the
[doc-lifecycle](../doc-lifecycle/SKILL.md) skill:

```
1. Repository Structure and Technology Stack
2. Feature Inventory
3. API Surface
4. Data Models
5. Authentication and Authorization
6. Dependencies and Integrations
7. Feature Profiles
8. Cross-Feature Dependency Map
9. Source References
   Critical Findings   (omit the heading entirely when there are none)
```

Use the `repo-analysis.md` template under `{{PIPELINE_ROOT}}/core/templates/docs/`.

## The Source-Reference Index

Every file you opened goes into one index document in the work order, built as
you read rather than reconstructed at the end:

| File | Lines | What was analysed |
|---|---|---|
| `src/webhooks/dispatcher.*` | L40-L118 | Retry policy and backoff schedule |

Paths are relative to the analysed repository's root, never absolute host
paths. This index is what `factuality-check` verifies against, what a reader
uses to check you, and what the next analysis of the same repository starts
from. Use the `source-references.md` template.

## Quality Gates

- [ ] All eight phases completed; none skipped, each with its timing recorded
- [ ] Every feature in the inventory is typed internal or consumer-facing
- [ ] Every endpoint recorded matches a route declaration you actually read
- [ ] Every entity recorded matches a model or schema file you actually read
- [ ] Every consumer-facing feature has a Feature Profile
- [ ] Every profile belongs to a capability domain with at least three members
- [ ] The cross-feature map names upstreams and downstreams for every feature
- [ ] The source-reference index lists every file opened, with line ranges
- [ ] No file in the analysed repository was modified
- [ ] Critical findings, if any, are classified and cited; nothing else
  prescriptive appears anywhere in the document

## Anti-Patterns

- **Inferring the API from the feature list.** If you did not read the route,
  it does not go in section 3. Plausible endpoints are the most damaging
  fabrication this pipeline can produce.
- **Folder-as-feature.** A directory named `notifications/` with two stub
  files is not a notification system. Depth of implementation is the claim,
  not existence of a path.
- **Skipping phase 7 because phases 1-6 "cover it".** They do not. An
  inventory nobody can read is an inventory nobody reads.
- **Reconstructing the source index at the end.** You will miss half of it and
  cite line numbers you did not check.
- **Quality commentary.** "The error handling here is inconsistent" is not
  analysis output. Take it to a bug or a work order.
- **Absolute host paths in citations.** They break for every other reader and
  they fail `bin/sanitize`.
- **One work order for a monorepo.** Split by deployable unit; an analysis
  that runs past its time boxes by 3x was scoped wrong.

## In this pipeline

- Analysis is work: `wo new "<repo> analysis" --area analysis`, and every
  artifact lives in that work-order folder under `{{WORKORDERS_DIR}}`. The
  distribution copy goes to `{{DOCS_DIR}}`.
- The shared rule is `core/rules/common/documentation.md`; this skill is the
  long form of its analysis half.
- `repo-analyst` runs the phases; `narrative-curator` reviews phase 7;
  `factuality-validator` verifies section 9 against the source before the
  document leaves DRAFT.
- Close with evidence: `wo verify <n> --run <suite>` over the reference-check
  script. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Command: `/analyze-repo`. Downstream: `/status-matrix`, `/docs-faq`,
  `/integration-kit`, `/docs-brief`.
