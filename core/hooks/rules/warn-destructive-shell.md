---
name: warn-destructive-shell
enabled: true
event: bash
pattern: \brm\s+-rf?\s+(/|~|\$HOME|\.\.?/?\s*$)|\bmkfs\b|\bdd\s+if=
action: warn
---
This command is destructive and hard to reverse. Confirm the target is exactly
what you intend before running it.
