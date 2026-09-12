---
description: Scaffold a project-specific agent overlay that survives reinstalls — narrowed to this codebase, with a dispatch signal in its description. Usage: /new-agent "<name>" for <target>
---

Args: **$ARGUMENTS** — the agent's name and what it is responsible for.

Read `{{PIPELINE_ROOT}}/core/agents/overlays/README.md` for the two overlay shapes and
`docs/example-overlay.md` for a worked one. An overlay is either a specialist the base fleet
does not cover, or a narrowing of a base agent that carries only this project's rules.

1. Decide which shape applies. If a base agent already covers the domain, narrow it: give the
   overlay a distinct name, state that it extends the base agent, and carry nothing the base
   agent already says.
2. Gather the project facts the agent will be trusted on — `code-explorer` traces the module
   layout, conventions, and the mistakes a guessing agent would make here. Verify each one
   against the codebase; an overlay that asserts something false is worse than no overlay.
3. Write `{{PIPELINE_ROOT}}/core/agents/overlays/<name>.md` with frontmatter `name` matching
   the filename, `model`, and a `description` that is a **dispatch signal**: what it does and
   when to use it. Claude Code selects on the description alone — no triggers, no file globs.
4. Body: what it extends, the facts agents get wrong by guessing, the conventions it enforces,
   what it must verify before writing, and the anti-patterns seen in this codebase.
5. `documentation-expert` reviews placement and shape; then run `{{PIPELINE_ROOT}}/bin/lint`,
   which checks the frontmatter, the name-to-filename match, the model, and the dispatch signal.
6. Remind the user: `install.sh` installs overlays into `.claude/agents` alongside the base
   fleet, and it replaces the base fleet on every run while leaving `overlays/` alone. This
   file is theirs and it survives.
7. Report the path, the shape chosen, and the facts the overlay asserts, each with where it
   was verified.
