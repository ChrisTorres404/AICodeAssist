# Project Overlays

Agents placed here are installed alongside `base/` and `roles/` but are **yours**
— `bin/install.sh` replaces `base/` and `roles/` wholesale on every run and
leaves this directory alone.

Put project-specific agent rules here: the schema map your database validator
should check against, the module layout your backend expert should follow, the
design system your UI expert must use.

Two ways to write one:

1. **A new specialist** the base fleet does not cover — write a full agent file.
2. **A narrowing of a base agent** — give it a distinct `name:` in the
   frontmatter (e.g. `acme-postgres-expert`), state that it extends the base
   agent, and carry only the project-specific rules.

`docs/example-overlay.md` shows one.
