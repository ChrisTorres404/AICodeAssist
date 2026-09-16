# manifest-suite-types

A suite's tier and its type are two different questions, and the manifest answers both.

`suites.manifest` was `tier|file|label`, and its tier vocabulary — essential, core, extended,
security, integration, performance, infrastructure, recent — mixed how central a suite is with what
kind of test it is. A project could not say that a security check is a static one, or that an
essential check runs in a browser, without giving up the tier that decides when it runs.

The format is now `tier|type|file|label` with a free-form type, and `--type` composes with `--tier`
and the modes. A three-field line still reads, with no type; `--type` never selects it, because
nothing says what kind of test it is. This checks both forms in one manifest, that type narrows
across tiers while tier still bounds the run, that the listing shows types and names suite files no
row mentions, and that the report script accepts the canonical runner's flags rather than a
vocabulary of its own.
