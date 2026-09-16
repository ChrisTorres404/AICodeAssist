# Playbooks

A playbook is a closed, verified work order kept for reuse: its spec, the
suite that proved it, and the pitfalls noted at closeout. Alongside the work
orders a playbook holds promoted bugs, behavioral test suites, architecture
notes, and a catalog of pitfalls. This directory ships empty. Playbooks are
built from your own verified work:

```bash
playbook new my-domain              # scaffold
wo promote 0407                     # add a closed, verified, sanitized work order
bug promote 0021                    # same for a defect
playbook search "rate limit"        # find precedent
playbook index                      # regenerate INDEX.md
```

Run `bin/sanitize playbooks/<name>` before sharing a playbook with anyone.

Each playbook keeps one catalog entry per promoted item under `catalog/`, and
`CATALOG.md` is generated from them by `playbook catalog`. That is what lets two
people promote at the same time without a merge conflict.
