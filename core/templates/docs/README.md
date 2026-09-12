# Documentation Templates

Templates for the knowledge-extraction and documentation side of the pipeline:
analysis of a codebase, and every document generated from that analysis.

Each one ships with the YAML frontmatter the
[`doc-lifecycle`](../../skills/doc-lifecycle/SKILL.md) skill requires, and
carries HTML-comment writing prompts inside its sections. **The prompts are
instructions, not content — delete each one as you fill its section.** Nothing
in these files is a claim: no example endpoints, no sample payloads, no
illustrative status badges. A template that shipped a plausible-looking
endpoint would eventually ship it into a published document.

---

## Template → skill → command

| Template | Produced by | Skill |
|---|---|---|
| `repo-analysis.md` | `/analyze-repo` | `repo-analysis` |
| `source-references.md` | `/analyze-repo` | `repo-analysis` |
| `feature-profile.md` | `/analyze-repo` (phase 7) | `feature-profile` |
| `feature-status-matrix.md` | `/status-matrix` | `status-matrix` |
| `faq-domain.md` | `/docs-faq` | `faq-package` |
| `faq-index.md` | `/docs-faq` | `faq-package` |
| `critical-review.md` | `/review-docs` | `critical-review` |
| `factuality-report.md` | `/review-docs` | `factuality-check` |
| `product-brief.md` | `/docs-brief` | `executive-docs` |
| `primer.md` | `/docs-primer` | `executive-docs` |
| `technical-reference.md` | `/docs-reference` | `developer-docs` |
| `developer-quickstart.md` | `/docs-developer` | `developer-docs` |
| `task-guide.md` | `/docs-developer` | `developer-docs` |
| `error-reference.md` | `/docs-developer` | `developer-docs` |
| `placement-manifest.md` | `/docs-developer` | `developer-docs` |
| `integration-playbook.md` | `/integration-kit` | `integration-kit` |
| `pm-integration-brief.md` | `/integration-kit` | `integration-kit` |
| `api-quick-reference.md` | `/integration-kit` | `integration-kit` |
| `integration-decision-matrix.md` | `/integration-kit` | `integration-kit` |
| `feasibility-analysis.md` | `/feasibility` | `feasibility-analysis` |

---

## Order of production

Nothing downstream is written before the analysis that grounds it.

```
/analyze-repo        repo-analysis, source-references, feature-profile
      │
      ├── /status-matrix        feature-status-matrix
      │         │
      │         ├── /docs-faq           faq-domain, faq-index
      │         ├── /integration-kit    playbook, PM brief, quick reference,
      │         │                       decision matrix
      │         ├── /docs-brief         product-brief
      │         └── /docs-primer        primer
      │
      ├── /docs-developer   quickstart, task-guide, error-reference,
      │                     technical-reference, placement-manifest
      └── /feasibility      feasibility-analysis

/review-docs   critical-review, factuality-report   (over any of the above)
```

The status matrix is the reconciliation point: every status claim in every
other document must match a row in it.

---

## Where the output goes

Documents are drafted inside the work-order folder under
`{{WORKORDERS_DIR}}`, and the distribution copy is placed under
`{{DOCS_DIR}}` — for developer documentation, per the placement manifest.

```bash
wo new "<repo> analysis" --area analysis      # analysis artifacts
wo new "<platform> integration kit" --area docs
wo verify <n> --run <suite>                   # executed evidence, then
wo close <n>                                  # refused without it
```

---

## Rules that apply to every template here

1. **Frontmatter before content.** Added at the end it becomes decoration,
   and the `created` date becomes a guess.
2. **Delete the prompts.** An HTML comment left in a published document is a
   note to the author that the reader can read with one keystroke.
3. **No bracketed placeholder survives DRAFT.** Past DRAFT it reads as a real
   claim to everyone who did not write it.
4. **Citations are relative paths.** Absolute host paths mean nothing to
   another reader and fail `bin/sanitize`.
5. **Omit rather than invent.** A section with no evidence behind it is
   deleted, not stubbed. See the empty-shelf rule in the `factuality-check`
   skill.

The shared rule these all serve is `core/rules/common/documentation.md`.
