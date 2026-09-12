# Knowledge Extraction Methodology

> This is non-negotiable. Every agent producing documentation for
> {{PROJECT_NAME}}, or from a repository it analyses, follows it.

The long form of `{{PIPELINE_ROOT}}/core/rules/common/documentation.md`. That
file states the rules; this one explains them, shows the shapes, and lists what
a document has to contain before it counts.

---

## Purpose

Understand a codebase well enough to document it, and document it so every claim
traces to a line of source.

The codebase may not be yours — a service you integrate with, a system you
inherited, a repository you will never commit to. That changes nothing about the
standard of evidence and everything about what you may touch.

The output is a set of artefacts a reader can act on: an analysis with a source
index behind it, a profile per feature, an honest status per capability, and
documentation written for a named audience.

**The failure mode this exists to prevent is the confident invention** — the
endpoint that returns 404, the configuration key that does nothing, the
capability a team scoped a quarter around that was an empty folder. Every gate
below aims at that one failure.

---

## The Read-Only Constitution

When analysing a repository you do not own:

| Permitted | Forbidden |
|---|---|
| Read any file | Modify any file |
| Quote source with path and line attribution | Create or delete files in the target |
| Map structure, dependencies, configuration | Any git operation on the target |
| Record what exists | Run its build, tests, or deployments |
| Generate documentation in the work order | Recommend refactors or rate code quality |

You are in observation mode: **identify** what exists, **document** what is
found, **catalog** what the system can do and requires, **map** how the parts
relate. Not critique, rate, or improve.

### The critical-findings exception

A serious security vulnerability, or a defect that could cause data loss,
unauthorized access, or system failure, is documented — never silently passed
over because the engagement was read-only. It goes in a dedicated
`Critical Findings` section carrying the classification (`CRITICAL-SECURITY` or
`CRITICAL-DEFECT`), the exact file and line, and a factual description of what
was observed. State the observation, not the remedy: the owner of the code
decides what to do about it, and your job was to make sure they know.

---

## The Eight-Phase Analysis

Every documentation command downstream reads this analysis and none may claim
what it did not find. Complete all eight phases; a phase that found nothing is
recorded as empty, never filled in from expectation.

| Phase | Goal | Output section |
|---|---|---|
| 1. Structural survey | Layout and technology stack | Repository structure and stack |
| 2. Feature inventory | Every capability the system provides | Feature inventory |
| 3. API surface | Every exposed endpoint | API surface |
| 4. Data models | Every entity, schema, and relationship | Data models |
| 5. Authentication and authorization | Every mechanism, token, role, policy | Authentication and authorization |
| 6. Dependencies and integrations | Libraries, services, configuration, secrets | Dependencies and integrations |
| 7. Feature Profiles | The inventory turned into narrative | Feature Profiles |
| 8. Cross-feature map | What depends on what, and what breaks | Cross-feature dependency map |

What each phase records:

1. The manifest, entry point, top three directory levels, and counts of routes,
   services, models, and tests.
2. Every feature, classified internal or consumer-facing, with what it does,
   where it lives, what it requires, and what it exposes.
3. Per endpoint: method, path, authentication requirement, request and response
   shape, throttling — grouped by domain.
4. Per entity: storage name, fields and types, relationships, constraints, and
   which code reads and writes it.
5. Guards and middleware, token types, role and permission structures, session
   handling, and the security configuration around them.
6. Dependencies with versions, external and internal service dependencies,
   required environment variables and secrets.
7. A Feature Profile for every feature found in phase 2.
8. Per feature: what must exist for it to work, what breaks without it, and the
   clusters those relationships form.

### The source-reference index

Every file read is recorded with its line ranges and what it established. This
index is the evidence every later gate checks against; a document without one
behind it is not reviewable.

---

## The Feature Profile

Every feature in the inventory gets one. **A feature named without a profile is
an incomplete deliverable.** Nine parts, all required:

| Part | Contains | Fails when |
|---|---|---|
| 1. In one sentence | What it does, jargon-free | You cannot write it — you do not understand the feature yet |
| 2. The full picture | Two or three sentences of mechanism and scope | It repeats part 1 with longer words |
| 3. The problem it solves | What life looks like without it | It restates the feature as its own justification |
| 4. How it works | Numbered walkthrough, trigger to outcome | It says "requests are processed" |
| 5. Use case scenarios | Two or three concrete, named situations | They are hypothetical rather than recognisable |
| 6. Edge cases and gotchas | Limits, failure modes, surprises | Only the happy path is documented |
| 7. How it connects | Upstream inputs, downstream consumers, position in the flow | The feature is described in isolation |
| 8. What it enables | The value, in the reader's terms | It never answers "so what?" |
| 9. Quick reference | Module, source, configuration, dependencies, admin surface | It is missing, so nobody can look anything up |

