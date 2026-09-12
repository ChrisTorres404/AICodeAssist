---
name: integration-kit
description: Produce the consumer-facing integration package — an integration playbook, a PM integration brief, an API quick reference, and an integration decision matrix — from a completed repository analysis, written entirely from the consuming team's perspective and guarded against fabricated endpoints. Use when another team asks how to integrate with a platform, or when scoping integration work.
---

# Integration Kit

An integration kit answers one question: *"I am on another team and I want to
use this platform — how do I do it?"* Nothing in it is about how the platform
is built. The reader has never opened its repository and never will.

This is the highest-risk output the documentation pipeline produces. When a
repository analysis is wrong, a reader is confused. When an integration kit is
wrong, a team spends a sprint calling an endpoint that returns 404, or a
product manager scopes a quarter around a capability that does not exist.
Section "Anti-Hallucination" below is therefore not advisory.

## When to Use

- A team has been asked to integrate with a platform and needs a path
- A product manager needs to scope integration work without a research session
- An evaluation needs "what would this actually take?" answered concretely

Run it with `/integration-kit`. Requires a completed `/analyze-repo` and,
strongly preferred, a `/status-matrix`.

## Consumer Perspective

> **Every sentence is written as if the reader will never see the platform's
> source code.**

| Write this | Not this |
|---|---|
| "To subscribe to events, POST to `/webhooks/subscriptions` with a callback URL and the event types you want." | "The `SubscriptionController` registers handlers through the dispatcher registry." |
| "The response includes a signing secret. Store it; you will need it to verify every delivery." | "The secret is generated in `createSubscription()` and persisted on the entity." |
| "Deliveries retry with exponential backoff up to five attempts, then park in the dead-letter list." | "`RetryPolicy` is injected into the worker and read from configuration." |

Internal source attribution still exists — as traceability comments and a
reference appendix — never inline in the instructions.

### The Consumer Perspective Test

Read each sentence and ask: **does this assume I know the code?** Class names,
file paths, internal service names, framework idioms, and database table names
in body text all fail. Rewrite them as something the reader can call, send,
set, or expect.

## Phase 1 — Surface Extraction (15 min)

From the completed analysis, extract only what a consumer can reach:

1. Externally callable endpoints — from section 3 of the analysis, not from
   the feature list.
2. Client library methods and their signatures, where a library exists.
3. Authentication mechanisms available to a consuming system.
4. Configuration a consumer must set: URLs, identifiers, secrets, callbacks.
5. Events a consumer can subscribe to, and their payload shapes.

This is a working document. It is not distributed.

## Phase 2 — Use-Case Mapping (20 min)

Reorganise by what the consumer wants to accomplish. Internal module structure
is invisible to them and must be invisible here.

Group into use cases phrased as the consumer's own goal — "authenticate my
users", "enforce permissions", "subscribe to changes", "set up my
organisation", "get an audit trail", "issue service credentials". Add
categories the analysed platform actually supports; drop the ones it does not.

Then score each use case:

| Score | Definition | Criteria |
|---|---|---|
| Simple | One or two calls, standard configuration | 1-2 endpoints, no data migration |
| Moderate | Several steps and some configuration | 3-5 endpoints, mapping or custom settings needed |
| Complex | Multi-phase effort needing planning | 6+ endpoints, data migration, federation, or policy design |

And map each to its status badge from the status matrix. A use case whose
capabilities are not implemented does not get a playbook section; it gets a
row in the decision matrix and a place in "what is coming".

## Phase 3 — The Four Documents (30 min)

**1. Integration Playbook** — for engineers on the consuming team. What the
platform does for them; where their system sits; prerequisites; step-by-step
per use case with what to send and what comes back; client setup; how to test;
a go-live checklist; a troubleshooting table of symptom, likely cause,
resolution.

**2. PM Integration Brief** — for product and programme managers. A capability
lookup table; integration paths grouped by complexity with effort ranges;
what is ready now versus what is coming; the common integration patterns in
plain language with one technical anchor each; questions to bring to the
engineering team; and copy-paste snippets ready to drop into a requirements
document.

**3. API Quick Reference** — for developers mid-integration. Every endpoint
organised by use case, not by module: purpose, authentication, request shape,
success shape, error codes. Terse. This is a lookup, not a tutorial.

**4. Integration Decision Matrix** — for tech leads deciding. One row per
capability: "I need to…", the platform capability, the integration path,
complexity, prerequisites, status. Then the sequencing diagram showing which
capabilities depend on which, recommended starting points by system type, and
a go / caution / hold aid.

