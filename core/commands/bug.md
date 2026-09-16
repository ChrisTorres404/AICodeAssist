---
description: Open, route, verify, and close a bug through the bug lifecycle. Usage: /bug "<title>" --category <auth|api|database|ui|observability|security|performance|integration|config|docs> | /bug <number> [status|verify|close|promote]
---

Args: **$ARGUMENTS**

**Open** (`/bug "<title>" --category C`): run `{{PIPELINE_ROOT}}/bin/bug new "<title>" --category C`. The category picks the number series and the routing header (investigate → fix → validate roles) written into the issue document. Then follow the `bug-triage` skill: reproduce first, one root cause with evidence, the fix, and the regression test that would have caught it.

**Status** (`/bug <n> status`): `bug status <n>` shows the documents present and the routing.

**Verify** (`/bug <n> verify --run <suite>`): the suite runs and the VERIFICATION document is stamped from its exit code. Never type PASS.

**Close** (`/bug <n> close`): refuses without executed verification. Write the CLOSEOUT's root cause and pitfalls first; they are what `bug promote` carries into the playbook.

**Promote** (`/bug <n> promote`): sanitize-gated; adds the bug and its pitfalls to the playbook catalog so the next project searches it before repeating the mistake.
