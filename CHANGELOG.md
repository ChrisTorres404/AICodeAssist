# Changelog

### 1.2.0 — enforcement that does not depend on the agent

A paired trial under Codex showed the fifteen session hooks, ninety-five agents and
one hundred sixty-two skills all inert, while the drivers, the templates and the one
git hook did the work. So the rules now live where every tool can reach them, and
the Claude Code layer is the early warning rather than the enforcement:

- `acp check` runs the rule set over the staged changes, changes since a ref, an
  explicit list of paths, or what a work order has changed since it opened; it
  imports its rule tables from the hook scripts so the two cannot drift
  (`portable-check`). Blocking under every profile: credentials, a modified lint,
  format or strictness configuration, a closeout without an executed pass
- `wo close` and `bug close` run it over the work's own changes, with or without
  git, from a manifest taken at `wo new` (`no-git-lifecycle`)
- install writes a git `pre-commit` hook that runs it on every commit, under any
  agent; an existing hook is left alone, the minimal profile installs none, and
  doctor reports it (`precommit-backstop`). `acp ci github` adds a workflow that
  runs it on every pull request
- standard and large work orders refuse to close without a filled-in review by
  someone who did not implement them; `WO-####-REVIEW.md` is scaffolded at
  `wo new`, and `ACP_SKIP_REVIEW=1` says so out loud (`review-required`)
- the routed specialists are written into the work order's own prompt with the
  path to each definition, so whatever tool does the work reads them; `acp agent`
  and `acp agents --area` reach the catalog from a shell
- install writes `AGENTS.md`, read by Codex, Cursor and most agents, and a short
  `CLAUDE.md` that imports it; a project's own copies are never touched and
  `detect-stack --write` refreshes whichever carries the stack lines
  (`instructions-for-every-tool`)
- `wo new --paths` binds a work order's evidence to part of a monorepo
  (`wo-paths-scope`)
- a project with no git gets the exact command that turns the backstop on, from
  install and from doctor. The work-order tier holds without it

Found by adopting the pipeline into a mature monorepo and migrating its record,
twenty-nine findings; the defects each have a regression evaluation:

- the fingerprint binds to file content whether or not git tracks the file yet, so
  committing between verify and close no longer stales the evidence; the suite that
  ran is bound on its own, so writing the next suite no longer stales the last pass
  (`evidence-binding`)
- exit 77 records `NOT EXECUTED — PRECONDITION FAILED`, never a failure, and the
  count a runner printed is kept beside the verdict and shown by `wo list`
  (`verify-results`)
- `wo adopt` and `bug adopt` bring an existing record in as history with no
  verification; `wo list`, `wo stats` and `bug list` read one definition of state;
  adopted items stay out of cycle-time statistics; a bug's category lives in its
  metadata (`adopt-existing-record`)
- `wo suite --wrap` and `SUITE_COMMAND` keep the runner a project already has
  (`suite-wrap`)
- `wo promote` carries the suites the verification names into the pack and marks
  references that did not travel; `pack lint` reports placeholder pitfalls
  (`pack-carries-evidence`)
- `acp baseline` runs the project's own tests once and records the first
  measurement; doctor asks for it, opens every agent and skill it counts, notices a
  repository with no commits and instructions pointing at a moved workspace; the
  installer names a moved workspace instead of orphaning it and ends with lint
  (`baseline-and-doctor`)
- a credential-shaped test fixture commits with `acp:allow-secret` on its line; the
  hooks skip the pipeline's own vendored source; a commit message may quote a
  work order that does not exist with an `Acp-Allow-Reference` trailer
  (`hook-secret-fixture-pragma`, `hooks-skip-vendored-pipeline`,
  `wo-reference-allow-trailer`)
- verification and closeout templates for UI work, a verification template of the
  bug's own, one results directory for every runner, a type axis in the suite
  manifest, the sanitizer notices internal hostnames, and a fresh install passes
  its own linter (`verification-templates`, `harness-results-path`,
  `manifest-suite-types`, `sanitize-hostname`, `install-lint-clean`)
- the drivers resolve their roots physically, so a project under a symlinked
  path fingerprints the same tree from every entry point

### 1.1.4 — first public release

The 1.1.3 tree, prepared for a public repository:

