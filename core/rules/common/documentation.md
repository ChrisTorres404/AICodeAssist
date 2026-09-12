# Documentation

Rules for documenting a codebase — this one or one you only analyse.

## Read-only on repositories you do not own

Read anything. Change nothing: no edits, no new files, no git operations, no
build, test, or deploy commands against the target. Output lands in the work
order, never in the analysed repository.

The one exception is a **critical finding** — a security hole or a defect that
loses data or grants access. Record it in a `Critical Findings` section with the
file, the line, and what was observed. State the observation, not the fix.

## Source or silence

If a claim cannot be traced to a source file, it is omitted. It is never
inferred, never extrapolated from a folder name, never filled in from how
systems like this usually work. An empty section beats a fabricated one.

Every endpoint, request or response shape, configuration item, capability claim,
and status badge carries its evidence inline:

```markdown
<!-- SOURCE: src/auth/auth.controller.ts:L45 — @Post('/login') -->
```

## Confidence

| Level | Evidence | May document |
|---|---|---|
| HIGH | Implemented, exercised by tests or callers | Normally |
| MEDIUM | Implemented, no tests or unclear usage | With an explicit verify-before-relying caveat |
| LOW | Partial, experimental, or unclear | Status only — never as available |
| NONE | No source evidence | Nothing. Omit it |

## Status badges

| Badge | Means |
|---|---|
| `IMPLEMENTED` | Working, in the source, reachable |
| `PARTIAL` | Core exists; the limitation is stated |
| `IN DEVELOPMENT` | Active work, not usable yet |
| `PLANNED` | Intended, nothing implemented |
| `NOT AVAILABLE` | Not implemented, not planned |

No `IMPLEMENTED` badge without a code reference. "We are working on it" is not a
status; pick the badge that is true.

## Over-claiming

| Avoid | Use instead |
|---|---|
| never | by design, `<mechanism>` prevents |
| always | under normal operation |
| impossible | structurally prevented by `<mechanism>` |
| guarantees | enforces, validates, checks |
| there is no way | the current implementation prevents |

## Lifecycle

`DRAFT` → `REVIEW` → `VALIDATED` → `FINAL`. Every generated document opens with
frontmatter carrying `wo`, `title`, `version`, `status`, `created`,
`last-modified`, `author`, `reviewed-by`. Advance the status one step at a time,
and only on a passed gate.

## Audience

| Tier | Reader | Answers | Length |
|---|---|---|---|
| Brief | Leadership | What is it, is it ready | 2–4 pages |
| Primer | Managers, architects | What it does, how it fits | 3–8 pages |
| Reference | Engineers, operators | Everything needed to integrate and run it | As long as the surface |
| Developer | External integrators | Make it work, then every option | Tiered, quickstart first |

## The validator is never the author

Factuality and critical review are separate gates run by agents that did not
write the document. Self-review is not a gate.

A hook checks that every `SOURCE` path exists and warns on over-claim words.

Long form: `{{PIPELINE_ROOT}}/core/methodology/KNOWLEDGE-EXTRACTION-METHODOLOGY.md`.
