---
description: Understand this codebase and produce a CLAUDE.md agents can act on — stack, commands that were actually run, layout, request path, conventions. Usage: /onboard
---

Load the `project-onboarding` skill and follow it.

Start with `{{PIPELINE_ROOT}}/bin/detect-stack . --json`, then gather what it
cannot see. Every command you record in CLAUDE.md, you ran. If one fails,
record it as failing with the reason, never as working.

If a CLAUDE.md already exists, preserve every project-specific decision in it
and replace only placeholders. Say what you added.