- the README is written for someone who has never seen the pipeline: the problem,
  what you get, five minutes to a first work order, a day with it, what it will
  not do, and the evidence so far, with the reference material after
- inline references to other projects removed from three skills and agents; the
  notices file is the one place another project is named
- an example key in the release-sanitizer agent's teaching table rewritten so it
  no longer matches a real credential's shape
- release assets: a source archive and the Claude Code plugin, with checksums

### 1.1.3 — the installed project as a test target

Findings from a blind recovery run on a mature codebase and two rounds of
independent review, each with a regression evaluation under `harness/evals/`:

- **Upgrading: re-run `acp install <project>` in each project you maintain.**
  It is the only migration path. It replaces the pipeline's own hooks by their
  `acp:` identity and keeps everything of yours. `acp doctor` only reports; it
  never edits git hooks, so a project installed before this release will not be
  told what it is missing until the installer has run there.
- traceability is enforced by a git `commit-msg` hook as well as the tool hook,
  so a citation of a work order nobody opened is refused whether the message
  came from `-m`, `-F`, stdin or an editor (`commit-msg-traceability`). A
  `commit-msg` hook you already have is left alone; chain the check into it to
  get the same guarantee, as the README shows
- `new-project` initialises the repository before installing, so scaffolded
  projects get the hook; previously there was no repository to wire it into
- an installed copy self-tests honestly: evaluations needing source-repository
  fixtures skip with a reason instead of failing, and two checks that scanned
  directories an install does not ship were scoping their scan wrong
- `acp doctor` opens, verifies and closes a throwaway work order in the layout
  it is pointed at, then removes it. It runs inside the target: doctoring one
  project never writes into another (`fresh-install-day-one`)
- `wo close` and `bug close` refuse a verification document that is still
  mostly the shipped template, measured against the template itself
  (`ALLOW_PLACEHOLDERS=1` when the prompts genuinely do not apply)
- external commands run under a bound that survives a malformed setting, so a
  third-party tool that hangs fails the run instead of holding it open forever
  (`bounded-external-commands`)
- the database-URL rule keys its exemption off the password rather than the
  username, so documentation examples stop reading as critical findings

Found by an adversarial review of the commit above, 23 scenarios against a
frozen build:

- work-order and bug identities are reserved atomically, so simultaneous
  creators no longer all receive the same number, and a number carried by two
  folders is reported rather than resolved by picking one (`concurrent-identity`).
  The same change exposed an older defect: a bug series is a band, not a prefix,
  and matching it as a prefix handed the second bug in a category a number that
  already existed
- verification refuses to record a pass when the source changed while the suite
  ran, marks a run before it starts so an interrupted rerun cannot leave an
  older pass standing, and the Stop hook now reads the authoritative status the
  same way the drivers do (`evidence-integrity`). `ALLOW_TREE_DRIFT=1` is there
  for suites that write into the tree by design
- the git hook is installed where git actually looks: a linked worktree keeps
  its hooks in the shared directory, and `core.hooksPath` moves them again
  (`worktree-hook`). doctor reports a hook that is present but not executable as
  the inactive thing it is
- the traceability hook reads the authored message as written, comment lines
  included, because `--cleanup=verbatim` records them and the hook cannot see
  the command line that chose it
- the minimal profile installs no git hook, and reinstalling it removes one the
  pipeline put there earlier
- a failed install leaves the project intact: the replacement is staged before
  anything is removed, and the project's authored overlays and harness
  configuration are held with the project until the install commits, so a retry
  restores them (`install-failure-recovery`)
- a bounded command is killed with its whole process group, so a timeout no
  longer returns while the work it started carries on

### 1.1.2 — parallel-work fixes

Found by building a four-module app with four agents working simultaneously in
separate worktrees:

- `wo promote` and `bug promote` write one catalog entry file per item under
  `packs/<name>/catalog/`; `pack catalog` assembles `CATALOG.md` from them and
  the generated file is untracked, so concurrent promotions merge cleanly
  (`parallel-promote`). Legacy single-file catalogs migrate on first use.
- scaffolded suites are self-starting: they start the service when nothing is
  listening, resolve the health endpoint afterwards, and stop the whole process
  group on exit, so a suite that passes for its author passes for everyone
  (`suite-self-starting`)
- the documentation hook ignores template placeholder SOURCE paths

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
