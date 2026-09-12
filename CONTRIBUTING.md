# Contributing

You are working on **the pipeline**, not on a project that uses it.
`CLAUDE.md` is the full brief; read it before your first change. This page is
the short version.

## The gate

```bash
bin/acp test
```

Lint, the sanitizer over every shipped directory, every evaluation, the plugin
build, and plugin validation. It must print `ALL CHECKS PASSED` before you
commit. `TESTING.md` explains each check and how to run it alone. After a
change to agents, skills, commands, rules, or templates, also run
`bin/acp test --live` — it drives real Claude Code sessions and costs tokens.

## The rules that catch people out

- **`core/` and `harness/` are templates.** Never hardcode a project name,
  path, domain, app directory, or database name into them. Add a `{{VAR}}`,
  declare it in `pipeline.config.example.sh` and in the `VARS` array in
  `bin/install.sh`, then verify an install reports no unresolved variables.
- **One rule, one home.** The rule itself goes in `core/rules/`; how to carry
  it out goes in `core/skills/`; the reasoning goes in `core/methodology/`.
  If a rule is stated twice in short form, delete the copy.
- **Enforcement is mechanical.** Prefer a hook, a driver guard, or a skill over
  prose in a governance document. Never relax the closeout guard — it is the
  only thing making evidence non-optional.
- **No project's own work in this repository.** `packs/` ships a scaffold and
  no corpus; users fill it with `wo promote`.
- **No third-party references.** Nothing in the tree names another product,
  company, or project. `THIRD-PARTY-NOTICES.md` is the single exception and
  carries only the licence notices the law requires.
- **No personal paths.** No `/Users/<name>/`, no `/home/<name>/`, no internal
  hostnames — in code, docs, templates, or example output. Use `<your-project>`
  and `<project>` placeholders. `bin/lint` and `bin/sanitize` both fail on
  them.
- **Shell portability.** bash 3.2 and BSD userland: no `\+`, `\?`, or `\|` in
  `sed`; wrap greps that may match nothing (`{ grep … || true; }`); run
  `bash -n` on every script you touch.

## Adding things

**An agent** — a markdown file in `core/agents/base/` (technology specialist)
or `core/agents/roles/` (process role). Claude Code selects on the
`description` field alone, so put both what it does and when to use it there.
Run `bin/maintenance/agent-normalize.sh` afterwards; it is idempotent.
Project-specific narrowing belongs in `core/agents/overlays/`, which survives
reinstalls. `bin/install.sh` regenerates `.claude/agents/` on every run.

**A skill** — `core/skills/<name>/SKILL.md` with `name` and `description` in
the frontmatter. Long-form; loaded on demand. A skill that never triggers is a
document nobody reads, so make the description say when it applies. Optional
collections live in `core/skill-packs/<pack>/<skill>/`.

**A hook** — prefer a markdown rule: a file in `core/hooks/rules/` with `name`,
`enabled`, `event`, `pattern`, and `action` (`block` or `warn`) in the
frontmatter and the message below it. No code. When you do need a script, put
it in `core/hooks/` and register it in `core/config/settings.hooks.json`
through `core/hooks/run-hook.sh <id> <profiles> <command>` with a stable
`acp:<event>:<name>` id and a profile list (`minimal`, `standard`, `strict`).
Never wire a hook in without both. Environment variables are prefixed `ACP_`.

**A rule** — a short markdown file in `core/rules/common/` (always loaded) or
`core/rules/<language>/` (loaded when files match its `paths:` frontmatter).
Language files extend the common file of the same name rather than repeating
it. Keep them under 120 lines; the worked examples belong in a skill.

**An evaluation** — `bin/eval new <name>` scaffolds
`harness/evals/<name>/{eval.sh,README.md}`. `eval.sh` gets `PIPELINE_ROOT` and
a scratch `EVAL_TMP`; it installs into a fixture, drives a hook or a driver for
real, and exits non-zero to fail. The README's third line says what it proves —
which failure it guards against. Add one whenever an agent, rule, or hook
change could regress silently. A live scenario is a directory under
`harness/evals/live/` with `prompt.md`, `check.sh`, and an optional `setup.sh`.

## Before you specify anything

`bin/pack search <term>`. Most of the hard thinking, including the mistakes, is
already recorded.

## Commits

One change, one commit, with a message that says what changed and why. Do not
report a test as passing without having run it and seen the output — that rule
applies to this repository first.
