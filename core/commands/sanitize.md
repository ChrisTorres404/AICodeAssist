---
description: Verify a directory is safe to share — secrets, PII, internal infrastructure, host paths, dangerous files. Usage: /sanitize <dir>
---

Target: **$ARGUMENTS** (default: the current project)

Delegate to the `release-sanitizer` agent. It runs
`{{PIPELINE_ROOT}}/bin/sanitize <dir> --report SANITIZATION-REPORT.md`, judges
each critical category, looks for what the scanner cannot see (customer names,
screenshots, git history), and appends a reviewer verdict to the report.

Report the verdict and point at the report. Never paste secrets, even
truncated, into the conversation beyond the first four characters.
