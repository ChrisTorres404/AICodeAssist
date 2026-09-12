## Stack Rules — Kotlin (Ktor / Spring / Android)

- Immutable by default: `val`, data classes, read-only collections at boundaries
- Coroutines are structured: every launch inside a scope tied to a lifecycle, `withContext(Dispatchers.IO)` at the IO edge only, no `GlobalScope`
- Sealed results for domain errors; exceptions only for the truly exceptional
- Null is a type decision, never an escape hatch: no `!!` outside tests
- Flows for streams; StateFlow for UI state; one source of truth per screen
- Detekt and ktlint clean; the Gradle build fails on their findings
- Tests: kotest or JUnit 5, `runTest` for coroutines, Turbine for flows; behavioural suites against the running service or app for verification
