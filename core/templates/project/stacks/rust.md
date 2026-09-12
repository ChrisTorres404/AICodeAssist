## Stack Rules — Rust

- `thiserror` for library errors, `anyhow` only in binaries and tests; no `.unwrap()`/`.expect()` in production paths, propagate with `?`
- Domain error enum per module mapped to responses via `IntoResponse` (or the framework's equivalent); internals never leak
- `#![deny(clippy::all, clippy::pedantic)]` and fix the warnings; `unsafe` only with a `// SAFETY:` justification
- `sqlx` `query!`/`query_as!` macros for compile-time-checked SQL; a shared `Pool`, never a connection per request; migrations with `sqlx migrate`
- `tracing` for structured logs; never `println!` in services
- `&str` in parameters, `String` when ownership transfers; derive `Debug` everywhere, `Clone`/`PartialEq` only when needed
- Unit tests in `#[cfg(test)]`; integration tests in `tests/` against a real database in a container
- `cargo build`, `cargo clippy`, `cargo test` are the verification floor
