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

It also refuses a template that arrives with a result already in it. An acceptance audit found
fifteen rows across the shipped templates that ended in `— PASS`, or in `EXECUTED — PASS`, or that
came with the checkbox already ticked — a pass no run produced. Those rows survive rendering: the
author fills in the document around them, the close gate counts a filled row, and the work order
closes on evidence the template typed for it. Every markdown template under `core/templates` is read
outside its code fences, and a line that ends in a pass, or a `- [x]`, fails this evaluation with
the file and line named. Two things are deliberately left alone: a suite template is a script, and a
script that prints PASS at run time is printing a real result; and `- [X]` in upper case is the
closeout templates' count placeholder — "[X] tests passing", "Coverage: [X]%" — which is a prompt,
not a claim.
