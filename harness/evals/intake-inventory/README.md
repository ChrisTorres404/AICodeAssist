# intake-inventory

Checks that a repository which has never heard of this pipeline is classified correctly, and read without being touched.

Projects arrive in different shapes. One already keeps work-order folders; one keeps numbered
documents, a bug series, decision records and a pile of loose markdown; one has nothing but code.
The inventory has to name which of those it is looking at, catalogue every document, and propose
the `wo adopt` and `bug adopt` commands that would bring the record in — with the numbers the
documents already cite and the state their names imply, never a number it invented.

This evaluation builds all three, asserts the shape, the item and bug counts, the titles taken
from each document's own H1, and the exact adoption commands — including `--status open` for an
item whose document says so, `--status fixed` for a bug whose filename does, and no command at all
for loose documentation, which is catalogued and nothing more. It then compares a content listing
of every fixture before and after: the guarantee that makes intake safe to run on someone else's
repository is that it only reads, and that has to be checked rather than asserted in prose.
