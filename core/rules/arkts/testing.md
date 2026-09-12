---
paths:
  - "**/*.ets"
  - "**/*.ts"
  - "**/ohosTest/**"
---
# HarmonyOS / ArkTS Testing

> This file extends [common/testing.md](../common/testing.md) with HarmonyOS-specific testing practices.

Worked examples: skill `arkts-testing`.

## Test Framework

HarmonyOS uses the built-in test framework with `@ohos.test` capabilities:

- **Unit tests**: Located in `src/ohosTest/ets/test/`
- **UI tests**: Use `@ohos.UiTest` for component testing
- **Instrument tests**: Run on device/emulator

## Test Directory Structure

```
module/
  |-- src/
  |   |-- main/ets/          # Production code
  |   |-- ohosTest/ets/      # Test code
  |       |-- test/
  |       |   |-- Ability.test.ets
  |       |   |-- List.test.ets
  |       |-- TestAbility.ets
  |       |-- TestRunner.ets
```

## Running Tests

## Unit Test Example

## UI Test Example

## TDD Workflow for HarmonyOS

Follow the standard TDD cycle adapted for HarmonyOS:

1. **RED**: Write a failing test in `ohosTest/ets/test/`
2. **GREEN**: Implement minimal code in `main/ets/` to pass
3. **REFACTOR**: Clean up while keeping tests green
4. **BUILD**: Run `hvigorw assembleHap` to verify compilation
5. **VERIFY**: Run tests on device/emulator

## Test Coverage Requirements

- Verification evidence is behavioral: the running system was exercised and state was checked. See common/testing.md.
- **Unit tests**: All utility functions, ViewModel logic, data models
- **Integration tests**: API calls, database operations, cross-module interactions
- **E2E / UI tests**: Critical user flows (login, navigation, data submission)
- Test edge cases: empty data, network errors, permission denials

## Testing Best Practices

- Keep tests independent - no shared mutable state between tests
- Mock network calls and system APIs in unit tests
- Use meaningful test names: `should_[expected_behavior]_when_[condition]`
- Test V2 state management reactivity: verify `@Trace` properties trigger UI updates
- Test Navigation flows: verify `NavPathStack` push/pop/replace operations
- Avoid testing framework internals - focus on business logic and user-visible behavior
