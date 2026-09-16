# adopt-existing-record

Checks that an existing engineering record can be brought in as history, and is never mistaken for evidence.

A project older than a week arrives with work orders and bugs already written. `wo adopt` and
`bug adopt` keep the document and the number, write no verification, and record a state that is
neither open nor closed. The three commands that report state read the same definition, adopted
items stay out of cycle-time statistics, and a bug's category lives in its metadata rather than in
the number series it happened to land in.
