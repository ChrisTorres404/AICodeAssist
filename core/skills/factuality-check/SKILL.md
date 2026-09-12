---
name: factuality-check
description: Verify every claim in a generated document against its source — build a claim inventory, check each one, mark it VERIFIED, UNVERIFIED, or DISCREPANCY, and report against a 95 percent bar. Use before moving any document to VALIDATED, and whenever a document asserts endpoints, shapes, configuration, or status that a reader will act on.
---

# Factuality Check

The critical review asks whether a document over-claims. The factuality check
asks something narrower and harder: **is each individual statement true of the
code as it exists right now?** It is the gate between REVIEW and VALIDATED,
and it is the only step that touches every sentence.

A document that passes review but not this check reads well and misleads
precisely.

## When to Use

- Before any document moves to VALIDATED — see
  [doc-lifecycle](../doc-lifecycle/SKILL.md)
- After any remediation from [critical-review](../critical-review/SKILL.md),
  because new wording is a new claim
- Before an integration kit or reference set is handed to a consuming team
- When a reader reports that something in the docs does not work

## Step 1 — Claim Inventory

You cannot verify what you have not enumerated. Read the document and extract
every checkable assertion into a numbered inventory before verifying anything.

A claim is checkable when a specific file could prove it true or false:

| Claim class | Examples |
|---|---|
| Interface | An endpoint's method and path; a client method's name and signature |
| Shape | Request and response fields, their types, which are required |
| Configuration | Setting and variable names, defaults, accepted values |
| Behaviour | Retry counts, timeouts, ordering, what happens on failure |
| Status | Every badge on every capability |
| Quantity | Counts of entities, routes, supported mechanisms |
| Relationship | "A must be configured before B"; "C fires D" |

Narrative framing — "this matters because teams otherwise rebuild it" — is not
a claim and is not inventoried. Do not pad the inventory with prose to raise
the percentage; the verification rate only means something if the denominator
is the set of statements a reader would act on.

Record each as: claim number, the quoted text, its class, and the document
location.

## Step 2 — Verify Each Claim Against Source

For each claim, open the file it depends on. Reading the analysis document is
not verification — the analysis is itself a claim set. Go to the source.

Assign one verdict:

| Verdict | Meaning | What the report shows |
|---|---|---|
| `VERIFIED` | The source confirms the claim as written | File and line range |
| `UNVERIFIED` | No source evidence found either way | What was searched, and where |
| `DISCREPANCY` | The source contradicts the claim | The claim, what the source says, the citation |

`UNVERIFIED` and `DISCREPANCY` are different failures with different fixes.
An unverified claim may be true but uncitable — the fix is to find the source
or remove the claim. A discrepancy is a document that is wrong — the fix is to
correct the document, and to ask what else came from the same assumption.

Verify against the current state of the code. A claim that was true two
releases ago is a discrepancy today.

## Step 3 — The Report

```
# Factuality Report — <document>

Document, version, date, verifier role.

## Summary
Total claims: N
VERIFIED: N (P%)
UNVERIFIED: N
DISCREPANCY: N
Verdict: PASS | FAIL

## Discrepancies         (each: claim, document text, source text, citation, fix)
## Unverified Claims     (each: claim, what was searched, recommended action)
## Verified Claims       (table: number, claim, citation, confidence)
## Recommended Actions   (ordered; discrepancies first)
```

### The 95 Percent Bar

> A document passes when **at least 95% of its claims are VERIFIED and there
> are zero DISCREPANCY findings**. Anything else is a FAIL and the document
> stays in REVIEW.

Both halves matter. A single discrepancy fails the document regardless of the
percentage — one wrong endpoint costs a reader more than five uncited
sentences. And the remaining 5% is headroom for claims that are true but
awkward to cite, not a quota of acceptable guesses.

Do not report a percentage you did not compute from a real inventory. This
check exists to be the one number in the set that cannot be felt out.

## Step 4 — Traceability Comments

Every claim that survives carries its citation in the document itself, as an
HTML comment the reader never sees:

