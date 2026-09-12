---
name: feasibility-analysis
description: Answer "can the platform do X, and is it a blocker?" with a structured verdict — the requirement restated in the asker's language, a three-sentence problem statement, how the platform handles it today with quoted evidence, the configuration the asker would write, a phased integration path, a decision matrix, limitations with real impact, and required actions. Use when a team raises a capability question that gates their work.
---

# Feasibility Analysis

A team is integrating with a platform and has hit a question: *does it support
this, and if not, are we blocked?* They need an answer today, backed by
evidence, in language they recognise. A feasibility analysis is that answer,
in a shape that can be pasted into a ticket and acted on.

It is short, specific, and decisive. Its defining property is the verdict near
the top: a reader must be able to learn whether they are blocked in the first
fifteen seconds and then read the justification at their own pace.

## When to Use

- A team raises a requirement as a potential blocker and needs a yes or no
- Someone asks "can the platform do X?" about a capability nobody has used yet
- A requirement exists as a sentence in a ticket and must become a path or a
  refusal

Run it with `/feasibility`. Requires a completed `/analyze-repo`; a
`/status-matrix` makes the verdict defensible.

## The Structure

### Header

The requirement identifier, the ticket, the date, and three one-line fields:
the **requirement** restated in one sentence, the **use case** — the business
scenario behind it — and the **question** this analysis answers, phrased so it
has a yes or no answer.

Restate the requirement **in the asker's own language**, using their terms for
their entities. If they call it an entitlement and the platform calls it a
permission, the header says entitlement and the analysis body introduces the
translation. Rewriting their vocabulary into the platform's before answering is
the fastest way to make a correct answer feel like a non-answer.

### Problem Statement — Exactly Three Sentences

1. **Context** — who is asking and what they are trying to do.
2. **Mechanics** — the specific technical behaviour they need, precise about
   inputs, outputs, and the logic between them.
3. **Gap** — why they cannot proceed without this answer.

Three sentences is a constraint that forces clarity. A five-paragraph problem
statement means the question is not yet understood.

### Goal

One sentence. What this analysis determines.

### Verdict

Two or three sentences, immediately after the goal, under a heading that
states the answer:

- Is it supported? Natively, with a workaround, or not at all.
- What mechanism satisfies it? Name it.
- Are changes to the platform required?

`NOT A BLOCKER` and `BLOCKER` are both complete answers. A verdict that hedges
is worse than either, because the reader has to keep reading to find out
whether to escalate — and will escalate anyway.

### The Requirement in Full

Now restate the requirement with all its specifics: the exact identifiers, the
example data from the ticket, the precise logic — whether conditions combine
with and, with or, or require all. This is the shared source of truth for what
was evaluated. When someone later says "that is not what we asked", this
section settles it.

### How the Platform Handles This Today

The core of the analysis. For each mechanism involved:

1. Name the mechanism and explain it in two or three plain sentences.
2. Quote the documentation that describes it, with the document path — an
   exact quotation, not a paraphrase.
3. Show the implementation: the source path, the line, and only the lines that
   matter, annotated.
4. Explain, in one or two sentences, what that code does *in the context of
   this requirement*.

Both halves are load-bearing. Documentation alone can be stale; source alone
does not tell the asker what the platform intends to keep supporting. Quoting
both, and noting when they disagree, is often the most valuable output.

### The Definition the Asker Would Write

Show the exact configuration, policy, or definition the asking team would
author, in the real format, ready to adapt. If there is more than one
reasonable shape — a simple one and a granular one — show both as options and
recommend one, with the reason.

This section is why the analysis gets used instead of summarised. A verdict
tells them they can proceed; this tells them what to type.

### Integration Path

Phased, three to five steps per phase, each with how to verify it worked:

- **Phase 1** — registration or setup.
- **Phase 2** — enforcement, with an example request and its real response.
- **Phase 3** — consumer-side integration, where it applies.

Examples come from the analysis, not from imagination. An invented request in
a feasibility document is the same failure as an invented endpoint in an
integration kit, delivered to a reader who is even more likely to act on it
immediately.

### Decision Matrix

Concrete scenarios, one per row: what the actor holds or sends, what gets
evaluated, the outcome, and a short reason. Cover the happy path, at least one
edge case, and at least one denial. This table is what the asking team will
turn into their own test cases.

| Input | Check | Result | Reason |
|---|---|---|---|

### Known Limitations

Only the limitations **relevant to this requirement**. For each, the
limitation and its actual impact here — and "no impact on this requirement" is
a valid and useful second column. A general limitations list padded in from
elsewhere buries the one that matters.

### Required Actions

A numbered list of what the asking team must do before this works in
production. Name the specific call, setting, or registration step. Anything
that requires someone else's action says whose.

### Summary Table

One row per key question, answered yes or no with a short phrase. The last two
rows are always the same:

| Question | Answer |
|---|---|
| … | … |
| Platform changes needed? | Yes / No |
| Blocker? | Yes / No |

Close with a one-sentence recommendation: proceed, escalate, or requires
platform work.

## Quality Gates

- [ ] The requirement is restated in the asker's own vocabulary
- [ ] The problem statement is exactly three sentences
- [ ] The verdict appears before any supporting detail and does not hedge
- [ ] Every mechanism claim carries both a documentation quote and a source
      citation with a line reference
- [ ] The definition or configuration shown is in the real format and complete
      enough to adapt
- [ ] Every example request and response is drawn from the analysis
- [ ] The decision matrix covers a happy path, an edge case, and a denial
- [ ] Limitations are filtered to this requirement, each with its actual impact
- [ ] Required actions are specific and name the owner where it is not the
      asking team
- [ ] The summary table ends with the platform-changes and blocker rows
- [ ] Verified per `factuality-check` before it is sent

## Anti-Patterns

- **Answering in the platform's vocabulary.** The asker has to translate it
  back, and will not trust the translation.
- **Burying the verdict.** A reader who cannot find the answer in fifteen
  seconds assumes it is bad news.
- **The hedged verdict.** "Partially supported, depending" leaves the decision
  exactly where it was.
- **Paraphrasing the documentation.** Quote it. A paraphrase is a new claim
  that nobody verified.
- **Invented example payloads.** The single most dangerous line in this
  document, because it will be pasted into a client within the hour.
- **Generic limitations.** A copied list where three lines matter and twelve
  do not.
- **Skipping the definition section.** The verdict without the artifact means
  the asking team opens another ticket to get it.
- **Effort estimates in place of a path.** "About a week" is not an answer to
  "how".
- **Answering from memory of a similar platform.** Adjacent systems are where
  fabricated capabilities come from.

## In this pipeline

- The analysis is a work order: `wo new "<requirement> feasibility" --area
  analysis`, in the work-order folder under `{{WORKORDERS_DIR}}`, with the
  copy sent to the asking team placed under `{{DOCS_DIR}}`.
- Template: `{{PIPELINE_ROOT}}/core/templates/docs/feasibility-analysis.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `repo-analyst` establishes how the platform handles it; `api-reference-writer`
  checks the example requests; `factuality-validator` verifies the quotes and
  citations; `critical-reviewer` checks the verdict against the status matrix.
- Close with evidence: `wo verify <n> --run <suite>` over a suite that runs
  the integration path's calls. When the path can be executed, execute it —
  that is the strongest possible answer to "are we blocked?". A typed `PASS`
  is not evidence.
- Command: `/feasibility`. Requires `/analyze-repo`; check `/status-matrix`
  before writing the verdict.
