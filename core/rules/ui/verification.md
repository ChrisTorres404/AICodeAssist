---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/features/**"
  - "**/components/**"
  - "**/pages/**"
  - "**/app/**"
---
# UI Verification

After creating or changing UI files, before telling anyone it is complete:

```bash
npx tsc --noEmit        # or the project's type-check command
npm run lint            # or the project's lint command
```

In a multi-package repository, run both from the package that owns the
changed files, not from the repository root — a root-level check can pass
while the app's own configuration rejects the same code.

Errors are fixed before reporting, not reported as caveats. Import errors
especially: a broken import is not a caveat, it is unfinished work.

Then the `frontend-validator-expert` checks: directory placement, line
limits, import paths, duplication, `any` in props, work-order headers.
UI work is not done until it passes.

Behavioral verification for UI means the page was opened and the flow was
exercised, with a screenshot or a scenario result recorded in the work
order's VERIFICATION document. A type check is not evidence that a screen
works.
