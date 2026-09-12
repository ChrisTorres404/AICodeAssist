---
name: feature-profile
description: Write a nine-part Feature Profile that explains a capability in narrative form — one sentence, full picture, problem solved, how it works, use cases, edge cases, connections, what it enables, quick reference. Use when documenting a discovered feature, enriching a repository analysis, or fixing documentation that lists features by name without explaining them.
---

# Feature Profile

A feature inventory tells you a system has a webhook dispatcher. A Feature
Profile tells you what happens when it retries, what it costs you when it is
down, and which team gets paged. The profile is the unit of narrative
documentation in this pipeline: every feature discovered in phase 2 of
[repo-analysis](../repo-analysis/SKILL.md) gets one, and a feature mentioned
anywhere without a profile behind it is an incomplete deliverable.

## When to Use

- During phase 7 of a repository analysis, for every discovered feature
- When existing documentation names features without explaining them
- Before writing an FAQ domain, a primer, or an integration playbook — those
  read profiles, not code
- When a reviewer says a document is "a wall of bullets"

## The Nine Parts

All nine. A profile missing parts 5 and 6 is the old six-part shape and it is
exactly the shape that gets a document rejected in review, because it
documents only the happy path.

### Part 1 — In One Sentence

One jargon-free sentence. If you cannot write it, you do not yet understand
the feature; go back to the source.

> **Bad:** "Handles rate limiting for API requests."
>
> **Good:** "A traffic governor that protects every endpoint by counting
> requests along four independent dimensions at once — per organisation, per
> user, per source address, and per route — so one noisy caller cannot
> degrade the service for anyone else."

The bad version restates the feature's name. The good version tells you the
mechanism and the stake in one breath.

### Part 2 — The Full Picture

Two or three sentences that expand part 1 with technical substance: the key
mechanism, the scope of what it covers, and one concrete detail that makes a
reader want to keep going.

> **Bad:** "It also supports configuration and logging."
>
> **Good:** "The limiter runs first in the request chain, ahead of
> authentication, so it protects unauthenticated routes from credential
> stuffing as well as authenticated ones from runaway clients. Limits are set
> per service tier, internal address ranges can be exempted, and every
> rejection is written to the audit log as a security event rather than
> discarded."

### Part 3 — The Problem It Solves

Two or three sentences describing life *without* the feature. What breaks,
what is at risk, who feels the pain.

> **Bad:** "Job scheduling is needed to run jobs on a schedule."
>
> **Good:** "Without a central scheduler, every service grows its own timer
> loop, and nobody can answer 'what ran last night and did it finish?'.
> Overlapping runs corrupt shared state, a restarted process silently skips a
> window, and the first sign of trouble is a customer noticing a report that
> never arrived."

### Part 4 — How It Works

A numbered walkthrough of the happy path, from trigger to outcome. Name the
components. Describe what each one does. Keep the sequence honest — if there
is a queue in the middle, the queue is a step.

> **Bad:** "Webhooks are delivered to subscribers when events occur."
>
> **Good:**
> ```
> 1. A domain event is published to the internal event bus.
> 2. The dispatcher matches the event type against active subscriptions
>    for that organisation.
> 3. For each match it builds a signed payload: body, timestamp, and an
>    HMAC signature over both, using the subscription's own secret.
> 4. Delivery is enqueued rather than attempted inline, so a slow
>    subscriber never blocks the publishing request.
> 5. A worker POSTs the payload. Any 2xx marks the delivery complete.
> 6. Anything else schedules a retry with exponential backoff, up to the
>    configured attempt ceiling, after which the delivery is parked in the
>    dead-letter list for manual replay.
> ```

### Part 5 — Use Case Scenarios

Two or three concrete, named scenarios with realistic actors and quantities.
The reader should recognise their own situation in at least one.

> - **Nightly reconciliation:** A finance service subscribes to
>   `invoice.settled`. Roughly 4,000 events land between 01:00 and 02:00. The
>   queue absorbs the burst; the subscriber's own rate of 50 per second sets
>   the drain speed, and the publishing service never slows down.
> - **A subscriber that goes down at the worst time:** A partner's endpoint
>   returns 503 for forty minutes during a deploy. Backoff spaces the retries
>   out, all deliveries succeed once the endpoint returns, and nothing is lost
>   or duplicated because delivery is keyed by event id.
> - **A silently wrong secret:** A team rotates its signing secret in its own
>   config but not in the subscription. Every delivery returns 401. After the
>   attempt ceiling the deliveries park in the dead-letter list, which is where
>   the team finds them.

### Part 6 — Edge Cases and Gotchas

The warnings an experienced colleague gives you unprompted. Bold label, then
the consequence.

> - **At-least-once, not exactly-once:** A subscriber that times out after
>   processing will be retried. Consumers must key on the event id.
> - **Ordering is not guaranteed across types:** Two events published in the
>   same transaction can arrive in either order. Do not build a state machine
>   that assumes otherwise.
> - **Payload size ceiling:** Bodies above the configured limit are truncated
>   rather than rejected, so a subscriber relying on a large embedded object
>   sees a partial record with no error.

### Part 7 — How It Connects

