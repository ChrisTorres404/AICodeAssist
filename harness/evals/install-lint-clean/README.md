# install-lint-clean

Proves a freshly installed project's own `bin/lint` reports zero errors.

The pipeline repository linted clean while the copy a new user actually got did
not: a fresh install reported three errors, because the installer renders the
project-root placeholder into an absolute path, and that path is a home
directory for almost everyone. The first thing a new user was invited to run therefore failed
on the tool's own files. `lint-and-sanitize-clean` could not see it — it lints
the source tree, where the placeholders are still placeholders.

So this evaluation installs into a directory shaped like a home directory
(`Users/dev/...`, which the personal-path rule matches on macOS and Linux
alike) and lints from inside the installed project, which is the only place the
rendered paths exist. It also lints once with PyYAML made unavailable, because
the frontmatter check has two implementations and most machines run the
fallback — that is the path a malformed skill description slipped through.

The last step is the control: a skill with deliberately malformed frontmatter is
dropped into the install, and lint has to fail and name it. Without it, a lint
that had quietly stopped checking anything would pass this evaluation.
