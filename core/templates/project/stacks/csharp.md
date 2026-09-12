## Stack Rules — C# (.NET services)

- Nullable reference types enabled and clean; warnings as errors
- Minimal APIs or thin controllers; validation at the boundary; services own logic; a single exception-to-ProblemDetails mapping
- `async` all the way down with `CancellationToken` on every public async method; no `.Result` or `.Wait()`
- Records for DTOs; `IOptions<T>` for configuration; no `IConfiguration` reads inside logic
- EF Core: explicit `Include`, `AsNoTracking` for reads, migrations committed and applied by the pipeline, never `EnsureCreated` in shared environments
- Structured logging through `ILogger<T>`; no `Console.WriteLine` in services
- Tests: xUnit with `WebApplicationFactory` for the host and Testcontainers for the database; behavioural suites against the running service for verification
- `dotnet build`, `dotnet format --verify-no-changes`, and `dotnet test` are the verification floor
