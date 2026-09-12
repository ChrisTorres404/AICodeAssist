---
paths:
  - "**/*.rs"
---
# Rust Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Rust-specific content.

Worked examples: skill `rust-patterns`.

## Repository Pattern with Traits

Encapsulate data access behind a trait: declare `find_by_id`, `find_all`, `save` and `delete` on a `Send + Sync` trait returning `Result<_, StorageError>`.

Concrete implementations handle storage details (Postgres, SQLite, in-memory for tests).

## Service Layer

Business logic in service structs; inject dependencies via constructor. The service owns boxed trait objects (repository, payment gateway) and propagates their errors with `?`.

## Newtype Pattern for Type Safety

Prevent argument mix-ups with distinct wrapper types:

```rust
struct UserId(u64);
struct OrderId(u64);

fn get_order(user: UserId, order: OrderId) -> anyhow::Result<Order> {
    // Can't accidentally swap user and order IDs at call sites
    todo!()
}
```

## Enum State Machines

Model states as enums — make illegal states unrepresentable. Carry per-state data in the variant (attempt count, session id, failure reason) and dispatch with `match`, using guards for threshold cases.

Always match exhaustively — no wildcard `_` for business-critical enums.

## Builder Pattern

Use for structs with many optional parameters: a `builder(...)` constructor takes the required fields and seeds defaults, chained setters take and return `self`, and `build()` produces the final struct.

## Sealed Traits for Extensibility Control

Use a private module to seal a trait, preventing external implementations: declare `Sealed` in a private module, make the public trait require it, and implement `Sealed` only for your own types.

## API Response Envelope

Consistent API responses using a generic enum: a serde-tagged `ApiResponse<T>` with an `Ok { data: T }` variant and an `Error { message: String }` variant.

## References

See skill: `rust-patterns` for comprehensive patterns including ownership, traits, generics, concurrency, and async.
