# WO-XXXX: Instructions — every agent reads the same file

**Intake step:** 2 of 6
**Suite:** `intake-02-instructions.sh`
**Closes with:** `wo verify <this number> --run <the suite>`, then `wo close <this number>`

---

## Why this step exists

The rules only hold if every agent that touches this project is reading them. `AGENTS.md`
is the file Codex, Cursor and most agents read, and `CLAUDE.md` imports it so Claude Code
reads the same thing rather than a second copy that drifted. An instruction file that still
names a layout this project does not use, or that still says to fill in the test command,
is worse than none: it reads as guidance and sends work to the wrong place.

## What the suite checks

- `AGENTS.md` exists at the project root.
- It mentions the work-order directory this project actually configured, read from
  `WORKORDERS_DIR` in `pipeline.config.sh`. If you changed the workspace layout, the
  instructions have to name the layout you changed it to.
- It carries no unresolved template variables — no double-brace names the installer was
  supposed to replace.
- Its Project Specifics section is filled in: no `_(fill in)_`, no `_(the command)_`, no
  "empty project" marker where the stack and the run and test commands belong.
- If `CLAUDE.md` exists, it contains the line `@AGENTS.md`. A project with no `CLAUDE.md`
  passes; a `CLAUDE.md` that does not import `AGENTS.md` does not.

## When it fails

- **AGENTS.md is missing.** The installer writes it and never overwrites an existing one.
  Run `{{PIPELINE_ROOT}}/bin/acp install .` from the project root.
- **AGENTS.md never mentions the configured work-order directory.** The instructions point
  at a layout this project does not use. Re-run `{{PIPELINE_ROOT}}/bin/acp install .`, or
  edit `AGENTS.md` so it names the directory the configuration names.
- **Unresolved template variables remain.** The installer never rendered the file. Re-run
  `{{PIPELINE_ROOT}}/bin/acp install .`.
- **Project Specifics is still a placeholder.** Run
  `{{PIPELINE_ROOT}}/bin/detect-stack . --write`, which fills in the stack and the run,
  test, build and lint commands from what is actually in the repository. On a project with
  no code yet, there is nothing to detect: write the commands in by hand.
- **CLAUDE.md does not import AGENTS.md.** Claude Code and every other agent are reading
  different instructions. Add the single line `@AGENTS.md` to `CLAUDE.md`.

## What "done" means

One set of instructions, in `AGENTS.md`, naming this project's real layout and its real
commands, imported by `CLAUDE.md` if that file exists. The suite exits 0 and the work order
closes.
