# Work Orders

Every non-trivial change is a work order: a folder under the project's
work-order directory, created with `wo new`, never a loose file.

- Fill in the SPEC before writing code. A spec written afterwards is a
  description, not a specification.
- Search the playbooks first: `playbook search "<problem>"`. Precedent beats a blank page.
- Reference the work order in every commit message: `WO-0407: add rate limiter`.
- A work order closes only with a VERIFICATION document containing executed
  evidence. `wo close` refuses otherwise. Do not route around it.

Right-size the ceremony with `--size`: `trivial` needs one document and a
verification, `standard` needs the full set. State the size you chose.

Long form: the `work-order` skill.

## Parallel batches

Work orders built at the same time each verify their own module. That proves
nothing about the whole: every suite can pass while a record written by one
module never reaches another. A batch is not finished until an **integration
work order** closes on an executed composition suite.

```bash
wo integrate "<batch name>" --covers 0002,0003,0004,0005
```

It wires every covered suite into one suite and asks for the composition
checks: one entity created in one module, then asserted in every other
module's output. Open it when the batch is planned, not after the merge.

## Active and completed

A work order is either active work or a completed record, and the two are never
mixed. New work orders are created in the active state and stay there while the
work is in progress; a work order becomes a completed record only through
`wo close`, which requires the verification evidence first.

| State | How it is reached | How it is listed |
|---|---|---|
| Open | `wo new` | `wo list --open` |
| In progress | `wo start <number>` | `wo list --active` |
| Blocked | `wo block <number> "<reason>"` | `wo list --active` |
| Closed | `wo close <number>` | `wo list --closed` |
| Migrated | `wo adopt <file.md> --number N --status migrated` | `wo list --closed` |

The folder never moves and the number is never reused, so a work order cited in
a commit, a comment, or a suite still resolves years later. There is no
separate `active/` and `completed/` directory to keep in sync, and no legacy
work-order directory: one directory, one number, a state that the driver
records.

## Folder rules

- One folder per work order, under `{{WORKORDERS_DIR}}`, named
  `WO-XXXX-[Descriptive-Name]/`. Nothing else goes in that directory.
- No loose `.md` file beside the work-order folders. A stray note, plan, or
  summary belongs inside the work order it concerns.
- No parallel or legacy work-order directory. If you find one, say so; do not
  write into it.
- Every document lives inside its work order's folder and is prefixed with the
  work-order number, so the file name still identifies it when quoted alone.
- A `standard` work order carries SPEC, CHECKLIST, TASK-BREAKDOWN, and Prompt
  at open, plus VERIFICATION before close and CLOSEOUT at close. Add
  `sdk-implementation` and `ui-implementation` when the work touches them.
- `wo status <number>` prints which of those exist and which are missing. Use
  it rather than eyeballing the folder.
