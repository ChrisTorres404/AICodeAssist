# kb-freshness

Proves a knowledge base's freshness is measured against source, never assumed.

A Feature Profile describing a login flow reads exactly the same whether the flow still
works that way or was rewritten last month, so documentation drifts silently and the
drift is discovered by a reader who acts on a false claim. `kb.py` removes the guess:
`bind` records a content hash for every file a profile cites through its
`<!-- SOURCE: path:L12 -->` comments, and `status` re-hashes them.

This evaluation builds a project with four source files and two profiles, then moves the
source underneath them. It asserts that before `bind` every profile reads as stale and
says it was never bound; that `bind` writes `source-index.tsv` and nothing else, with
relative paths, a row per cited file and a `bound_tree` in the header; that editing one
cited file makes exactly the profile citing it stale (exit 1) while the other stays
current; that `impact` names that profile for a changed file and lists an undescribed
file as uncovered; that a deleted cited file and a citation past the end of a file are
broken (exit 2), broken outranking stale; that a citation with no line number only checks
existence; that re-binding makes a stale profile current again; that the source file no
profile cites is reported under its directory; that `--json` carries the same counts;
that a missing knowledge base exits 3 without creating anything; and that two binds of
one tree produce identical bytes.

The guard: a freshness report that cannot go stale is decoration. With the hash
comparison removed, an edited file leaves its profile reading "current" and this
evaluation fails at the edit assertion.
