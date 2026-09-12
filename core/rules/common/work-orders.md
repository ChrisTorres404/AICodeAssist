# Work Orders

Every non-trivial change is a work order: a folder under the project's
work-order directory, created with `wo new`, never a loose file.

- Fill in the SPEC before writing code. A spec written afterwards is a
  description, not a specification.
- Search the packs first: `pack search "<problem>"`. Precedent beats a blank page.
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
