# AICodePipeline — Instructions for AI Agents

You are working on **the pipeline itself**, not on a project that uses it.
That distinction governs everything below.

---

## The one rule that matters most

`core/` and `harness/` are **templates**. They contain `{{VARIABLE}}`
placeholders that `bin/install.sh` resolves per project.

- **Never hardcode a project name, path, domain, app directory, or database
  name into `core/` or `harness/`.** Use a `{{VARIABLE}}` and declare it in
  `pipeline.config.example.sh` and in the `VARS` array in `bin/install.sh`.
- **Never put a project's own work into this repository.** Packs are built
  by users from their own verified work with `wo promote`; this repository
  ships the machinery and no corpus. Anything under `packs/` here is a
  scaffold, never content.

Before committing any change to `core/` or `harness/`:

```bash
grep -rniE "/Users/|monorepo" core harness bin/dev   # plus the name of any project it came from
```

This must return nothing. (`bin/portability-pass.sh` legitimately contains
those strings — it is the substitution table. Exclude it.)

---

## Rules versus skills versus governance

One rule, one home:

| Layer | Length | Loaded | Holds |
|---|---|---|---|
| `core/rules/common/` | short | always | the rule itself, stated once |
| `core/rules/<language>/` | short | when files match `paths:` | the language-specific form |
| `core/skills/` | long | on demand | how to carry the rule out |
| `core/methodology/` | long | by reference | the reasoning and history |

If a rule is stated in more than one short form, delete the copies. Skills and
governance link to the rule; they do not restate it.

## Hooks

Every hook goes through `core/hooks/run-hook.sh <id> <profiles> <command>`
and gets a stable id (`acp:<event>:<name>`) and a profile list. Never add a
hook straight into `settings.hooks.json` without both. Profiles: `minimal`,
`standard`, `strict`. Environment prefix: `ACP_`.

Prefer a markdown rule in `core/hooks/rules/` over a new script when the
check is a pattern match.

## Before sharing anything

`bin/sanitize <dir>`. A FAIL is a FAIL. Every shipped tree must pass.

## Adding a variable

1. Add it to `pipeline.config.example.sh` with a sensible example value.
2. Add its name to the `VARS` array in `bin/install.sh`.
3. Use `{{NAME}}` in `core/` or `harness/`.
4. Verify: `bin/install.sh <scratch-project> ` reports no unresolved variables.

---

## Verifying a change end to end

The pipeline has a real round-trip test. Use it — do not assume.

```bash
mkdir -p /tmp/pt && cp pipeline.config.example.sh /tmp/pt/pipeline.config.sh
$EDITOR /tmp/pt/pipeline.config.sh          # set PROJECT_ROOT=/tmp/pt
bin/install.sh /tmp/pt
cd /tmp/pt && PATH="/tmp/pt/.aicodepipeline/bin:$PATH" wo new "Round trip" --series 100
bin/build-plugin && claude plugin validate dist/plugin
bin/acp doctor /tmp/pt
```

GitHub commands (`wo publish`, `sync`, `import`) are tested against a mock
`gh` on PATH that logs its arguments. Never test them against a real
repository from this repo.

A change is done when: the install reports **no unresolved variables**, `wo new`
produces the documents its size requires, `wo close` still refuses without a
verification document, the hooks still pass their stdin tests, and the plugin
still validates.

---

## Search the packs before specifying anything

`packs/` holds accumulated engineering experience. Before writing a new spec —
in this repo or any project the pipeline is installed into — run
`bin/pack search <term>`. If a work order already covers the problem, start from
it. Most of the hard thinking, including the mistakes, is already recorded.

## Keep enforcement mechanical

The point of this repo is that rules are enforced by machinery, not by asking
a model to remember them:

| Rule | Mechanism | Do not weaken |
|---|---|---|
| No closeout without verification | `bin/wo close`, `bin/bug close` | The guard is the only thing making evidence non-optional |
| No debug logging or stubs in source | `core/hooks/quality-gate.py` | Add patterns; do not remove the hook |
| Commits trace to a work order | `core/hooks/wo-reference.py` | Advisory by design — keep it non-blocking |
| Methodology is read when relevant | `core/skills/` | A skill that never triggers is a document nobody reads |

If you find yourself adding a rule as prose in a governance document, ask
first whether it can be a hook, a driver guard, or a skill instead.

---

## The methodology applies to this repo too

`core/methodology/` is not decoration. When changing the pipeline:

- No placeholder implementations, no `TODO: later`, no code referencing files
  that do not exist.
- Do not report a test as passing without having run it and seen the output.
- Read every changed file line by line before declaring work complete.

The `wo` and `bug` drivers exist to make two of these rules mechanical rather
than aspirational. Preserve that property: if you relax the closeout guard, you
have removed the only thing enforcing evidence.

---

## Agents

`core/agents/base/` and `roles/` are regenerated by `bin/install.sh` on every
run. Project-specific rules go in `core/agents/overlays/`.

Claude Code selects a subagent from its `description` field alone. It does not
read file patterns, contexts, or trigger lists — an earlier tool did, and the
fleet still carried those sections until `bin/agent-normalize.sh` stripped them.
When adding an agent, put the dispatch signal in `description`: what it does
**and when to use it**. Run `bin/agent-normalize.sh` after editing the fleet;
it is idempotent.

---

## Shell portability

The drivers and installer target **bash on macOS (BSD userland)** and Linux.

- BSD `sed` does not support `\+`, `\?`, or `\|`. Use `[x][x]*` forms.
- `set -euo pipefail` plus a `grep` that matches nothing kills the script.
  Wrap non-matching greps: `{ grep ... || true; }`.
- Run `bash -n` on every script you touch.

---

## Layout

| Path | Templated? | Purpose |
|---|---|---|
| `core/` | yes | methodology, instructions, rules, skills, hooks, templates, agents, commands, workflows |
| `harness/` | yes | behavioral test framework |
| `bin/` | no | `new-project`, `install.sh`, `build-plugin`, `wo`, `bug`, `pack`, `sanitize`, `detect-stack` |
| `packs/` | no | empty scaffold; users fill their own with `wo promote` |
| `docs/` | no | harness guides carried from the origin |

New content is written templated from the start; there is no de-coupling
step to run.
