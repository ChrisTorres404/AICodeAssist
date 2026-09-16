# Intake

Six small work orders, opened at install, that a project completes before the pipeline counts
it as operational. Each one is a step the rest of the tool assumes has happened: a source
state to bind evidence to, one set of instructions every agent reads, a first measurement,
the existing record brought in honestly, a way to produce evidence, and a description of the
repository bound to the source it describes.

Each step ships two files:

| Step | Specification | Suite |
|---|---|---|
| 1 | `INTAKE-01-source-state.md` | `intake-01-source-state.sh` |
| 2 | `INTAKE-02-instructions.md` | `intake-02-instructions.sh` |
| 3 | `INTAKE-03-baseline.md` | `intake-03-baseline.sh` |
| 4 | `INTAKE-04-record.md` | `intake-04-record.sh` |
| 5 | `INTAKE-05-suites.md` | `intake-05-suites.sh` |
| 6 | `INTAKE-06-knowledge-base.md` | `intake-06-knowledge-base.sh` |

`TEST-TEMPLATE-VERIFICATION-INTAKE.md` is the verification document these work orders use.
The shipped feature-work template asks for requirements traceability, security and
performance tables, and a code-quality review, none of which an intake step has; this one is
two paragraphs and a notes line, and the driver appends the Execution Record beneath it.

## The order

The steps run in the order they are numbered, and the order is the point. Version control
comes first because evidence is bound to a source state. Instructions come next, because
everything after them is done by an agent reading them. The baseline is third: it measures
the project once, bound to the tree, and every later result is relative to it. Then the
existing record, then a way to produce evidence, then the description of the repository,
which is the longest of the six and the one that pays off on every session afterwards.
Nothing stops you doing them out of order; the suites judge state, not sequence.

## Why the specifications are complete

These specifications carry no placeholders, by design. A normal work order's specification is
a form: the person who opens it knows what the feature is, and the template's prompts are
there to make them write it down. An intake step is the same step in every project, so there
is nothing for anyone to fill in. Each document explains what the step is for, lists what its
suite checks, says what each failure means and names the exact command that fixes it, and
says what "done" means. Read it, run the fix, run the suite.

Every suite reads the project's configuration for its paths, prints one line per check in the
shape `  PASS <what>` or `  FAIL <what> — <what to do>`, ends with a `== N passed, M failed`
line the drivers parse, and never writes into the project. Exit 0 means every check passed, 1
that at least one failed, and 77 that the checks could not be attempted at all, which the
driver records as NOT EXECUTED — PRECONDITION FAILED rather than as a failure of the project.

`wo verify <number> --run <the suite>` records the evidence. `wo close` refuses until it
passes. `acp doctor` reports how many of the six are closed with evidence.
