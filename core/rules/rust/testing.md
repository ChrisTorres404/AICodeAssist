---
paths:
  - "**/*.rs"
---
# Rust Testing

> This file extends [common/testing.md](../common/testing.md) with Rust-specific content.

Worked examples: skill `rust-testing`.

## Test Framework

- **`#[test]`** with `#[cfg(test)]` modules for unit tests
- **rstest** for parameterized tests and fixtures
- **proptest** for property-based testing
- **mockall** for trait-based mocking
- **`#[tokio::test]`** for async tests

## Test Organization

Unit tests go inside `#[cfg(test)]` modules in the same file. Integration tests go in `tests/`, where each file is a separate binary, with shared test utilities in `tests/common/`. Criterion benchmarks go in `benches/`.

## Unit Test Pattern

Put unit tests in a `#[cfg(test)] mod tests` block that opens with `use super::*;`. Cover the success case and the rejection case, asserting on the error message for failures.

## Parameterized Tests

Use `#[rstest]` with one `#[case(...)]` per input/expected pair instead of repeating the test body.

## Async Tests

Mark async tests with `#[tokio::test]` and await the operation under test.

## Mocking with mockall

Define traits in production code; generate mocks in test modules. Keep the trait `pub` so integration tests can import it. Set expectations with `.with(...)`, `.times(...)` and `.returning(...)`, then inject the mock into the service under test.

## Test Naming

Use descriptive names that explain the scenario:
- `creates_user_with_valid_email()`
- `rejects_order_when_insufficient_stock()`
- `returns_none_when_not_found()`

## Coverage

- Verification evidence is behavioral: the running system was exercised and state was checked. See common/testing.md.
- Use **cargo-llvm-cov** for coverage reporting
- Focus on business logic — exclude generated code and FFI bindings

## Testing Commands

```bash
cargo test                       # Run all tests
cargo test -- --nocapture        # Show println output
cargo test test_name             # Run tests matching pattern
cargo test --lib                 # Unit tests only
cargo test --test api_test       # Specific integration test (tests/api_test.rs)
cargo test --doc                 # Doc tests only
```

## References

See skill: `rust-testing` for comprehensive testing patterns including property-based testing, fixtures, and benchmarking with Criterion.
