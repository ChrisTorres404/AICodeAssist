## Stack Rules — Go

- Effective Go and the Code Review Comments are the style guide; `gofmt` and `goimports` are not negotiable
- `ctx context.Context` first parameter, propagated through every layer; goroutines have a cancellation path and a `WaitGroup` or errgroup
- Errors are returned, wrapped with `fmt.Errorf("doing x: %w", err)`, compared with `errors.Is`/`errors.As`; no `_ = err`, no panics for recoverable conditions
- Sentinel errors per domain package; the handler layer maps them to HTTP or gRPC status
- No `init()`, no package-level mutable state; dependencies via constructors
- SQL through parameterised queries or generated code (`sqlc`); migrations in `migrations/` with `golang-migrate`; transactions for multi-step writes
- Table-driven tests; integration tests against a real database in a container
- `go vet`, `staticcheck`, `golangci-lint`, and `go test -race ./...` are the verification floor
