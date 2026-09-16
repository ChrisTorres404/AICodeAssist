# harness-results-path

One results directory for everything the harness writes, and a report script that starts.

`run-behavioral-tests.sh` read `SUITES_DIR` two lines before assigning it, so under `set -u` it
died with "SUITES_DIR: unbound variable" before running a single suite. It also wrote to a
`test-results` directory beside the suites, while the installer creates `results` and the drivers
exclude only `results` from the source fingerprint — so every report it wrote invalidated the
evidence the report was about.

This checks that the script runs with nothing preset, that every runner resolves suites, manifest
and results through the one shared `harness/lib/paths.sh`, that a run lands in `results`, that the
`test-results` name appears nowhere, and that the two duplicate runners stay deleted and
unreferenced.
