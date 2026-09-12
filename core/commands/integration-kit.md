---
description: The four integration documents — playbook, capability brief, API quick-reference, decision matrix — through the four-phase pipeline, with the anti-hallucination gate. Usage: /integration-kit [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `integration-kit` skill. Requires completed Feature Profiles; a `/status-matrix` is
what the readiness badges are drawn from.

1. Open or reuse the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> integration kit" --area docs`.
2. **Phase 1 — surface extraction.** `repo-analyst` pulls the externally consumable surface out
   of the analysis: endpoints, client methods, authentication mechanisms, configuration items.
3. **Phase 2 — use-case mapping.** Regroup that surface by what a consuming team wants to
   accomplish, never by the internal module layout. Score each use case Simple, Moderate, or
   Complex, and attach its readiness badge from the status matrix.
4. **Phase 3 — generation** from `{{PIPELINE_ROOT}}/core/templates/docs/`:
   the **playbook** (step-by-step, for engineers), the **capability brief** (plain language and
   effort, for product owners, with copy-ready summaries), the **API quick-reference**
   (organised by use case), and the **decision matrix** ("I need X, here is the path").
   `api-reference-writer` owns the quick-reference; `product-strategist` owns the brief.
5. **Phase 4 — the gate.** `factuality-validator` confirms every endpoint, request and response
   shape, client method, and configuration item against source; `critical-reviewer` cross-checks
   every badge and every "supports X" claim beyond the existence of a file, and downgrades
   absolute language. Either one can hold the kit in DRAFT.
6. **Empty shelf:** a capability without enough implementation is omitted from the playbook
   entirely, appears in the decision matrix with its honest badge, and appears in the brief
   under what is coming — never as an instruction with a caveat attached.
7. Every claim carries a `<!-- SOURCE: path:L12 -->` comment. This is the highest-risk output in
   the set: a fabricated endpoint costs a reader days.
8. Report the use cases covered, the complexity spread, and every capability the empty-shelf
   rule removed.
