# WO-XXXX: Knowledge base — the repository has been described

**Intake step:** 6 of 6
**Suite:** `intake-06-knowledge-base.sh`
**Closes with:** `wo verify <this number> --run <the suite>`, then `wo close <this number>`

---

## Why this step exists

An agent that has not read the codebase invents one. The knowledge base is the project
described once, carefully, in documents the next session reads instead of guessing: what the
features are, where each one lives, what the shape of the thing actually is. The part that
keeps it worth reading is the binding — every profile cites the source it was written from,
so when that source moves the profile is marked stale rather than quietly becoming fiction.
A description nobody re-binds decays into confident, wrong context.

## What the suite checks

- The knowledge-base directory exists, at `KNOWLEDGE_DIR` from the configuration or its
  default under the documentation directory.
- It contains `source-index.tsv`, the binding between the description and the files it was
  written from. That file is written by `acp kb bind`, not by hand.
- At least one Feature Profile exists under `profiles/`.
- At least one analysis document sits directly in the directory, alongside the index and any
  status matrix. An index and a matrix are a table of contents, not a description.
- `kb.py status` runs and its exit code is the verdict: 0 means every profile is current
  against the source it cites, 1 means some are stale, 2 means some are broken, and 3 means
  there is no knowledge base for it to report on.

## When it fails

- **No knowledge base, no profiles, or no analysis document.** The repository has not been
  described yet, and the engine says the same thing by exiting 3. Under Claude Code, run
  `/analyze-repo`. Under any other agent, open this work order and follow its prompt. Then
  run `acp kb bind`.
- **No source-index.tsv.** The documents exist but nothing ties them to the source. Run
  `acp kb bind`.
- **Some profiles are stale.** The source moved under them, which is the normal state of
  things after a few weeks of work. Run `acp kb status` to see which, update those profiles
  against what the code says now, then `acp kb bind`.
- **Some profiles are broken.** They cite source that no longer exists. Run `acp kb status`,
  repair those profiles, then `acp kb bind`.
- **The engine is missing.** If `{{PIPELINE_ROOT}}/core/hooks/kb.py` is not installed, or
  python3 is not on PATH, the suite exits 77 and nothing is asserted. Install what is
  missing and run it again.

## Under any agent

Under Claude Code, `/analyze-repo` runs the eight phases of the repository analysis and
writes the whole output layout: the analysis documents, the Feature Profiles under
`profiles/`, and the status matrix. Under Codex, Cursor, or any other tool, nothing is lost
except the shorthand — this work order's prompt carries the same repo-analyst guidance, the
same phase order, and the same output layout, so the agent can produce the identical result
by reading it. Either way the binding step is the same command, `acp kb bind`, and the suite
judges the result rather than the route taken to it.

## What "done" means

The repository is described in documents a new session can read, every profile cites the
source it was written from, and `kb.py status` reports all of them current. The suite exits
0 and the work order closes.
