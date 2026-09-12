---
paths:
  - "**/*.ets"
  - "**/*.ts"
  - "**/module.json5"
---
# HarmonyOS / ArkTS Security

> This file extends [common/security.md](../common/security.md) with HarmonyOS-specific security practices.

Worked examples: skill `arkts-patterns`.

## Permission Management

### Declare Permissions in module.json5

All system API calls requiring permissions must be declared.

### Permission Checklist

Before calling system APIs, verify:

- [ ] Permission declared in `module.json5`
- [ ] Permission reason string defined in resources (for user-facing permissions)
- [ ] Runtime permission request implemented for sensitive permissions (camera, location, etc.)
- [ ] Permission check before API call with graceful fallback on denial

### Runtime Permission Request

## Secret Management

- **NEVER** hardcode API keys, tokens, or passwords in `.ets`/`.ts` source files
- Use HarmonyOS Preferences API for non-sensitive configuration
- Use HarmonyOS Keystore for sensitive credentials
- Environment-specific configs should be managed via build profiles

## Input Validation

- Validate all user input before processing
- Sanitize data before displaying in UI to prevent injection
- Validate deep link parameters before navigation

## Network Security

- Always use HTTPS for network requests
- Validate server certificates
- Implement request timeout and retry policies
- Never log sensitive data (tokens, user credentials) in network request/response logs

## Data Storage Security

- Use encrypted preferences for sensitive local data
- Clear sensitive data from memory when no longer needed
- Implement proper data lifecycle management
- Consider data classification (public, internal, confidential) when choosing storage mechanisms

## Dependency Security

- Only use dependencies from trusted sources (official ohpm registry)
- Verify dependency versions in `oh-package.json5`
- Regularly check for known vulnerabilities in third-party libraries
- Pin dependency versions to avoid unexpected updates
