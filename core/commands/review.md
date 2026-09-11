---
description: Review a work order's changes across quality, evidence, language, and security, with adversarial verification of every blocking finding. Usage: /review WO-####
---

Target: **$ARGUMENTS**

1. Compute the diff for this work order (`git diff <base>...HEAD` or the
   working tree) and detect the primary language.
2. Run the `wo-review` workflow with `{ diff, wo, language, changedFiles }`.
   It fans out one reviewer per dimension and has two skeptics attempt to
   refute each CRITICAL or HIGH finding.
3. On `CHANGES_REQUESTED`, list the confirmed blocking findings with file and
   line, and stop. Do not draft a closeout.
4. On `APPROVE`, summarize the advisory findings and proceed to `/verify` if
   verification is not yet executed, then `wo close`.

You own the human gate. The workflow reports; it does not close anything.
