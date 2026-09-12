# Changelog

### 1.1.1 — round-two audit fixes

Findings from an independent consumer audit of 1.1.0, each with a regression
evaluation under `harness/evals/`:

- release gate validates the real plugin manifest, not only the marketplace one;
  lint rejects frontmatter that is not valid YAML (38 files corrected)
- packaged drivers work from the plugin layout (`plugin-drivers`)
- close and promote read the authoritative latest verification result in both
  drivers; plan-only and PASS-then-FAIL are refused (`promote-latest-status`)
- evidence is bound to the source tree it ran against: closing after the code
  changed requires a re-run (`evidence-freshness`)
- hooks merge by identity: user hooks survive, reinstalls do not duplicate,
  tampered pipeline hooks are restored, minimal removes only pipeline hooks
  (`hooks-merge`)
- reinstalling with a smaller profile removes pipeline-owned skills and
  pack agents the profile does not select; user additions survive
  (`profile-reconcile`)
- hook commands are quoted and relative to the project directory, so paths
  with spaces and moved projects work (`hooks-paths`)
- session orientation lists in-progress and blocked work (`wo list --active`,
  `session-orient-active`)
- the scaffolded suite asserts against the health URL it resolved
  (`suite-health-url`)
- an unknown evaluation name is an error, never "0 passed" (`eval-unknown-name`)
- documented: the documentation hook proves references resolve; the
  factuality validator proves support

## 1.1.0

What the pipeline contains now: the work-order and bug drivers with their
closeout guards, 95 agents, 162 skills plus 9 optional skill packs, 32 slash
commands, 15 hook scripts on three profiles, 23 rule sets chosen by stack
detection, 16 stack profiles, a behavioural test harness and a k6 load harness,
a knowledge-extraction lifecycle for code you did not write, a pack system that
carries verified work forward, a sanitizer, a plugin build, and an evaluation
suite that tests all of it. Everything below changed since 1.0.

### Lifecycle and drivers

- `wo suite <n>` scaffolds a behavioural suite for a work order from the suite
  template, ready to fill in and run.
- `wo verify <n> --run <suite>` executes the suite and writes `EXECUTED — PASS`
  or `EXECUTED — FAIL` from its exit code; logs are kept beside the document,
  without host paths.
- `wo new --area analysis|docs` opens an analysis specification and routes to
  the analysis roles.
- `wo promote` refuses a closeout that still carries template placeholders
  (`--allow-placeholders` overrides) and replaces its catalog entry instead of
  appending a duplicate.
- `wo stats` counts only `EXECUTED — PASS` as evidence and reports closeouts
  whose last run failed.
- `pack search` lists matching catalog entries with their pitfalls first, then
  unique folders; an empty `packs/` exits 0 with an explanation.
- Unpadded work-order numbers accepted everywhere; `--help` on every script.

### Enforcement

- `wo close`, `bug close`, and `wo promote` require `EXECUTED — PASS`.
  Plan-only and failed verifications are refused. Previously this was a
  filename existence check.
- Eight new hooks (7 at 1.0, 15 now): `commit-quality` (blocks staged
  credentials), `config-protection` (blocks weakening a lint or strictness
  config, including sections inside `pyproject.toml`, `setup.cfg`, and
  `package.json`), `post-edit-format`, `post-edit-typecheck`, `doc-file-warning`,
  `design-quality`, `ui-size-check`, `pre-compact`, `doc-claims-check`.
- The quality gate is language-aware (Go, Rust, Java, C#, Ruby, PHP, Python,
  JavaScript) and hooks read `MultiEdit` edits, not just single writes.
- Every hook has a stable `acp:` id and a profile; `ACP_HOOK_PROFILE` and
  `ACP_DISABLED_HOOKS` control them.
- The permission baseline is 77 deliberate allow rules and 21 deny rules,
  replacing a session allowlist that granted `ssh`, `scp`, `dropdb`, and bash.

