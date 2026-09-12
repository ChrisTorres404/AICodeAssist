---
paths:
  - "**/*.java"
---
# Java Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Java-specific content.

Worked examples: skill `java-coding-standards`.

## Repository Pattern

Encapsulate data access behind an interface:

```java
public interface OrderRepository {
    Optional<Order> findById(Long id);
    List<Order> findAll();
    Order save(Order order);
    void deleteById(Long id);
}
```

Concrete implementations handle storage details (JPA, JDBC, in-memory for tests).

## Service Layer

Business logic in service classes; keep controllers and repositories thin.

## Constructor Injection

Always use constructor injection — never field injection.

## DTO Mapping

Use records for DTOs. Map at service/controller boundaries.

## Builder Pattern

Use for objects with many optional parameters.

## Sealed Types for Domain Models

## API Response Envelope

Consistent API responses.

## References

See skill: `springboot-patterns` for Spring Boot architecture patterns.
See skill: `quarkus-patterns` for Quarkus architecture patterns with REST, Panache, and messaging.
See skill: `jpa-patterns` for entity design and query optimization.
