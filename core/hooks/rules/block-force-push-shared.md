---
name: block-force-push-shared
enabled: true
event: bash
pattern: git push\b.*(--force|-f\b).*\b(main|master|develop|production)\b
action: block
---
Force-pushing a shared branch rewrites history for everyone on it. Use a
feature branch, or `--force-with-lease` on a branch only you touch.
