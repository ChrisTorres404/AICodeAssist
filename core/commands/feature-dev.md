---
description: Guided feature development inside a work order — explore the codebase, design, confirm, implement test-first, review, verify, close. Usage: /feature-dev "<feature>"
---

Feature: **$ARGUMENTS**

1. **Open** a work order (`wo new --area <area> --size <size>`) and search the playbooks for precedent.
2. **Explore** with `code-explorer`: trace the existing path this feature touches, name the files, list reusable utilities.
3. **Clarify**: present what you found and ask the design and edge-case questions that change the approach. Wait.
4. **Design** with `architect` (or `code-architect` for a contained change): the blueprint, trade-offs, and an ADR if the decision is architectural. Wait for approval.
5. **Implement** test-first: write the behavioural suite that will verify the feature, then the code, in small commits referencing the work order.
6. **Review** with `code-reviewer`, then the area's validator; fix CRITICAL and HIGH.
7. **Verify**: `wo verify <n> --run <suite>`; the status comes from the run.
8. **Close**: `wo close <n>`, then `wo promote <n>` if it is worth carrying forward, with the pitfalls written.
