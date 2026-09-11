# Git Workflow

## Commit messages

```
WO-0407: add token-bucket rate limiter

<body: what changed and why, not how>
```

Lead with the work order or bug id. A commit with neither is either tooling,
docs, or a chore, and should say so. A hook reminds you.

## Pull requests

- Summarise the full branch, not the last commit: `git diff <base>...HEAD`.
- Include the verification evidence or link the VERIFICATION document.
- Automated checks green and branch current before requesting review.

## Never

- Commit secrets. Run `bin/sanitize` if unsure.
- Force-push a shared branch.
- Skip hooks with `--no-verify`.
