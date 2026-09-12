---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart/Flutter Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Dart, Flutter, and common ecosystem-specific content.

Worked examples: skill `dart-flutter-patterns`.

## Repository Pattern

Declare an `abstract interface class` repository exposing `getById`, `getAll`, `watchAll`, `save` and `delete`. The implementation takes a remote and a local data source, reads through the local cache first, writes remote results back to it, and serves streams from the local source.

## State Management: BLoC/Cubit

- Cubit for simple state transitions — call `emit` directly from methods
- BLoC for event-driven state — model events as a `sealed` class hierarchy, register one `on<Event>` handler per event, and produce new state with `copyWith`
- Mark event and state classes `@immutable`

## State Management: Riverpod

- `@riverpod` functions for derived/async reads; `ref.watch` dependencies
- `@riverpod` Notifier classes for mutable state — `build()` returns the initial value and mutations reassign `state`
- Widgets read providers through `ConsumerWidget.build(context, ref)`

## Dependency Injection

Constructor injection is preferred. Use `get_it` or Riverpod providers at composition root: register singletons for clients and repositories and factories for view models in one setup file.

## ViewModel Pattern (without BLoC/Riverpod)

Extend `ChangeNotifier`, hold an `AsyncState<T>` field, and `notifyListeners()` on each transition (loading, then success or failure). Catch `Exception`, not `Error`.

## UseCase Pattern

One class per use case with a `call` method delegating to the repository. Inject collaborators such as an `IdGenerator` — the domain layer must not depend on the `uuid` package directly. Validate and apply business rules before persisting.

## Immutable State with freezed

Declare state with `@freezed` and a `const factory`, using `@Default(...)` for defaults and nullable fields for optional values such as `errorMessage`.

## Clean Architecture Layer Boundaries

```
lib/
├── domain/              # Pure Dart — no Flutter, no external packages
│   ├── entities/
│   ├── repositories/    # Abstract interfaces
│   └── usecases/
├── data/                # Implements domain interfaces
│   ├── datasources/
│   ├── models/          # DTOs with fromJson/toJson
│   └── repositories/
└── presentation/        # Flutter widgets + state management
    ├── pages/
    ├── widgets/
    └── providers/ (or blocs/ or viewmodels/)
```

- Domain must not import `package:flutter` or any data-layer package
- Data layer maps DTOs to domain entities at repository boundaries
- Presentation calls use cases, not repositories directly

## Navigation (GoRouter)

Declare routes with `GoRoute` builders, read path parameters from `state.pathParameters`, and guard authentication in `redirect`. Pass `refreshListenable` so the redirect is re-evaluated whenever auth state changes.

## References

See skill: `flutter-dart-code-review` for the comprehensive review checklist.
See skill: `compose-multiplatform-patterns` for Kotlin Multiplatform/Flutter interop patterns.