Upstream: what must exist for this to work. Downstream: what consumes its
output, and what breaks without it. Position: where it sits in the request or
event lifecycle. Point at the cross-feature map from phase 8 of the analysis
rather than inventing relationships.

### Part 8 — What It Enables

The "so what?", in the reader's terms, not the implementer's.

| Feature | Bad | Good |
|---|---|---|
| Webhook dispatch | "Delivers webhook events." | "Lets a consuming team react to changes the moment they happen instead of polling every minute — cutting both their infrastructure cost and the lag a user sees." |
| Audit logging | "Logs security events." | "Produces a tamper-evident record of every authentication, permission change, and administrative action — which is what an auditor asks for first and what a forensic investigation starts from." |
| Job scheduling | "Runs jobs on a schedule." | "Gives operations one place to see what is scheduled, what ran, and what failed — so a missed nightly job is caught by a dashboard rather than by a customer." |

### Part 9 — Quick Reference

A compact lookup table: module, source paths, configuration keys,
dependencies, administrative surface, status badge. This is the part people
come back to; keep it dense and keep it accurate.

## The Story Arc

Every profile, and every document built from profiles, follows one arc:

```
SETUP  →  CONTEXT  →  MECHANISM  →  IMPACT
```

| Phase | Answers | Lives in |
|---|---|---|
| Setup | What are we looking at? | Parts 1-2 |
| Context | Why does it matter? | Part 3 |
| Mechanism | How does it work? | Parts 4-7 |
| Impact | What does it enable? | Parts 8-9 |

A profile that opens with mechanism has skipped the reason anybody should read
it. A profile that never reaches impact is a description of code.

## Audience Tiers

The same feature is written four ways. Know which one you are writing.

| Tier | Reader | Rule | Test |
|---|---|---|---|
| 0 | Executive leadership | Zero jargon; define any term you must use; one paragraph per topic | "Could this go on a slide?" |
| 1 | Managers, architects, product | Technical terms allowed, but say *why*, not only *what* | "Can they explain this to their team afterwards?" |
| 2 | Integrating engineers (primary) | Maximum practical detail; every step says what it connects to and why | "Can they start building without asking a question?" |
| 3 | Developers at the keyboard | Contracts, examples, error causes and fixes | "Can they implement from this page alone?" |

Full profiles are written at tier 2 and summarised upward. Never write upward
first; a summary of nothing is nothing.

## The Two-Sentence Test

> Can you explain what this feature does, to someone who has never worked on
> this kind of system, in two sentences, without using an acronym they would
> not know?

Apply it to part 1 plus part 3 before marking any profile ready for review. If
the answer is no, the profile is not finished — and no amount of detail in
parts 4 through 9 will rescue it.

## Cross-Feature Weaving

Features do not live alone. Every profile must place its feature in the larger
system:

- **Where in the lifecycle does it run?** "First in the request chain, before
  authentication" is a fact a reader can act on.
- **What depends on it?** Name the features, not "other components".
- **What should a neighbouring team know?** "You cannot issue service
  credentials without also setting a rate limit for the issuing organisation"
  saves someone a day.

Weaving is what turns fifteen profiles into one document. Without it you have
fifteen documents in one file.

## Quality Gates

- [ ] All nine parts present; none collapsed into another
- [ ] Part 1 passes the two-sentence test with part 3
- [ ] Part 4 is a numbered sequence, not a paragraph of prose
- [ ] Part 5 has at least two named scenarios with realistic quantities
- [ ] Part 6 has at least two gotchas, and at least one is a real limitation
- [ ] Part 7 names actual upstream and downstream features
- [ ] Part 8 is written in the reader's terms, not the implementer's
- [ ] Part 9 carries source paths that appear in the source-reference index
- [ ] A narrative paragraph precedes every table in the document
- [ ] The profile belongs to a capability domain with at least three members

## Anti-Patterns

- **Bullet soup** — fifteen bullets with no connective prose.
- **Table-only sections** — a table with nothing saying what it means.
- **Jargon wall** — five acronyms in one sentence, none defined.
- **Passive voice** — "authentication is handled" hides who does what. Name
  the component: "the login handler validates the credential".
- **Vague descriptors** — "handles scheduling" instead of the mechanism.
- **Name-only references** — mentioning a feature without explaining it. This
  is the single most common defect and the reason this skill exists.
- **Implementation without consequence** — "uses a 30-second lock" without
  saying what happens at second 31.
- **Happy path only** — parts 5 and 6 exist precisely to prevent this.
- **Copying part 1 into part 2** — part 2 must add mechanism, not adjectives.

## In this pipeline

- Profiles are produced inside an analysis work order: `wo new "<repo>
  feature profiles" --area analysis`, stored in the work-order folder under
  `{{WORKORDERS_DIR}}`, distributed from `{{DOCS_DIR}}`.
- Template: `{{PIPELINE_ROOT}}/core/templates/docs/feature-profile.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `repo-analyst` drafts profiles from the inventory; `narrative-curator` owns
  narrative quality; `factuality-validator` checks part 9 against source.
- Close with evidence: `wo verify <n> --run <suite>`; a typed `PASS` is not
  evidence.
- Commands: `/analyze-repo` produces profiles; `/docs-faq`, `/docs-primer` and
  `/integration-kit` consume them.