All four take their status badges from the same status matrix. All four carry
frontmatter per [doc-lifecycle](../doc-lifecycle/SKILL.md).

## Phase 4 — Review Gate (15 min)

No integration kit is distributed before this gate closes:

1. `product-strategist` reviews the PM brief for value clarity and whether a
   product manager can use it without a developer.
2. `api-reference-writer` reviews the quick reference against the analysis's
   API section, endpoint by endpoint.
3. `factuality-validator` runs the full check from
   [factuality-check](../factuality-check/SKILL.md): 95% verified, zero
   discrepancies.
4. `critical-reviewer` runs the five-phase protocol from
   [critical-review](../critical-review/SKILL.md), with particular attention
   to status badges and capability-depth claims.
5. Documents move DRAFT → VALIDATED only after all four pass.

## Anti-Hallucination

The source-or-silence rule: **if it cannot be traced to a file read during the
analysis, it does not go in the document.**

| Pattern | What the reader suffers | How it happens |
|---|---|---|
| **Invented endpoints** | Calls a URL that 404s, then doubts everything else | The engine infers a plausible path from a feature name |
| **Fabricated request bodies** | Sends malformed requests and debugs their own code | Field names guessed from the data model rather than read from the request schema |
| **Assumed client methods** | Imports something that does not exist | A convenience method is invented because the capability exists |
| **Phantom features** | A quarter is scoped around nothing | A directory, a config key, or a roadmap note is treated as an implementation |
| **Optimistic status** | Builds against something not ready | A badge assigned from file existence rather than implementation depth |
| **Invented configuration** | Sets variables that do nothing, then cannot explain the behaviour | Standard-looking names assumed by convention |
| **Fabricated error codes** | Writes handling for responses that never fire | Error shapes generalised from other systems |

Each is prevented the same way: open the file, cite the line, or leave it out.

Every endpoint, shape, configuration item, and badge carries a traceability
comment in the source form defined by
[factuality-check](../factuality-check/SKILL.md), and obeys the empty-shelf
rule — a category with nothing behind it is omitted from the playbook, appears
in the decision matrix with an honest badge, and appears in the PM brief only
under what is coming. Never as "call `POST /endpoint` (coming soon)".

## Quality Gates

- [ ] A completed analysis and status matrix exist as input
- [ ] Every sentence passes the consumer perspective test
- [ ] Documents organised by use case, never by internal module
- [ ] Every use case carries a complexity score and a status badge
- [ ] Every endpoint traces to a route declaration read during analysis
- [ ] Every request and response shape traces to a schema or type
- [ ] Every configuration item traces to a config or environment declaration
- [ ] Every claim carries a traceability comment with a relative path
- [ ] Capabilities with no implementation are omitted, not stubbed
- [ ] The PM brief is usable by a product manager without a developer
- [ ] All four review-gate roles have signed off before distribution

## Anti-Patterns

- **Writing the kit from the feature list.** The feature list says a
  capability exists; only the route declaration says how to call it.
- **Leaking internals.** Class names and file paths in body text tell the
  reader they are reading the wrong document.
- **Module-shaped organisation.** Grouping by the platform's own structure
  forces the reader to learn it in order to find anything.
- **Effort estimates with no basis.** "Two weeks" derived from nothing is a
  commitment someone else will be held to. Anchor it to endpoint count,
  configuration, and whether data must migrate.
- **Optimistic status to keep a document tidy.** The decision matrix exists to
  carry bad news; let it.
- **Skipping the review gate under deadline.** The whole risk of this artifact
  is concentrated in the step being skipped.

## In this pipeline

- The kit is a work order: `wo new "<platform> integration kit" --area docs`,
  with all four documents in the work-order folder under `{{WORKORDERS_DIR}}`
  and the distribution copy under `{{DOCS_DIR}}`.
- Templates: `integration-playbook.md`, `pm-integration-brief.md`,
  `api-quick-reference.md`, `integration-decision-matrix.md` under
  `{{PIPELINE_ROOT}}/core/templates/docs/`.
- The shared rule is `core/rules/common/documentation.md`.
- `api-reference-writer` owns the quick reference, `product-strategist` the PM
  brief, `developer-experience-writer` the playbook, `factuality-validator`
  and `critical-reviewer` the gate.
- Close with evidence: `wo verify <n> --run <suite>` over the endpoint and
  citation checks. A typed `PASS` is not evidence.
- Command: `/integration-kit`. Requires `/analyze-repo` and `/status-matrix`.
