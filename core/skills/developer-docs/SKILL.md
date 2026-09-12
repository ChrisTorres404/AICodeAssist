---
name: developer-docs
description: Write consumer-facing developer documentation in progressive disclosure — a quickstart under five minutes, task guides, exhaustive reference, and concepts — with zero internal terminology, runnable samples, a full error reference, a placement manifest, and a navigation proposal. Use when producing or fixing docs that external developers will build against.
---

# Developer Documentation

Developer documentation is judged by one measurement: how long it takes a
reader who has never seen the platform to make a working call. Everything in
this skill serves that number, and then serves the reader who comes back six
months later needing the option they skipped.

The audience is external. They do not work on the platform, they will not read
its source, and they did not attend the meeting where the terminology was
invented.

## When to Use

- A platform needs documentation an outside developer can build from
- Existing docs explain how the system works but not how to use it
- Time-to-first-success is being measured and is bad

Run it with `/docs-developer`.

## Progressive Disclosure

Four tiers. Each answers a different question, and mixing them is the most
common structural failure in developer documentation.

| Tier | Reader's question | Budget | Shape |
|---|---|---|---|
| Quickstart | "Make it work now." | Under 5 minutes | 3-5 numbered steps, copy-paste samples, one verification step |
| Task guide | "I need to do X." | 10-20 minutes | Prerequisites, steps with decision points, verification, what next |
| Reference | "What are all the options?" | Lookup | Every parameter, every error, every setting |
| Concepts | "How does this actually work?" | 30+ minutes | Architecture narrative, flow description, design rationale |

### Quickstart rules

One per integration path — not one per platform. If there is a client library
and a direct HTTP path, that is two quickstarts.

1. Three to five steps. Numbered. Nothing optional.
2. Every step is a copy-paste block, not a description of what to type.
3. It ends with a **verification step** showing the expected output, so the
   reader knows they succeeded rather than assuming.
4. No concepts, no alternatives, no "you may also wish to". Those belong one
   tier down, linked at the bottom.
5. Time it. Actually read it, run it, and count. Over five minutes, cut
   something.

### Task guide rules

