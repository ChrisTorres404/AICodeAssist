# WO-XXXX: Record — the existing history is in, and it is honest

**Intake step:** 4 of 6
**Suite:** `intake-04-record.sh`
**Closes with:** `wo verify <this number> --run <the suite>`, then `wo close <this number>`

---

## Why this step exists

Most projects arrive with a record of work already done: work orders in a folder somewhere,
bugs tracked in documents, a history nobody wants to retype. That record can come in as
history, unchanged, at the numbers it already cites. What it must never come in with is
evidence that was never produced. Historical completion is recorded, not verified, and an
adopted item earns a pass the first time its suite genuinely runs. That single rule is what
makes the rest of the record worth anything.

## What the suite checks

- The inventory exists: `INDEX.md` in the knowledge directory, at the location the
  configuration resolves to rather than a hardcoded path. It is what lists the documents
  this project already carries and where they landed.
- No adopted item carries fabricated evidence. For every work-order and bug folder whose
  metadata records that it was adopted, any verification document claiming
  EXECUTED — PASS must have a run log beside it. A pass with no log was typed, not run.
- One number, one folder. No two folders under the work-order or bug directories share a
  number, in either the padded or the unpadded spelling.

## When it fails

- **No inventory.** Nothing has listed what this project already holds. Run
  `acp intake inventory`, which writes the index the rest of this step reads.
- **An adopted item claims a pass with no log.** Delete the pass line from that
  verification document, or produce real evidence by running the suite:
  `wo verify <number> --run <suite>`. Do not leave it standing. An adopted work order is
  brought in with `wo adopt <file> --number N`, which deliberately writes no verification at
  all; `bug adopt` does the same and takes `--category`, because an adopted number may land
  in a series it does not belong to.
- **Two folders share a number.** The number is the item's identity, and two items with one
  identity make every later reference ambiguous. Rename one with `git mv`, giving it a free
  number and keeping the slug.

## What "done" means

Everything the project already had is either in the record as adopted history or
deliberately left out, the inventory says which, no adopted item claims evidence it cannot
produce, and every number identifies exactly one item.
