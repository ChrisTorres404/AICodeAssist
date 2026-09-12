---
name: warn-commented-security
enabled: true
event: file
pattern: ^\s*(//|#|/\*)\s*@(UseGuards|Roles|RequirePrivilege|RequireScope|Authorize|Public|login_required|permission_required|requires_auth)\b|^\s*(//|#)\s*(if\s*\(!?\s*(user|session|token|auth)|assert\s+(user|session|request\.user))
action: warn
---
A guard, decorator, or auth check appears to be commented out. Debugging
shortcuts like this have shipped before. Restore it, or if it is genuinely
obsolete, delete it and say why in the commit.
