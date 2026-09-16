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

Describing a system well is writing, and writing is agent work. Finding out what is in the
tree is not: directories, routes, models, manifests and entry points can be read the same way
twice. So the tool does that part itself. `acp kb scaffold` walks the repository and writes
the survey, one Feature Profile per feature with its structure and its file inventory already
filled in and cited, the status matrix, and the binding. What it leaves behind in every
profile is the part that needs a person or an agent: the narrative sections, still carrying
the writing prompts they shipped with.

## The three levels

A knowledge base has levels the way a work order has sizes. `KNOWLEDGE_LEVEL` in
`pipeline.config.sh` chooses which one this step demands; the default is `lite`.

| Level | What it means | Who does it |
|---|---|---|
| `lite` | A profile exists for every feature, with its module, files, endpoints and models read out of the tree and cited. The narrative sections are unwritten. | The tool, at intake. `acp kb scaffold` produces it in seconds, with no agent run. |
| `standard` | The narrative is written: no more than half the writing prompts the scaffold left are still standing, in sections 1, 2, 3, 5, 6, 7 and 8 of each profile. | An agent or a person. Under Claude Code, `/analyze-repo`. Under any other tool, this work order's prompt carries the same guidance. |
| `full` | Standard, and a second reader has checked each profile against the source: frontmatter `validated: true` with a name in `reviewed-by`. | A reviewer who did not write the profile. |

`lite` is the level a fresh install passes on its own. That is the point of it: a step whose
only route to green ran through a command the tool never started was a step designed to fail.
Raising `KNOWLEDGE_LEVEL` to `standard` or `full` is a decision to require the writing, and it
should be made when there is someone to do it.

## What the suite checks

- **Nothing to describe yet.** If the tree holds no source — a brand new project — the step
  passes and says so. The knowledge base grows as work orders close, and asking for profiles
  of code nobody has written yet asks for fiction.
- The knowledge-base directory exists, at `KNOWLEDGE_DIR` from the configuration or its
  default under the documentation directory.
- It contains `source-index.tsv`, the binding between the description and the files it was
  written from. That file is written by `acp kb bind` — or by `acp kb scaffold`, which binds
  on its way out — not by hand.
- At least one Feature Profile exists under `profiles/`.
- At least one analysis document sits directly in the directory, alongside the index and any
  status matrix. An index and a matrix are a table of contents, not a description.
- `kb.py status --level <the configured level>` runs and its exit code is the verdict: 0 means
  every profile is current against the source it cites and at the level, 1 means some are
  stale, 2 means some are broken, 3 means there is no knowledge base for it to report on, and
  4 means the profiles are current but some fall short of the level.

## When it fails

- **No knowledge base, no profiles, or no analysis document.** Run `acp kb scaffold`. It reads
  the tree and writes all three, deterministically, with no agent run and no network. The
  driver runs it during intake; running it again costs nothing, because a profile whose
  narrative has been written is left exactly as it is.
- **No source-index.tsv.** The documents exist but nothing ties them to the source. Run
  `acp kb bind`.
- **Some profiles are stale.** The source moved under them, which is the normal state of
  things after a few weeks of work. Run `acp kb status` to see which, update those profiles
  against what the code says now, then `acp kb bind`.
- **Some profiles are broken.** They cite source that no longer exists. Run `acp kb status`,
  repair those profiles, then `acp kb bind`.
- **Some profiles are short of the level.** The suite names them. At `standard`, write the
  narrative sections of each named profile — replace the bracketed prompts with the sentences
  the writing prompts above them ask for — then run `acp kb bind`. At `full`, have each named
  profile read against the source by someone who did not write it, then set `validated: true`
  and `reviewed-by: <name>` in its frontmatter.
- **The engine is missing.** If `{{PIPELINE_ROOT}}/core/hooks/kb.py` is not installed, or
  python3 is not on PATH, the suite exits 77 and nothing is asserted. Install what is
  missing and run it again.

## Under any agent

The scaffold is the same command everywhere: `acp kb scaffold`, a python script reading a
directory tree. Nothing about it is tool-specific.

The writing is where the tools differ, and only in shorthand. Under Claude Code,
`/analyze-repo` runs the eight phases of the repository analysis and fills in the narrative
sections the scaffold left. Under Codex, Cursor, or any other tool, this work order's prompt
carries the same repo-analyst guidance, the same phase order, and the same output layout, so
the agent can produce the identical result by reading it. Either way the binding step is the
same command, `acp kb bind`, and the suite judges the result rather than the route taken to
it.

## What "done" means

Every feature in the repository has a profile, every profile cites the source it was written
from, `kb.py status` reports all of them current, and none of them falls short of the level
this project asked for. The suite exits 0 and the work order closes.
