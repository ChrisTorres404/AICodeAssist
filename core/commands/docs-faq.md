---
description: FAQ package — domains discovered from the analysis, ten questions each, seven-part answers, mandatory critical review, status matrix, and a master index. Usage: /docs-faq [repo]
---

Target: **$ARGUMENTS** (default: the repository of the most recent `/analyze-repo`)

Load the `faq-package` skill. Requires completed Feature Profiles.

1. Open or reuse the work order: `{{PIPELINE_ROOT}}/bin/wo new "<repo> FAQ" --area docs`.
2. **Discover the domains**, never reuse them: cluster the feature inventory by function into
   ten to twenty capability domains. Fewer than three features is a merge; more than twenty
   domains is a consolidation.
3. **Design ten questions per domain** — the questions an integrating team lead, a security
   architect, or a compliance reviewer would actually ask. Cover architecture, capabilities,
   edge cases, integration, and gaps. A yes-or-no question wastes one of the ten.
4. **Answer in seven parts**: status badge, technical answer, code reference, integration
   guidance, plain-language summary, gap analysis where the badge is not IMPLEMENTED, and
   cross-references. `repo-analyst` grounds each answer; `documentation-expert` writes it.
5. **Critical review is mandatory**, not optional: `critical-reviewer` hunts contradictions
   between answers, over-claim language, and any badge the source does not support, then the
   findings are remediated before the package moves out of DRAFT.
6. Run `/status-matrix` if one does not exist, and reconcile every badge in every answer to it.
7. Build the master index: domains, question ranges, and the roll-up of badges per domain.
8. Report the domain count, the question count, the badge distribution, and the contradictions
   the review caught — that list is the most useful part of the package.