### The explain-it-to-me test

> Can you explain what this feature does to someone who has never seen this
> domain, in two sentences, using no acronym they would not know?

If not, the profile is not ready for review.

---

## Documentation Tiers

One analysis, four audiences. The tier decides length, tone, and sections, and
is chosen before the first sentence, not discovered afterwards.

**Brief — leadership.** The landscape before this system, what it is in one
paragraph, the capability snapshot by domain, maturity, the scale in narrated
numbers, readiness, and a phased rollout. Two to four pages, every technical
term defined where it first appears or cut.

**Primer — managers and architects.** Executive summary, what this is in plain
language, key capabilities, architecture overview, integration touchpoints,
dependencies, value, glossary. Three to eight pages. The test is whether the
reader can afterwards explain the system to their own team.

**Reference — engineers and operators.** Scope, architecture detail, API
surface, data models, authentication and authorization, configuration,
dependencies, integration points, error codes with cause and resolution,
operational considerations, source references. As long as the surface is, and
precision over readability where the two conflict.

**Developer — external integrators**, by progressive disclosure:

| Sub-tier | Reader need | Budget | Shape |
|---|---|---|---|
| Quickstart | Make it work now | Under 5 minutes | 3–5 steps, copy-paste, working call at the end |
| Task guide | I need to do one thing | 10–20 minutes | Prerequisites, steps, decisions, verification |
| Reference | What are all the options | Lookup | Every parameter, error, and setting |
| Concept | How does this work | 30 minutes | Architecture narrative, only where non-obvious |

Written for someone who will never open the repository: no internal class names,
module paths, or work-order numbers in the text. Every sample carries
authentication and error handling; every replaceable value says where the reader
gets it; every error has a status, a body, a plain cause, and the fix. Source
attribution lives in a reference section, not inline with the instructions.

---

## The Seven Quality Gates

A document passes all seven or it does not advance.

| Gate | Checks |
|---|---|
| 1. Structural completeness | Every section the tier requires is present; frontmatter complete; no `TBD`, no empty section |
| 2. Factual accuracy | Every technical claim carries a source reference; endpoints, shapes, and configuration re-derived from source |
| 3. Placement and naming | In the work-order folder, named for it, cross-references carry the work-order number |
| 4. Readability | Right tier for the reader, consistent terms, acronyms defined once, tables for structured data |
| 5. Narrative depth | Every feature has a profile; no name-only references; narrative precedes every table; value articulated |
| 6. Integration guidance | Answers say how to use the capability, not only what it is; profiles carry use cases and edge cases |
| 7. Planning artefacts | The work order's required documents existed before generation began |

Gates 2 and 5 are the ones skipped under time pressure, and the two that make
the document worth reading.

---

## Document Lifecycle

```
DRAFT → REVIEW → VALIDATED → FINAL
```

| Status | Meaning | Who acts |
|---|---|---|
| `DRAFT` | Generated, unchecked | The author |
| `REVIEW` | Structure and completeness confirmed | A reviewer who did not write it |
| `VALIDATED` | Every claim confirmed against source | The factuality gate |
| `FINAL` | Approved for distribution | The owner |

Frontmatter on every generated document: `wo`, `title`, `version`, `status`,
`created`, `last-modified`, `author`, `reviewed-by`. Versions move one step at a
time: a structural rewrite is a major bump, a correction within the structure a
minor one, and a modified document records what changed.

**The validator is never the author.** Self-review is not a gate.

---

## The FAQ Engine

The questions are discovered, never reused from the last project:
`analysis → domain discovery → question design → grounded answers → critical review`.

1. **Domains** come from clustering the feature inventory by function, not by
   folder. Ten to twenty: a cluster of fewer than three features merges into a
   neighbour, and more than twenty domains means consolidating.
2. **Ten questions per domain**, and the constraint is the point — it forces the
   ten that matter. Cover architecture, capabilities, edge cases, integration,
   and gaps. A yes-or-no question wastes one of the ten.
3. **Seven-part answers**: status badge, technical answer, code reference,
   integration guidance, plain-language summary, gap analysis where the badge is
   not `IMPLEMENTED`, and cross-references.
4. **Critical review is mandatory.** Contradictions between answers, badges the
   source does not support, and absolute language are found and remediated
   before the package leaves `DRAFT`.
5. **The status matrix** is generated alongside it, and every badge reconciled.

A good question is one an integrating team lead would actually ask — "if my
traffic all arrives from one address, how does this tell an attack from normal
load?" — not "does this have rate limiting?"

---

## The Integration Kit

