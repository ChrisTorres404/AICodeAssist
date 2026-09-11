---
name: block-no-verify
enabled: true
event: bash
pattern: git (commit|push)\b.*--no-verify
action: block
---
`--no-verify` skips the hooks that enforce this project's standards. If a hook
is wrong, fix the hook.
