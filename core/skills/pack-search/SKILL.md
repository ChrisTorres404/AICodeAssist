---
name: pack-search
description: Search accumulated engineering knowledge — prior work orders, bugs, test suites, and architecture — before specifying or building anything. Use when starting any non-trivial feature, investigating a bug, or when the user asks whether something has been done before.
---

# Search the Packs First

A pack is a domain's accumulated experience: work orders, bug investigations,
behavioral test suites, and the architecture behind them, promoted from real
projects with `wo promote` and `bug promote`.

If a pack exists for this domain, most of what you are about to design has a
precedent in it, including the mistakes made the first time.

```bash
{{PIPELINE_ROOT}}/bin/pack packs              # what is installed
{{PIPELINE_ROOT}}/bin/pack search "<term>"    # everything
{{PIPELINE_ROOT}}/bin/pack wo "<term>"        # work orders
{{PIPELINE_ROOT}}/bin/pack bug "<term>"       # bugs
{{PIPELINE_ROOT}}/bin/pack suite "<term>"     # behavioral suites
{{PIPELINE_ROOT}}/bin/pack arch "<term>"      # architecture and schema
{{PIPELINE_ROOT}}/bin/pack show WO-0407       # one item's documents
```

`{{PIPELINE_ROOT}}/packs/INDEX.md` lists every work order and bug with a
lifecycle map: `SCTPVC` = Spec, Checklist, Task-breakdown, Prompt,
Verification, Closeout. A dot is a document never written. `SCTPVC` is a
complete, evidenced piece of work; `SCT...` was abandoned. Both are informative,
but only the first is proof.

## The catalog

Each pack may carry a `CATALOG.md`: one entry per promoted work order with the
problem, the solution, the files touched, and the **pitfalls**. Read the
catalog before the folders; it is the distilled form.

## How to use what you find

Pack content is **origin-specific on purpose** — real service names, schemas,
ports, tenants. That specificity is why it teaches; a sanitised spec teaches
nothing. Read it as precedent:

- Take the **problem decomposition** and the **failure modes**. These transfer.
- Take the **acceptance criteria** and the **test shape**. These usually transfer.
- Do **not** copy paths, table names, or configuration. These do not transfer.

If you find a bug closeout describing a trap, say so explicitly before building.
Avoiding a known pitfall is the single highest-value thing a pack provides.
