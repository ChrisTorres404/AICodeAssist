# stack-fixtures

Proves every supported stack installs the right rules, stack profile, and commands.

One minimal fixture project per stack — marker files and a single source file,
no toolchain — is installed into with `bin/install.sh`. For each, the evaluation
asserts:

* the rule sets under `.claude/rules` are exactly the ones the stack needs
* the `## Stack Rules — …` section from `core/templates/project/stacks/` is in
  `CLAUDE.md` when a profile exists for that stack, and absent when none does
* the `- **Stack:**` line names the language, the framework, and the package manager
* `detect-stack --json` emits the expected `run` and `test` commands, or nothing
  when nothing can be known from the markers alone
* `acp doctor` reports no FAIL

The expectations are the behaviour of the current tree: this evaluation locks in
what works so a change to `detect-stack`, the rule sets, the stack profiles, or
the installer cannot regress it silently.

Where detection falls short of what the markers make knowable, the evaluation
prints a `KNOWN GAP` line and does not fail. Those lines are the to-do list for
`bin/detect-stack`; each one should disappear, and its expectation tighten, when
detection is fixed.
