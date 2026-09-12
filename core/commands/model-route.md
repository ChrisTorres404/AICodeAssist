---
description: Recommend the model tier for a task from its complexity, risk, and ambiguity. Usage: /model-route "<task>"
---

Task: **$ARGUMENTS**

| Choose | When |
|---|---|
| `haiku` | mechanical, deterministic, low-risk: renames, formatting, generated code, lookups |
| `sonnet` | the default: implementation, refactors, reviews, most bug fixes |
| `opus` | architecture, ambiguous requirements, security-sensitive design, full audits, anything where being wrong is expensive |

Answer with: the recommended tier, confidence, the one reason that decides it, and the fallback if the first attempt fails. Agents already declare their tier in frontmatter; this is for ad-hoc work.
