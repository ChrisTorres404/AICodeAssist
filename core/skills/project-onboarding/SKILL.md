---
name: project-onboarding
description: Understand an unfamiliar codebase and produce a project CLAUDE.md that agents can act on. Use when opening a project for the first time, when the user says onboard me or explain this repo, when CLAUDE.md is missing or has unfilled placeholders, or right after bin/new-project on an existing codebase.
---

# Project Onboarding

The goal is not a tour. It is a `CLAUDE.md` that stops the next agent from
guessing wrong about where things are and how they run.

## 1. Mechanical reconnaissance first

```bash
{{PIPELINE_ROOT}}/bin/detect-stack . --json
```

That gives languages, frameworks, package manager, and the run, test, build,
and lint commands it could prove from manifests. Trust it for what it found.
Then gather what it cannot see, in parallel and without reading every file:

- **Entry points.** `main.*`, `index.*`, `server.*`, `cmd/`, `app/`.
- **Directory purpose.** Top two levels only. Ignore vendored and generated trees.
- **Config and tooling.** Linters, formatters, `Makefile`, `Dockerfile`, compose
  files, CI workflows, `.env.example`.
- **Tests.** Where they live, how they are named, which runner.
- **Git conventions.** Branch names and the last thirty commit subjects. Skip
  this if history is missing or shallow, and say so.

## 2. Map the architecture

Answer these from evidence, not inference:

- Monolith, monorepo, services, or serverless. If a monorepo, list the
  workspaces and what each is.
- Where a request enters, where it is validated, where business logic lives,
  how it reaches storage. Trace one real request end to end and name the files.
- Naming conventions actually in use: file case, test suffixes, error style.

## 3. Write the CLAUDE.md

If one exists, read it first and **preserve** everything project-specific.
Replace placeholders; do not replace decisions. Mark what you added.

Fill the **Project specifics** section:

```markdown
- **Stack:** <languages, frameworks, database, package manager>
- **Run locally:** `<command>`
- **Run tests:** `<command>`
- **Build:** `<command>`
- **Layout:** one line per top-level directory that matters
- **Request path:** entry → validation → logic → storage, with file names
- **Conventions:** file naming, test naming, error handling style
- **Architecture notes:** anything an agent would get wrong by guessing
```

Every command you write down, you ran. A command that fails goes in as
"`<command>` — currently fails: <reason>", never as a working command.

## 4. Seed the work

- Run `{{PIPELINE_ROOT}}/bin/playbook list` and note which playbooks apply.
- If the project has obvious gaps the stack rules flag, open them as
  work orders with `wo new --size small` rather than fixing them silently.

## What good looks like

A fresh session with no memory reads the CLAUDE.md and can start a real task
inside five minutes without asking where anything is.
