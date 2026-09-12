---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Dart/Flutter Testing

> This file extends [common/testing.md](../common/testing.md) with Dart and Flutter-specific content.

Worked examples: skill `dart-flutter-testing`.

## Test Framework

- **flutter_test** / **dart:test** — built-in test runner
- **mockito** (with `@GenerateMocks`) or **mocktail** (no codegen) for mocking
- **bloc_test** for BLoC/Cubit unit tests
- **fake_async** for controlling time in unit tests
- **integration_test** for end-to-end device tests

## Test Types

| Type | Tool | Location | When to Write |
|------|------|----------|---------------|
| Unit | `dart:test` | `test/unit/` | All domain logic, state managers, repositories |
| Widget | `flutter_test` | `test/widget/` | All widgets with meaningful behavior |
| Golden | `flutter_test` | `test/golden/` | Design-critical UI components |
| Integration | `integration_test` | `integration_test/` | Critical user flows on real device/emulator |

## Unit Tests: State Managers

### BLoC with `bloc_test`

Build the bloc in `setUp`, close it in `tearDown`, and write one `blocTest` per transition with `build`, `act` and `expect`. Use `seed` to start from an existing state.

### Riverpod with `ProviderContainer`

Create a `ProviderContainer` with the repository provider overridden by a fake, register `addTearDown(container.dispose)`, then read the provider's future.

## Widget Tests

Pump the widget inside its scope (for example `ProviderScope` with overrides, wrapped in `MaterialApp`), `await tester.pump()`, then assert with `find.text` / `find.byType` and matchers such as `findsOneWidget`. Cover the populated state and the empty state.

## Fakes Over Mocks

Prefer hand-written fakes for complex dependencies: implement the repository interface over an in-memory map, expose a settable error field so failure paths can be exercised, and add helpers for seeding data.

## Async Testing

Use `fake_async` for controlling timers and Futures: run the code inside `fakeAsync`, advance with `async.elapse(...)`, and assert the behaviour before and after the delay.

## Golden Tests

Pump the widget and assert with `expectLater(find.byType(...), matchesGoldenFile('goldens/....png'))`.

Run `flutter test --update-goldens` when intentional visual changes are made.

## Test Naming

Use descriptive, behavior-focused names that state the expected outcome and the condition — `returns null when user does not exist`, `throws NotFoundException when id is empty string`, `disables submit button while form is invalid`.

## Test Organization

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   └── data/
│       └── repositories/
├── widget/
│   └── presentation/
│       └── pages/
└── golden/
    └── widgets/

integration_test/
└── flows/
    ├── login_flow_test.dart
    └── checkout_flow_test.dart
```

## Coverage

- Verification evidence is behavioral: the running system was exercised and state was checked. See common/testing.md.
- All state transitions must have tests: loading → success, loading → error, retry
- Run `flutter test --coverage` and inspect `lcov.info` with a coverage reporter
- Coverage failures should block CI when below threshold
