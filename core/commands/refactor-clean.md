---
description: Find and safely remove dead code, unused exports and dependencies, and duplicates, verified after every batch. Usage: /refactor-clean [path]
---

Delegate to `refactor-cleaner`. Scope: **$ARGUMENTS**

Detection tools first (knip, depcheck, ts-prune, vulture, deadcode, cargo-udeps as the stack allows), then grep confirms every candidate including string references, then removal in batches by category with the full test suite after each batch and a commit per green batch. Duplicates consolidate into the most complete, best-tested survivor, which must pass every test the losers had. Never during active feature work on the same files or before a release. Report what went, by batch, with the test evidence.