One per real task the reader has ("rotate a credential", "handle a failed
delivery", "move from sandbox to production"), never one per endpoint. Opens
with a "what you will need" block, closes with "what's next" links, and
handles the error at each step where an error is likely — not in an appendix.

### Reference rules

Exhaustive is the whole point. Every endpoint with method, path,
authentication, request and response. Every configuration option with its
default and accepted values. Every error. Every client method with its
signature and what it raises. A reference with gaps sends the reader to support.

### Concepts rules

Write one only when the mental model is genuinely non-obvious and the reader
will make wrong decisions without it. A concepts page written because the tier
exists is the page nobody reads.

## Consumer-Facing Quality Rules

These are checkable, and they are checked.

**Zero internal terminology.** No work-order numbers, no internal role names,
no internal project or pipeline references, no class or file names, no
database table names, no references to how the docs were produced. If a term
cannot be found in the platform's public surface, it does not belong on the
page.

**Every code sample includes authentication and error handling.** A sample
without the auth header teaches the reader to write a call that fails. A
sample with no error branch teaches them to ship one that fails silently. Both
appear in *every* sample, including the quickstart — especially the quickstart,
because it is the one that gets copied into production.

**Every replaceable value uses a `YOUR_` placeholder with a sourcing comment.**

```bash
# YOUR_API_KEY — created under Settings → API keys; starts with "pk_"
curl -X POST https://api.example.com/v1/subscriptions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url": "YOUR_CALLBACK_URL", "events": ["invoice.settled"]}'
```

The comment says where the value comes from. Without it the reader has a blank
they cannot fill, which is a support ticket.

**Every error entry has four fields.** Status, response body, plain-English
cause, and the fix.

| Status | Body | Cause | Fix |
|---|---|---|---|
| 401 | `{"error":"invalid_token"}` | The key is wrong, revoked, or from another environment | Check the key matches the environment you are calling |
| 409 | `{"error":"duplicate_subscription"}` | A subscription already exists for this URL and event type | Fetch the existing subscription and update it instead |
| 429 | `{"error":"rate_limited"}` | You exceeded the request allowance for this window | Back off using the `Retry-After` header value |

A code with no cause is a code the reader cannot act on.

**Samples in cURL plus at least one client language.** cURL is the universal
fallback that proves the contract; the client sample is what most readers will
actually paste. Where the docs portal supports tabbed code blocks, present them
as tabs on one sample rather than as two sequential blocks.

## The Placement Manifest

Generated content has to land somewhere. The manifest is the table that says
where, and it is a deliverable, not a note:

| Produced file | Target path in the docs tree | Action | Replaces |
|---|---|---|---|
| `quickstart-http.md` | `docs/get-started/quickstart.md` | new | — |
| `errors.md` | `docs/reference/errors.md` | replace | existing partial error list |

Every produced file appears exactly once. Every target path is checked for an
existing file, and the action says new, replace, or merge. A manifest that
silently overwrites is how a team loses documentation it wrote by hand.

## The Navigation Proposal

Propose the navigation change as a diff against the existing structure — in
MkDocs-style navigation for portals that use it, or the equivalent for
whatever the project's docs site consumes. Rules that hold regardless:

- Maximum three levels deep. Deeper and readers stop finding things.
- Sections named for tasks, not for internal modules: "Handle failures", not
  "Dispatcher".
- The quickstart is the first entry a new reader can reach.
- No orphan pages — every page is reachable from the navigation.
- Every cross-link is relative and resolves to a page that exists.

The proposal is reviewed and applied by the docs owner; it is not applied
silently by the generator.

## Quality Gates

- [ ] One quickstart per integration path, each verified under five minutes
- [ ] Every quickstart ends with a verification step and its expected output
- [ ] Task guides are named for tasks, not endpoints
- [ ] The reference covers every endpoint, option, error, and client method
- [ ] A concepts page exists only where the mental model demands one
- [ ] Zero internal terminology anywhere in the set
- [ ] Every sample includes authentication and error handling
- [ ] Every replaceable value is `YOUR_`-prefixed with a sourcing comment
- [ ] Every error has status, body, cause, and fix
- [ ] Every sample has cURL plus at least one client language
- [ ] Placement manifest complete, with an action per file
- [ ] Navigation proposal at most three levels deep, no orphans, links resolve
- [ ] Every endpoint and shape verified per `factuality-check`

## Anti-Patterns

- **The quickstart that explains.** Concepts in step 2 double the clock.
- **Endpoint-shaped task guides.** "Using POST /subscriptions" is reference
  material wearing a guide's title.
- **Samples without auth.** The reader's first call fails and they blame the
  platform.
- **Bare placeholders.** `<your-key-here>` with no sourcing comment.
- **Error tables without causes.** A list of status codes is not an error
  reference.
- **One language only.** A client-only sample leaves everyone else guessing at
  the wire format; a cURL-only sample makes every reader write their own
  wrapper.
- **Internal vocabulary.** The fastest way to tell a reader these docs were not
  written for them.
- **Generated files with nowhere to go.** Content with no placement manifest
  sits in a work-order folder and is never read.
- **Navigation by module.** It mirrors the org chart and hides the task.

## In this pipeline

- The set is a work order: `wo new "<platform> developer docs" --area docs`,
  drafted in the work-order folder under `{{WORKORDERS_DIR}}` and placed into
  `{{DOCS_DIR}}` per the placement manifest.
- Templates: `developer-quickstart.md`, `task-guide.md`, `error-reference.md`,
  `technical-reference.md`, `placement-manifest.md` under
  `{{PIPELINE_ROOT}}/core/templates/docs/`.
- The shared rule is `core/rules/common/documentation.md`.
- `developer-experience-writer` writes the tiers, `api-reference-writer` owns
  the reference, `documentation-expert` owns placement and navigation,
  `factuality-validator` verifies every sample against source,
  `critical-reviewer` checks for over-claims and missing error cases.
- Close with evidence: `wo verify <n> --run <suite>` over a suite that runs
  the quickstart's calls. Documentation whose samples have been executed is
  the strongest evidence this pipeline produces — and a typed `PASS` is still
  not evidence.
- Command: `/docs-developer`. Related: `/docs-reference`, `/integration-kit`.