```markdown
<!-- SOURCE: src/webhooks/dispatcher.ts:L12 — retry ceiling read from config -->
```

The convention:

- The path is relative to the analysed repository's root. Never an absolute
  host path — those fail `bin/sanitize` and mean nothing to another reader.
- One line number or range, pointing at the line that proves the claim.
- A short note saying what was confirmed there.
- The comment sits immediately above or beside the claim, never collected at
  the end of the section where it can drift away from what it cites.

Mandatory for endpoints, request and response shapes, configuration items, and
status badges. Optional but valuable for behavioural claims.

### Confidence Levels

Source evidence is not uniformly strong. Record the level alongside the
citation and let it govern what the document is allowed to say:

| Level | Evidence | What the document may do |
|---|---|---|
| `HIGH` | The code exists, is exercised by tests or callers, and the path is reachable | Document normally |
| `MEDIUM` | The code exists but nothing exercises it, or usage is unclear | Document with an explicit caveat to verify in a sandbox first |
| `LOW` | Partial or experimental implementation, or the reachable path is unclear | Do not present as available; it may appear only under a non-implemented badge |
| `NONE` | No source evidence | Do not document it at all |

### The Empty Shelf Rule

> **When there is no evidence, omit. Never fabricate, and never write a
> placeholder that looks like a claim.**

If a category has nothing behind it, the category does not appear in the
consumer-facing document. It appears in the status matrix with an honest
badge, and in the forward-looking section of a brief — never as a section
with invented content, and never as "call `POST /coming-soon`".

An empty shelf is infinitely better than a stocked-looking one. A reader who
finds nothing looks elsewhere; a reader who finds something wrong builds on it.

## Quality Gates

- [ ] A numbered claim inventory exists before any verification began
- [ ] Every claim in it carries a verdict; none left blank
- [ ] Every VERIFIED claim cites a file and a line range
- [ ] Every DISCREPANCY names both the document text and the source text
- [ ] Every UNVERIFIED claim records what was searched
- [ ] Verification was against source, not against the analysis document
- [ ] The percentage was computed from the inventory, not estimated
- [ ] Zero discrepancies before any PASS is recorded
- [ ] Traceability comments present on every endpoint, shape, config item, and
      badge, with relative paths
- [ ] Confidence levels recorded; nothing at `LOW` or `NONE` is presented as
      available
- [ ] Re-run after remediation, over the changed claims

## Anti-Patterns

- **Verifying against the analysis.** The analysis is a claim set. Both were
  written by the same process and will agree with each other while both are
  wrong.
- **Inventory padding.** Counting narrative sentences to lift the percentage.
- **The friendly percentage.** A number reported without an inventory behind
  it. If you cannot show the rows, do not show the rate.
- **Treating unverified as passing.** It is a claim nobody can check, which is
  the definition of something a reader should not act on.
- **Absolute paths in traceability comments.** They break for everyone else
  and fail sanitisation.
- **Citing a file, not a line.** "See the dispatcher" is not a citation.
- **Placeholder claims.** `POST /endpoint (coming soon)` is a fabricated
  endpoint with a disclaimer attached; readers keep the endpoint and drop the
  disclaimer.
- **One-time verification.** Remediation changes claims. Re-run.

## In this pipeline

- The check belongs to the documentation work order under
  `{{WORKORDERS_DIR}}`; its report is the verification artifact for that work
  order, alongside the executed reference check.
- Template: `{{PIPELINE_ROOT}}/core/templates/docs/factuality-report.md`.
- The shared rule is `core/rules/common/documentation.md`.
- `factuality-validator` owns this check and is never the document's author;
  `repo-analyst` supplies the source-reference index it verifies against;
  `critical-reviewer` handles the claims that are true but overstated.
- Close with evidence: `wo verify <n> --run <suite>` over the reference-check
  script. A PASS typed by hand is exactly what this skill exists to prevent.
- Command: `/review-docs` runs this after the critical review.
