# kb-levels

Proves the tool builds the knowledge base itself, and that the levels measure writing.

Before this, intake step six asked for a knowledge base that only an agent run could
produce, and nothing in the tool started that run. On a fresh install the step failed, and
the fix printed under it was an instruction to a human. A step whose only route to green
runs through a command the tool never issues is a step designed to fail.

`kb.py scaffold` removes the impossibility. It reads the tree — feature units under the
conventional roots, route decorators and handler registrations, model directories and entity
files, the package manifest, the entry points — and writes the survey, one Feature Profile
per feature with its module, file inventory, endpoints and models already filled in and cited
to a real file and line, the status matrix, the `level` file, and the binding. No agent, no
network, the same bytes from the same tree. What it does not write is the part worth reading,
and the levels are how the tool says so: `lite` is a profile per feature, `standard` is the
narrative written, `full` is a second reader having checked it against the source.

This evaluation builds a four-feature TypeScript project with a route line, a model file and
a manifest, then:

- scaffolds it and asserts the survey, the four profiles, the matrix with its three badges,
  the level file and the index all exist; that the layout table, the route, the model, the
  dependency and the entry-point scripts were each found; and that **every** citation in
  every document it wrote resolves to a file and a line that are actually there.
- asserts `status` exits 0 at `lite` — the scaffold's own output passes its own check — and
  exits 4 at `standard` naming all four profiles as short, with the count on the summary line.
- writes the narrative of one profile and asserts it drops off the short list while the other
  three stay on it; writes the rest and asserts `standard` reaches 0 while `full` still exits
  4 saying `validated: false`; validates all four and asserts `full` reaches 0.
- edits a cited file and asserts the exit code goes to 1: freshness outranks the level,
  because a stale profile is wrong and an unwritten one is only unwritten.
- re-runs the scaffold and asserts that the profile someone wrote is byte-for-byte untouched,
  that a new feature directory gets a profile, and that a deleted one leaves its profile in
  place marked `status: orphaned` — reported as orphaned rather than broken, so a deliberate
  record does not become a step nobody can pass again.
- asserts `--force` regenerates everything and says so, and that two scaffolds of one tree
  produce identical bytes outside the date lines.
- asserts `scaffold --grow`, the form `wo close` calls, adds the new feature's profile and
  binds only that profile's citations: the rows bound earlier are byte-identical, and the
  profile describing the file that just changed is still stale. A full re-bind there would
  mark it current and lose the finding.
- asserts a tree with no source in it scaffolds to a survey that says so, an empty index and
  exit 0 at every level, while a knowledge base that is genuinely absent still exits 3; and
  that adding the first source file turns that into a real profile which `standard` then
  names as short.

The guard: feature discovery is the whole scaffold. With the grouping broken — every unit
collapsing to the conventional root instead of the directories under it — the run produces
one profile named after `src` instead of four named after the features, and this evaluation
fails at the first assertion, on the count the scaffold prints about itself.