Four documents, four phases, one audience: a team integrating with this system
that will never read its source.

| Phase | Produces |
|---|---|
| 1. Surface extraction | The externally consumable endpoints, client methods, auth mechanisms, and configuration |
| 2. Use-case mapping | That surface regrouped by what a consumer wants to do, scored Simple / Moderate / Complex, badged for readiness |
| 3. Generation | The playbook, capability brief, API quick-reference, decision matrix |
| 4. The gate | Factuality and critical review, either of which holds the kit in `DRAFT` |

Organise by the consumer's goal, never by the internal module layout.

### Anti-hallucination guardrails

The highest-risk output in the set: a fabricated endpoint costs a reader days.
Every claim is provably grounded or it is absent.

| Claim | Must be confirmed in | The failure it prevents |
|---|---|---|
| Endpoint | A route or controller file, exact path | A URL that returns 404 |
| Client method | An exported module, exact name | An import that does not resolve |
| Configuration item | A config or environment file | A setting that does nothing |
| Request or response shape | The actual type or schema definition | Malformed requests built from a guess |
| Capability | Implemented code, not intent or folder | A quarter scoped around a phantom |
| Status badge | The status matrix and the source | A team planning against something unready |

**The empty-shelf rule.** If the implementation is not there, the section is
omitted entirely; the capability appears in the decision matrix with its honest
badge and in the brief under what is coming — never as an instruction with a
caveat attached. An empty section beats a fabricated one; silence beats invention.

---

## Feasibility Analysis

The question is whether a system can meet a stated requirement, and the answer
is allowed to be no.

1. **Restate** the requirement as testable conditions; an unstated assumption is
   a question for the requester, not a guess.
2. **Map** each condition to evidence with a source reference, or record that
   nothing satisfies it — nothing is a finding, not a blank.
3. **State the gap** per condition, from the code, not a reference architecture.
4. **Size it**: the work, the blast radius across everything the cross-feature
   map shows depends on the same code, and the risks that would move the number.
5. **Verdict**, with the conditions that decided it and what would change it:

| Verdict | Means |
|---|---|
| `FEASIBLE AS BUILT` | The conditions are already satisfied |
| `FEASIBLE WITH WORK` | Additive work on existing foundations |
| `FEASIBLE WITH MATERIAL REWORK` | A load-bearing assumption has to change |
| `NOT FEASIBLE AS DESIGNED` | The requirement conflicts with the architecture |

A grounded no, delivered early, is the most valuable output here; an ungrounded
yes the most expensive.

---

## It All Runs Through Work Orders

No documentation is produced outside a work order; the folder is the record.

```bash
wo new "<repo> analysis" --area analysis   # analysis, status matrix, feasibility
wo new "<repo> primer"   --area docs       # every documentation deliverable
```

| Area | Implement with | Backup | Validate with |
|---|---|---|---|
| `analysis` | `repo-analyst` | `code-explorer` | `factuality-validator` |
| `docs` | `documentation-expert` | `developer-experience-writer` | `critical-reviewer` |

Every artefact lands in the work-order folder, every file name begins with the
work-order number, every cross-reference carries it, and the source-reference
index lives beside the documents it supports.

The analysis is the root of the tree: the status matrix, the brief, the primer,
the reference, the FAQ, the developer docs, the integration kit, and every
feasibility verdict read it. Run it first; rerun it when the target changes, and
reconcile what moved.

Long extraction work is handed off rather than restarted: the `session-handoff`
skill carries what was found, what is open, and what to read first.

---

## Anti-Patterns

These have each cost real rework. Do not repeat them.

1. **The confident invention.** An endpoint, field, or setting written down
   because it is what a system like this would probably have.
2. **Folder-as-feature.** A directory named for a capability, documented as the
   capability, with nothing implemented inside it.
3. **Optimistic badges.** `IMPLEMENTED` because a file exists rather than
   because the logic in it works.
4. **Name-only references.** A feature mentioned, never explained: the reader
   learns a word instead of a system.
5. **Bullet soup and table-only documents.** Structure with no narrative, so
   nobody can tell what the table means.
6. **The jargon wall.** Five acronyms in one sentence, none of them defined.
7. **Happy-path-only profiles.** No edge cases, so every surprise reaches the
   reader in production.
8. **Absolute language.** An invitation to the counter-example, in writing.
9. **Rubber-stamp review.** Approving without re-deriving one claim from source
   — worse than no review, because it launders the document.
10. **Self-validation.** The author confirming their own work as a passed gate.
11. **Documenting the target by changing it.** Any edit, commit, or test against
    a repository you were given to read.
12. **The orphan document.** No work order, no source index, no way to check it.

---

No exceptions. This is the standard.
