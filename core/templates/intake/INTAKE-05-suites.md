# WO-XXXX: Suites — there is a way to produce evidence

**Intake step:** 5 of 6
**Suite:** `intake-05-suites.sh`
**Closes with:** `wo verify <this number> --run <the suite>`, then `wo close <this number>`

---

## Why this step exists

`wo close` refuses without an executed pass, so a project with no way to run anything cannot
close a work order at all. This step asks for one runnable path to evidence. It does not ask
you to rewrite the harness you already have: wrapping the runner the project already uses
keeps the shared context that made it good, and a thin suite that delegates to it and exits
with its code is exactly as much evidence as one written from scratch.

## What the suite checks

- The suite manifest under the configured testing directory has at least one line that is
  not a comment, naming a file that exists and is executable. Both manifest shapes read: the
  four-field form `tier|type|file|label` and the older three-field form `tier|file|label`.
- Or, instead of that, `SUITE_COMMAND` or `BASELINE_COMMAND` is set in `pipeline.config.sh`,
  which makes a wrapped suite the default shape for everything scaffolded afterwards.
- Every registered file that exists is executable. A suite the runner cannot execute is not
  a suite.
- Rows naming a file that does not exist are reported as notes, not failures. The runner
  reports such a row as SKIP and never as a pass.

## When it fails

- **No way to produce evidence.** Nothing executable is registered and no command is
  configured. Wrap what the project already runs:
  `wo suite <number> --wrap '<your test command>'` scaffolds a suite that delegates to it,
  or set `SUITE_COMMAND` in `pipeline.config.sh` so every suite is scaffolded that way.
  Then register it in the manifest as `tier|type|file|label`.
- **A registered suite is not executable.** Run `chmod +x` on the file the failure names.
- **A registered file does not exist.** That is a note, not a failure, but a manifest full
  of rows pointing at nothing is a manifest nobody trusts. Fix the path or delete the row.

Whatever you wrap, make it establish its own preconditions and exit 77 when they are not
met. A suite whose environment never came up has asserted nothing, and 77 is recorded as
NOT EXECUTED — PRECONDITION FAILED rather than as a failure of the code.

## What "done" means

At least one executable suite is registered, or the configuration names the command every
new suite will wrap. A work order opened tomorrow can be verified today's way, without
anyone inventing a harness first.
