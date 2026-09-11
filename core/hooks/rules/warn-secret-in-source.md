---
name: warn-secret-in-source
enabled: true
event: file
pattern: (api[_-]?key|secret|password|token)\s*[:=]\s*['"][A-Za-z0-9+/=_\-]{16,}['"]
action: warn
---
That looks like a credential being written into source. Move it to the
environment or a secret manager and reference it by name.