### Agents and skills

- 95 agents (38 at 1.0): 52 technology specialists and 43 process roles, each
  with responsibilities, templates, a validation checklist, patterns,
  anti-patterns, and common issues. 19 more in opt-in domain packs
  (`identity`, `ml`, `network`, `healthcare`, `gan`).
- 162 skills, from 6 at 1.0: playbooks for testing, verification, API design,
  security review, migrations, deployment, architecture, and per-language and
  per-framework patterns.
- 9 optional skill packs (business-ops, healthcare, marketing, media, ml,
  network, science, supply-chain, web3) selected with `SKILL_PACKS`.
- 32 slash commands, from 8: `/plan`, `/feature-dev`, `/pr`, `/review-pr`,
  `/test-coverage`, `/refactor-clean`, `/checkpoint`, `/prd`, `/learn` and more.
- 23 language rule files condensed to 120 lines or fewer, the worked examples
  moved into companion skills.
- `bin/lint` validates agent frontmatter, skill structure, hook rules, rule
  files, cross-skill links, personal paths, and invisible unicode.

### Knowledge extraction lifecycle

A second lifecycle for understanding and documenting code you did not write,
held to the same evidence discipline as building it.

- `/analyze-repo` runs an eight-phase read-only analysis and produces a Feature
  Profile per feature plus a source-reference index.
- `/status-matrix`, `/docs-brief`, `/docs-primer`, `/docs-reference`,
  `/docs-faq`, `/docs-developer`, `/integration-kit`, `/feasibility`,
  `/review-docs`, and the roles behind them: `repo-analyst`,
  `narrative-curator`, `factuality-validator`, `critical-reviewer`,
  `product-strategist`, `developer-experience-writer`, `api-reference-writer`.
- `core/rules/common/documentation.md`: source or silence, `<!-- SOURCE: -->`
  traceability, status badges, over-claim language, and the rule that the
  validator is never the author. `doc-claims-check` verifies every SOURCE path
  and line number as the document is written.

### Harness

- Configurable authentication, database statistics and preparation from config,
  generic tiers, manifest-driven runners, endpoint-configurable k6 scenarios, a
  parameterised RLS check: nothing presumes the platform it came from. A k6
  import bug that made authenticated load runs pick no user is fixed.
- `bin/eval` runs behavioural evaluations of the pipeline itself and `bin/eval
  live` drives real sessions: ten offline evaluations and four live scenarios.
  `bin/acp test` runs lint, the sanitizer, every evaluation, the plugin build,
  and plugin validation in one command.

### Install and profiles

- `--profile minimal | standard | full` on `install.sh` and `new-project`;
  `bin/detect-stack` chooses the rule sets and fills in the run, test,
  and build commands; `--write` refreshes them once code exists and installs
  the rule sets the code now needs.
- 16 stack profiles (Next.js, NestJS, Remix, Angular, Vue, Svelte, Go, Python, Rust, Java, Kotlin, Swift, C#, PHP, Ruby, Flutter)
  appended to the generated `CLAUDE.md` from what detection found.
- `install.sh` renders every variable in one pass — 41 seconds to 1 — preserves
  `core/agents/overlays/` and `harness/config/` across reinstalls, and records
  the profile. `bin/build-plugin` assembles a plugin from the same sources.

### First-run fixes

Found by installing a clean copy and using it as a first-time developer would.

- `install.sh` refuses to install the installed copy over itself and re-runs
  from the source it recorded; copy failures abort instead of half-installing.
- Verification and bug closeout templates ship no pre-filled PASS rows,
  approvals, or deployment claims — fabricated evidence is the thing this
  pipeline exists to prevent.
- `acp doctor` is profile-aware, understands plugin mode, and checks only the
  pipeline's own template variables.
- The test framework no longer sets `-e` at library scope, works without a TTY,
  and exits non-zero when any test failed. `pipeline.config.sh` resolves its own
  location, so a clone works anywhere.
