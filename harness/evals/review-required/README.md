# review-required

Checks that the specialists routed for a work order reach the agent doing it, and that a review by someone else is not optional.

A role name in metadata is used by nothing. The work order's own prompt now carries each
routed specialist's guidance and the path to the full definition, which every tool can read.
Standard and large work orders refuse to close without a filled-in review in the validator role;
trivial and small ones stay light.
