---
description: Create, verify, or list workflow checkpoints backed by git and the work order's verification record. Usage: /checkpoint create|verify|list [name]
---

Args: **$ARGUMENTS**

**create `<name>`**: run the project's type-check and the quick behavioural tier; if green, commit (or stash) with `checkpoint: <name>` referencing the current work order, and append `date | name | sha | tests` to `{{SESSIONS_DIR}}/checkpoints.log`.

**verify `<name>`**: compare now against the checkpoint: files added and modified since, tests passing now versus then (re-run the same tier), build state. Report the deltas; if tests regressed, name which.

**list**: every checkpoint with timestamp, sha, and whether the current tree is at, ahead of, or diverged from it.

A checkpoint is only as good as the tests that ran to create it; a checkpoint without executed tests is a bookmark, and the log says so.
