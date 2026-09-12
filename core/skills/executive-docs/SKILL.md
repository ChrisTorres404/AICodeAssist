---
name: executive-docs
description: Write the two leadership-facing documents from a completed analysis — a two-to-four page product brief covering landscape, vision, capability snapshot, maturity, scale, readiness, and phased rollout, and a three-to-eight page primer covering what a system is, its capabilities, architecture, touchpoints, dependencies, value, and glossary. Use when leadership needs to understand or decide about a platform.
---

# Executive Documentation

Two documents, two readers, two failure modes.

The **product brief** is for leadership deciding whether and how to adopt a
platform. Its failure mode is vagueness: a page of capability adjectives that
supports no decision.

The **primer** is for the manager, architect, or product owner who has to work
with the system and explain it to others. Its failure mode is the opposite: a
condensed technical document that assumes the reader already understands the
thing being explained.

Both are written *down* from a completed analysis and its Feature Profiles.
Never write either first — a summary of nothing is nothing, and leadership
documents written from impressions are how a roadmap acquires a capability
that does not exist.

## When to Use

- Leadership needs a decision-grade view of a platform: `/docs-brief`
- A team or stakeholder needs to understand a system they will work with:
  `/docs-primer`
- An existing overview has drifted from what the system does

Both require a completed `/analyze-repo` and, for any status claim,
`/status-matrix`.

## The Product Brief

**Reader:** senior leadership. **Length:** two to four pages. **Tone:**
business impact, zero unexplained jargon, one paragraph per topic.

### 1. The Landscape

Two or three sentences on the current state of affairs — the "before" picture
that makes the rest necessary. What does the organisation deal with today?
Fragmented approaches, duplicated effort, inconsistency that becomes risk.
Written so a reader with no engineering background follows it completely.

### 2. The Platform Vision

One paragraph. What this system does about the landscape above. Clear,
specific, and confident without being promotional: name what it consolidates
and what teams stop having to build.

### 3. Capability Snapshot

A table of capability domains — from the analysis, not invented — each with one
or two sentences. Write capability *stories*, not feature names.

> **Weak:** "Job scheduling. Webhooks. Rate limiting."
>
> **Strong:** "Background work runs on a single schedule the whole
> organisation can see: what is queued, what ran, what failed, and what was
> retried — so a job that silently stopped running is caught by a dashboard
> rather than by a customer."

Use the domains the analysis produced. Eight is a comfortable number for a
page; fewer is fine if that is what the system has.

### 4. Maturity Assessment

| Maturity | Definition | Count | Examples |
|---|---|---|---|
| Foundational | Core capabilities, fully implemented | | |
| Differentiating | Advanced capabilities, production-ready | | |
| Emerging | Recently added, narrower proving ground | | |

Counts come from the status matrix. A maturity table that disagrees with the
badge counts is the fastest way to lose a technically literate reader.

### 5. The Scale

One paragraph of numbers, narrated rather than listed. Counts of modules,
entry points, entities, supported mechanisms — each doing work in a sentence.
"Forty-one endpoints across nine modules, backed by twenty-eight entities"
tells a reader the size of what they are adopting. A bullet list of the same
numbers tells them nothing.

### 6. Readiness

An overall assessment — ready, ready with caveats, or not yet — and one or two
paragraphs justifying it from the matrix. Name which domains are green and
which carry the caveats. "Ready with caveats" without the caveats named is not
an assessment.

### 7. Recommended Rollout

A phased table: which teams or systems go first, which capabilities they
adopt, and a rough timeframe. Phase 1 is a small pilot on the foundational
capabilities; later phases widen as the caveated domains resolve. Frame the
timings as estimates anchored to integration complexity, never as commitments.

### The Ten-Minute Test

> A senior leader reads this in ten minutes, and can then brief *their* leader
> accurately without opening anything else.

Accurately is the operative word. If the brief is readable but leaves the
reader unable to say what the platform does not yet do, it has failed the test
in the most expensive direction.

## The Primer

