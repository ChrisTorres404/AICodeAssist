---
description: Two-gate review of any generated document — factuality first, then critical review — advancing DRAFT to REVIEW to VALIDATED only when both pass, and naming what blocks. Usage: /review-docs <path>
---

Document: **$ARGUMENTS**

Load the `factuality-check`, `critical-review`, and `doc-lifecycle` skills. The reviewer is
never the author: if you wrote this document, delegate both gates and do not adjudicate them.

1. Read the document and its work order, and locate the source-reference index the claims are
   supposed to trace to. No index means the document is not reviewable yet; say so and stop.
2. **Gate one — `factuality-validator`.** Every `<!-- SOURCE: path:L12 -->` comment resolves to a
   file that exists and says what the document claims. Every endpoint, shape, configuration
   item, and capability claim is re-derived from source. Anything unsupported is a blocking
   finding: it is removed or downgraded, never softened in place.
3. **Gate two — `critical-reviewer`.** Contradictions between sections, status badges the code
   does not support, over-claim language (never, always, impossible, guarantees, "there is no
   way"), and claims that rest on a folder existing rather than on an implementation.
4. Advance the status in the frontmatter only on a clean gate: DRAFT to REVIEW when gate one
   passes, REVIEW to VALIDATED when gate two passes. Never skip a step and never advance a
   document with an open blocking finding.
5. On a failure, leave the status where it is and report the findings with a location, the
   claim, what the source actually shows, and the corrected wording.
6. Report the verdict, the status transition that did or did not happen, and the findings
   ranked by severity. Zero findings is a valid outcome; a rubber stamp is not.
