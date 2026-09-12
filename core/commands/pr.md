---
description: Create a pull request from the current branch — validates, discovers the template, summarises every commit, links the work order and its verification evidence, pushes. Usage: /pr [base-branch] [--draft]
---

Args: **$ARGUMENTS** (base defaults to `main`; `--draft` allowed)

1. **Validate**: on a feature branch, clean tree, commits ahead of the base, no existing PR for this branch. Stop with the reason otherwise.
2. **Discover**: the repository's PR template if one exists; the work order(s) referenced in the branch's commits; their VERIFICATION documents.
3. **Summarise** from the full range (`git log <base>..HEAD`, `git diff <base>...HEAD --stat`), not the last commit: what changed, why, by area; migrations and config changes called out.
4. **Evidence**: the PR body links each work order and quotes the verification status exactly as recorded (`EXECUTED — PASS` with the log path). If a work order has no executed verification, say so; do not imply it.
5. **Push** with `-u` and create with `gh pr create`; return the URL. If the work order is published as an issue, reference it so GitHub links them.