**Reader:** managers, architects, product owners, new joiners. **Length:**
three to eight pages. **Tone:** explanatory; technical terms allowed but
always explained on first use.

### 1. Executive Summary

Four sentences, in this order: the problem, what this system does about it,
how it works at a high level, what it enables. A reader who stops here should
still have an accurate picture.

### 2. What This Is

Two or three paragraphs explaining the system to someone who joined last week.
Build understanding progressively. Analogies are welcome where they are
honest. No acronym appears without its definition.

### 3. Key Capabilities

Grouped by domain, each capability a bolded name plus one descriptive sentence.

> **Weak:** "- Retry handling"
>
> **Strong:** "- **Retry handling** — a failed delivery is retried on a
> widening schedule up to a configured ceiling, then parked for manual replay,
> so a subscriber's outage does not become lost data."

### 4. Architecture Overview

What connects to what, and in what order. No implementation detail — the
reader is orienting, not building. A short diagram description or a numbered
flow is usually clearer than a paragraph.

### 5. Integration Touchpoints

A table: touchpoint, what connects to what, protocol, direction. This is the
section people come back to.

### 6. Dependencies

A table: dependency, type, criticality, and — the column people forget — what
happens when it is unavailable. Degraded and fatal are very different answers.

### 7. Business Value

Framed for three audiences, one line each:

- **For teams building on it:** what they no longer have to build.
- **For security and compliance:** what can now be demonstrated.
- **For operations:** what can now be seen and managed without custom tooling.

### 8. Glossary

Every term the document uses that a new reader would not know, defined in
plain language. The glossary is what makes the primer forwardable.

## Quality Gates

- [ ] Both documents written from a completed analysis, never from impressions
- [ ] Every status or maturity claim matches the status matrix
- [ ] Brief is two to four pages; primer is three to eight
- [ ] Brief passes the ten-minute test, including on what is *not* ready
- [ ] Capability snapshot uses the analysis's own domains
- [ ] Scale figures are narrated and traceable to the analysis counts
- [ ] Readiness names the caveats, not just the rating
- [ ] Rollout phases are framed as estimates with their anchor stated
- [ ] Primer defines every acronym on first use and again in the glossary
- [ ] Dependency table says what happens when each dependency is unavailable
- [ ] Both verified per `factuality-check` before leaving REVIEW

## Anti-Patterns

- **Adjective inflation.** "Robust, scalable, enterprise-grade" survives no
  contact with a reader who asks what it means.
- **The brief that hides the gaps.** Leadership discovering a caveat in
  quarter two, after planning around its absence, is the exact failure this
  document exists to prevent.
- **Feature lists as capability snapshots.** Names without stories.
- **Committed-looking timelines.** A rollout table read as a delivery promise
  becomes one. State the anchor and the uncertainty.
- **The primer that is a shortened reference.** Compression is not
  explanation; a reader who does not already understand the system gets
  nothing from a denser version of it.
- **Undefined acronyms.** One is enough to lose the reader the primer exists
  for.
- **Numbers with no denominator.** "Supports eleven mechanisms" needs to say
  eleven of what, and out of what.
- **Writing the brief before the analysis.** It will be pleasant, confident,
  and unverifiable.

## In this pipeline

- Each document is a work order: `wo new "<platform> product brief" --area
  docs`, drafted in the work-order folder under `{{WORKORDERS_DIR}}` and
  distributed from `{{DOCS_DIR}}`.
- Templates: `{{PIPELINE_ROOT}}/core/templates/docs/product-brief.md` and
  `primer.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `product-strategist` owns the brief and its framing; `narrative-curator`
  reviews both for story arc; `factuality-validator` verifies every figure and
  status claim; `critical-reviewer` checks readiness language for over-claims.
- Close with evidence: `wo verify <n> --run <suite>` over the figure and
  badge-consistency checks. `NOT EXECUTED — PLAN ONLY` is honest; a typed
  `PASS` is not.
- Commands: `/docs-brief` and `/docs-primer`. Both require `/analyze-repo` and
  `/status-matrix`.
