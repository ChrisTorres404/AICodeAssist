## Stack Rules — Java (Spring Boot / JVM services)

- Constructor injection only; no field injection, no static state
- Records for immutable data, sealed interfaces for closed hierarchies, `Optional` for return values never for fields or parameters
- Validation at the boundary with `@Valid` and constraint annotations; controllers stay thin, services own logic, repositories own data access
- Exceptions: a small domain hierarchy mapped once by a `@ControllerAdvice`; never catch-and-log-and-continue
- Every list query is paged; every JPA association is `LAZY` with explicit fetch joins where needed; N+1 is a review finding
- Migrations through Flyway or Liquibase only; the ORM never generates the schema in a shared environment
- Tests: JUnit 5 with Testcontainers for the database; slice tests for controllers; behavioural suites against the running service for verification
- `./mvnw verify` or `./gradlew check` is the verification floor; the build fails on warnings the team has agreed to keep clean
