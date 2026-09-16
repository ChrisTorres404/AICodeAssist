# pack-carries-evidence

Checks that a promoted work order carries the suites that produced its evidence, and that a pack's pitfalls are checked.

The tests are what make precedent reusable; a description of a test is not. Every suite the
verification record names travels into the pack, the catalog points at the carried copy, and a
reference to a file that did not travel says so. `pack lint` reports the entries whose pitfalls
are still the placeholder.
