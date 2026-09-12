## Stack Rules — Flutter / Dart

- Widgets small and composed; `const` constructors wherever possible; no logic in `build()`
- State management chosen once (Riverpod, Bloc, or Provider) and used consistently; no `setState` for shared state
- Repositories behind interfaces; models immutable with `freezed` or equivalent
- Errors modelled as sealed results, not exceptions crossing the UI boundary
- `dart analyze` and `flutter test` clean; widget tests for components, integration tests for flows
