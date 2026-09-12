## Stack Rules — Swift (server or app)

- Value types by default; classes only for identity or reference semantics
- `async/await` and actors for concurrency; no completion-handler pyramids in new code; every actor-isolated state documented
- Errors are typed enums thrown and handled at the boundary that can act on them
- Dependency injection through protocols; no singletons reached from inside logic
- SwiftLint clean; warnings are errors in CI
- Tests: XCTest with async tests; snapshot tests for UI; behavioural suites against the running service or app for verification
- `swift build` and `swift test` (or the Xcode scheme's test action) are the verification floor
