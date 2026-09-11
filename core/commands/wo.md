---
description: Work order lifecycle — open, advance, verify, close, promote. Usage: /wo new "<title>" | /wo status <n> | /wo verify <n> | /wo close <n> | /wo promote <n>
---

Load the `work-order` skill and follow it. Then act on: **$ARGUMENTS**

The driver is `{{PIPELINE_ROOT}}/bin/wo`. Use it for every lifecycle step; do
not create work-order files by hand.

- `new "<title>"` — search the packs first (`{{PIPELINE_ROOT}}/bin/pack search`), then
  choose a size honestly and say which: trivial, small, standard, large.
- `verify <n> [--run <suite>]` — the only way a VERIFICATION document should
  come into being. With `--run`, the status is stamped from the exit code.
- `close <n>` — refuses without executed verification. Do not work around it.
- `promote <n>` — after close, when the work is worth carrying forward. Then
  edit the Pitfalls lines in the pack catalog.

If no arguments were given, run `wo list` and report what is in flight.
