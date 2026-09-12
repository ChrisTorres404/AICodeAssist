---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Kotlin Testing

> This file extends [common/testing.md](../common/testing.md) with Kotlin and Android/KMP-specific content.

Worked examples: skill `kotlin-testing`.

## Test Framework

- **kotlin.test** for multiplatform (KMP) — `@Test`, `assertEquals`, `assertTrue`
- **JUnit 4/5** for Android-specific tests
- **Turbine** for testing Flows and StateFlow
- **kotlinx-coroutines-test** for coroutine testing (`runTest`, `TestDispatcher`)

## ViewModel Testing with Turbine

## Fakes Over Mocks

Prefer hand-written fakes over mocking frameworks.

## Coroutine Testing

Use `runTest` — it auto-advances virtual time and provides `TestScope`.

## Ktor MockEngine

## Room/SQLDelight Testing

- Room: Use `Room.inMemoryDatabaseBuilder()` for in-memory testing
- SQLDelight: Use `JdbcSqliteDriver(JdbcSqliteDriver.IN_MEMORY)` for JVM tests

## Test Naming

Use backtick-quoted descriptive names.

## Test Organization

```
src/
├── commonTest/kotlin/     # Shared tests (ViewModel, UseCase, Repository)
├── androidUnitTest/kotlin/ # Android unit tests (JUnit)
├── androidInstrumentedTest/kotlin/  # Instrumented tests (Room, UI)
└── iosTest/kotlin/        # iOS-specific tests
```

Minimum test coverage: ViewModel + UseCase for every feature.
