# kb-close-impact

Checks that a change to code the knowledge base describes is named at the moments the code changes.

The engine knows which profiles cite which files. `wo close` intersects that with what the work
order changed, names the affected profiles, writes them into the closeout, and refuses under
the strict profile. `acp check` carries the same rule into the pre-commit hook and CI. Doctor
reports the counts. None of it rewrites a profile; it says when one has to be.
