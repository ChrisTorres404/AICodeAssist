# Packs

A pack is a domain's accumulated experience: work orders, bugs, behavioral
test suites, architecture, and a catalog of pitfalls. This directory ships
empty. Packs are built from your own verified work:

```bash
pack new my-domain              # scaffold
wo promote 0407                 # add a closed, verified, sanitized work order
bug promote 0021                # same for a defect
pack search "rate limit"        # find precedent
pack index                      # regenerate INDEX.md
```

Run `bin/sanitize packs/<name>` before sharing a pack with anyone.
