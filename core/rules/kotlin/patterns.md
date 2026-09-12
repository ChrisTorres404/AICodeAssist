---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Kotlin Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Kotlin and Android/KMP-specific content.

Worked examples: skill `kotlin-patterns`.

## Dependency Injection

Prefer constructor injection. Use Koin (KMP) or Hilt (Android-only).

## ViewModel Pattern

Single state object, event sink, one-way data flow.

## Repository Pattern

- `suspend` functions return `Result<T>` or custom error type
- `Flow` for reactive streams
- Coordinate local + remote data sources

```kotlin
interface ItemRepository {
    suspend fun getById(id: String): Result<Item>
    suspend fun getAll(): Result<List<Item>>
    fun observeAll(): Flow<List<Item>>
}
```

## UseCase Pattern

Single responsibility, `operator fun invoke`.

## expect/actual (KMP)

Use for platform-specific implementations.

## Coroutine Patterns

- Use `viewModelScope` in ViewModels, `coroutineScope` for structured child work
- Use `stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), initialValue)` for StateFlow from cold Flows
- Use `supervisorScope` when child failures should be independent

## Builder Pattern with DSL

## References

See skill: `kotlin-coroutines-flows` for detailed coroutine patterns.
See skill: `android-clean-architecture` for module and layer patterns.
