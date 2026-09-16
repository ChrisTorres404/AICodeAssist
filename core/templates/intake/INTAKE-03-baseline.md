# WO-XXXX: Baseline — the project's own tests have been run once

**Intake step:** 3 of 6
**Suite:** `intake-03-baseline.sh`
**Closes with:** `wo verify <this number> --run <the suite>`, then `wo close <this number>`

---

## Why this step exists

Structure checks pass on a codebase whose tests have been dead for a month. The baseline is
the step that asks whether they pass, runs them once, and records the answer bound to the
tree it ran against. Everything this tool records afterwards is relative to that
measurement. A failing baseline is information, not a block: it is the state the project is
actually in, written down before anyone starts changing it.

## What the suite checks

- A baseline record exists at `results/BASELINE.md` under the configured testing directory.
- It names the tree it was taken against, as a sixteen-character fingerprint.
- That fingerprint equals the current one, computed by
  `{{PIPELINE_ROOT}}/bin/wo fingerprint` from the project root. A baseline taken against a
  different tree describes a project that is no longer here.
- It carries a Result line, so the record says what happened rather than only when it ran.

## When it fails

- **No baseline.** The project's own tests have never been run under this tool. Run
  `acp baseline`. When it cannot find a test command, give it one:
  `acp baseline --command 'npm test'`, or set `BASELINE_COMMAND` in `pipeline.config.sh`.
  Run the environment-free tier first and read it on its own if you can — unit tests and a
  type check depend on nothing outside the repository, while browser suites depend on a
  running service and the state of a store, and one blended number buries the difference.
- **The tree has changed since the baseline was taken.** The measurement describes a tree
  that is not the one on disk. Re-run `acp baseline`. Committing does not change the
  fingerprint; editing inside the tree does.
- **No tree in the record.** It was written by hand or predates this format. Re-run
  `acp baseline`.
- **No Result line.** The same fix: re-run `acp baseline`, which writes the result from the
  command's exit code rather than from anyone's summary.
- **The driver is missing.** If `{{PIPELINE_ROOT}}/bin/wo` is absent, the suite exits 77 and
  nothing is asserted. Re-run the installer.

## What "done" means

The project's own tests have been executed once under this tool, the result is recorded
whether it passed or failed, and the record is bound to the tree on disk right now. From
here, every verification is a statement about a change from a known state.
