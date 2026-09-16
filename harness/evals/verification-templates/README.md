# verification-templates

The verification and closeout templates fit what is being verified, and stay countable by the gates.

There was one verification template, written for work orders. A bug rendered from it opened with
"**Work Order:** BUG-0019" and asked six times for a requirement from a spec that a bug does not
have. The same template, and the closeout beside it, assumed a backend: HTTP 200, a database record,
schema changes, a coverage percentage — so a UI work order closing on browser evidence had nothing
to fill in, and the unfilled prompts then tripped the placeholder gate.

There are now three: a bug verification whose claims are reproduction before the fix, no
reproduction after, and a regression check that fails if it returns; and a UI verification and
closeout whose evidence is what rendered — element visible, text matches, route reached, keyboard
reachable, contrast, no console errors, screenshot kept — with deliverables counted as components,
pages, state and styles.

This checks each one exists, carries no wording from the shape it was cut away from, leaves the
Execution Record and the Overall status line to the drivers, and keeps its prompt count within ten
of the template it stands in for, so the close gate's budget still means the same thing. It also
checks the shared template says how its traceability was obtained: recorded per-check lines when the
suite emits them, traced from the suite's source when it does not.
