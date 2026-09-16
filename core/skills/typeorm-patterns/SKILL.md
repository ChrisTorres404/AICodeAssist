---
name: typeorm-patterns
description: TypeORM + PostgreSQL patterns and troubleshooting — entity definition, the nullable-column metadata trap, service-layer null vs undefined, database and schema setup, and a symptom-to-fix index for the errors that actually block a boot. Use when writing TypeORM entities, repositories, or DataSource config, or when debugging a TypeORM startup, metadata, or type error.
---

# TypeORM Patterns and Troubleshooting

Gotchas, patterns, and lessons learned from building a PostgreSQL-backed API with
TypeORM under `strictNullChecks`. Every entry below came from an error that stopped a
build or a boot, not from documentation.

## When to Activate

- Defining or changing a TypeORM entity, column, or relationship
- Adding a nullable column and deciding between `?` and `| null`
- Writing service-layer code that creates or updates entities with optional fields
- Configuring `TypeOrmModule` / `DataSource`, entity discovery, or `synchronize`
- Setting up a database and schema before first boot
- Debugging `DataTypeNotSupportedError`, `EntityMetadataNotFoundError`,
  `QueryFailedError`, `TS2769`, or `Cannot find module` for an entity
- Reviewing a pull request that touches entities or repositories

## Contents

1. [Error Index](#error-index)
2. [Entity Definition](#1-entity-definition)
3. [TypeScript Configuration](#2-typescript-configuration)
4. [Nullable Columns (Critical)](#3-nullable-columns-critical)
5. [Service Layer Patterns](#4-service-layer-patterns)
6. [Database Setup](#5-database-setup)
7. [Troubleshooting: Symptom, Cause, Fix](#6-troubleshooting-symptom-cause-fix)
8. [Project Structure](#7-project-structure)
9. [Quick Reference Checklist](#8-quick-reference-checklist)
10. [Quick Fixes Cheat Sheet](#quick-fixes-cheat-sheet)
11. [Templates](#templates)

## Error Index

| Error | Jump To |
|-------|---------|
| `Data type "Object" is not supported` | [6.1](#61-data-type-object-not-supported) |
| `Type 'null' is not assignable to type 'undefined'` | [6.2](#62-null-not-assignable-to-undefined) |
| `database "X" does not exist` | [6.3](#63-database-does-not-exist) |
| `relation "X" does not exist` | [6.4](#64-relation-does-not-exist) |
| `No overload matches this call` (repository.create) | [6.5](#65-no-overload-matches-repositorycreate) |
| `Cannot find module` | [6.6](#66-cannot-find-module) |
| `EntityMetadataNotFoundError` | [6.7](#67-entitymetadatanotfounderror) |

## 1. Entity Definition

### What Works

```typescript
// CORRECT: Entity with proper decorators
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Generated,
} from 'typeorm';

@Entity({ schema: 'myschema', name: 'users' })
export class User {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'uuid', unique: true })
  @Generated('uuid')
  uuid: string;

  @Column({ length: 255 })
  email: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
```

### What Doesn't Work

```typescript
// WRONG: Missing type in Column decorator for certain fields
@Column({ length: 500, nullable: true })
imageUrl: string | null;  // TypeORM sees "Object" as the reflected type
```

### Key Rules

1. **Always use `@Generated('uuid')` with UUID columns** - Don't rely on database defaults alone
2. **Specify schema explicitly** - Use `@Entity({ schema: 'schemaname', name: 'tablename' })`
3. **Use snake_case for database columns** - Map with `name: 'column_name'`
4. **Use camelCase for TypeScript properties** - Standard TS convention

### Dual-Id Note

A `@PrimaryGeneratedColumn({ type: 'bigint' })` is returned by the PostgreSQL driver as a
**string**, not a number, regardless of the `id: number` declaration on the entity. Any
`Map`/`Set` keyed by that id, or any `===` comparison against a numeric literal, must
normalize first:

```typescript
// The entity says number; the driver hands you "29".
const key = Number(entity.id);
cache.set(key, value);          // not cache.set(entity.id, value)
```

## 2. TypeScript Configuration

### Required tsconfig.json Settings for TypeORM

```json
{
  "compilerOptions": {
    "emitDecoratorMetadata": true,    // REQUIRED for TypeORM
    "experimentalDecorators": true,   // REQUIRED for TypeORM
    "strictNullChecks": true,         // Recommended but causes issues (see Section 3)
    "target": "ES2021",
    "module": "commonjs",
    "skipLibCheck": true
  }
}
```

### Critical: `emitDecoratorMetadata`

Without this setting, TypeORM cannot reflect property types and will fail with cryptic errors like:

```
DataTypeNotSupportedError: Data type "Object" in "Entity.property" is not supported
```

## 3. Nullable Columns (Critical)

This is the **number one gotcha** when using TypeORM with `strictNullChecks: true`.

### The Problem

When you use TypeScript union types with `null`, the reflected metadata becomes `Object` instead of the actual type:

```typescript
// BROKEN: TypeORM sees "Object" as the type due to | null union
@Column({ length: 500, nullable: true })
imageUrl: string | null;  // Runtime error!
```

### The Solution

Use **optional properties** (`?`) instead of union types with `null`:

```typescript
// CORRECT: Use optional property syntax
@Column({ type: 'varchar', length: 500, nullable: true })
imageUrl?: string;
```

### Comparison Table

| Pattern | Works? | Notes |
|---------|--------|-------|
| `prop: string \| null` | NO | TypeORM sees `Object` |
| `prop?: string` | YES | TypeORM sees `String` |
| `prop: string \| null` with explicit `type` | MAYBE | Inconsistent |
| `prop?: string` with explicit `type` | YES | Most reliable |

### Recommended Pattern for All Nullable Columns

```typescript
// For string columns
@Column({ type: 'varchar', length: 255, nullable: true })
name?: string;

// For text columns
@Column({ type: 'text', nullable: true })
description?: string;

// For number columns
@Column({ type: 'int', nullable: true })
count?: number;

// For bigint foreign keys
@Column({ name: 'related_id', type: 'bigint', nullable: true })
relatedId?: number;

// For decimal columns
@Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
price?: number;

// For date columns
@Column({ name: 'event_date', type: 'timestamptz', nullable: true })
eventDate?: Date;

// For JSONB columns (non-nullable with default)
@Column({ type: 'jsonb', default: {} })
metadata: Record<string, unknown>;

// For JSONB arrays (non-nullable with default)
@Column({ type: 'jsonb', default: [] })
tags: string[];
```

### Relationship Nullable Pattern

```typescript
// Foreign key column
@Column({ name: 'category_id', type: 'bigint', nullable: true })
categoryId?: number;

// Relationship decorator
@ManyToOne(() => Category, { nullable: true })
@JoinColumn({ name: 'category_id' })
category?: Category;
```

### Hydrated Relations Beat Raw Foreign Keys on save()

When an entity is loaded with `relations: ['category']`, TypeORM hydrates the
`category` object. Assigning the raw foreign-key column afterwards is **silently
ignored** by `save()` — the generated UPDATE omits the column entirely, with no error:

```typescript
// BROKEN: entity was loaded with relations: ['category']
entity.categoryId = newCategoryId;
await this.repository.save(entity);   // UPDATE never mentions category_id
```

```typescript
// FIXED: write the column directly
await this.repository
  .createQueryBuilder()
  .update(MyEntity)
  .set({ categoryId: newCategoryId })
  .where('id = :id', { id: entity.id })
  .execute();
```

Either assign the hydrated relation object (`entity.category = category`) or bypass
`save()` with a query builder. Do not mix the two styles on the same entity.

## 4. Service Layer Patterns

### The Problem

After fixing entities to use `?` optional properties, your service code may still use `null`:

```typescript
// BROKEN: Service assigns null but entity expects undefined
const entity = this.repository.create({
  eventDate: dto.eventDate ? new Date(dto.eventDate) : null,  // Type error!
});
```

### The Solution

Use `undefined` instead of `null` in service layer code:

```typescript
// CORRECT: Use undefined for optional properties
const entity = this.repository.create({
  eventDate: dto.eventDate ? new Date(dto.eventDate) : undefined,
});

// CORRECT: For conditional updates
entity.notes = dto.notes || undefined;  // Not: dto.notes || null
```

### Pattern for Repository Create

```typescript
async create(customerId: number, dto: CreateEntityDto): Promise<Entity> {
  const entity = this.repository.create({
    // Required fields
    customerId,
    status: 'pending',
    description: dto.description,

    // Optional fields - use undefined, not null
    eventDate: dto.eventDate ? new Date(dto.eventDate) : undefined,
    eventType: dto.eventType,  // undefined if not provided
    notes: dto.notes,          // undefined if not provided
  });

  return this.repository.save(entity);
}
```

### Pattern for Updates

```typescript
async update(uuid: string, dto: UpdateDto): Promise<Entity> {
  const entity = await this.findByUuid(uuid);

  // Only set if provided, otherwise leave as-is
  if (dto.name !== undefined) {
    entity.name = dto.name;
  }

  // For optional fields that can be cleared
  entity.notes = dto.notes || undefined;  // Not: || null

  return this.repository.save(entity);
}
```

### null vs undefined, decided once

| Layer | Use | Reason |
|---|---|---|
| Entity property type | `prop?: T` | Keeps reflected metadata as the real type |
| `repository.create()` argument | `undefined` | `DeepPartial<T>` rejects `null` for `T \| undefined` |
| Assignment to an optional property | `undefined` | Same type constraint, same error |
| Database column | SQL `NULL` | TypeORM writes `NULL` for `undefined` on a nullable column |
| DTO from a client | either | Normalize at the boundary, before it reaches the entity |

## 5. Database Setup

### Pre-Flight Checklist

Before starting the API, ensure:

1. **Database exists**
2. **Schema exists** (if using custom schema)
3. **Connection parameters are correct**

### Common Startup Error

```
error: database "app_dev" does not exist
```

### Solution: Create Database First

```bash
# Connect to postgres database to create new database
psql -h localhost -p 5432 -d postgres -c "CREATE DATABASE app_dev;"

# Then run setup script
psql -h localhost -p 5432 -d app_dev -f scripts/setup-database.sql
```

### Schema Creation in SQL Script

```sql
-- Always create schema first
CREATE SCHEMA IF NOT EXISTS myschema;

-- Then create tables
CREATE TABLE myschema.users (
  -- ...
);
```

### TypeORM Synchronize Setting

```typescript
// app.module.ts
TypeOrmModule.forRoot({
  // ...
  synchronize: true,  // OK for development
  // synchronize: false,  // REQUIRED for production - use migrations
})
```

**WARNING:** `synchronize: true` will modify your database schema on every startup. Never use in production!
For production schema changes use migrations — see
[database-migrations](../database-migrations/SKILL.md).

## 6. Troubleshooting: Symptom, Cause, Fix

### 6.1 Data type "Object" not supported

#### Error Message

```
DataTypeNotSupportedError: Data type "Object" in "EntityName.propertyName" is not supported by "postgres" database.
```

#### Cause

TypeScript union type with `null` causes metadata reflection to see `Object` instead of the actual type.

#### Bad Code

```typescript
@Column({ nullable: true })
imageUrl: string | null;  // BROKEN
```

#### Fix

```typescript
@Column({ type: 'varchar', length: 500, nullable: true })
imageUrl?: string;  // FIXED
```

#### Second Framing (same bug, minimal column options)

```typescript
// Before (broken)
@Column({ nullable: true })
name: string | null;

// After (fixed)
@Column({ type: 'varchar', nullable: true })
name?: string;
```

#### Rule

**Never use `| null` in entity property types. Use `?` optional syntax instead.**

If the error names a property you did not change, check `emitDecoratorMetadata` in
tsconfig.json first — a missing flag produces the identical message for every column.

### 6.2 null not assignable to undefined

#### Error Message

```
Type 'null' is not assignable to type 'string | undefined'.
Type 'null' is not assignable to type 'DeepPartial<Date | undefined>'.
```

#### Cause

Entity uses optional (`?`) syntax but service code assigns `null`.

#### Bad Code

```typescript
// In service
entity.notes = dto.notes || null;  // BROKEN
```

#### Fix

```typescript
// In service
entity.notes = dto.notes || undefined;  // FIXED
```

#### Second Framing (before/after)

```typescript
// Before (broken)
entity.notes = dto.notes || null;

// After (fixed)
entity.notes = dto.notes || undefined;
```

#### Rule

**Use `undefined` instead of `null` when working with optional entity properties.**

### 6.3 database does not exist

#### Error Message

```
error: database "app_dev" does not exist
```

#### Cause

Attempting to connect before the database is created.

#### Fix

```bash
# Connect to postgres db to create target db
psql -h localhost -p 5432 -d postgres -c "CREATE DATABASE app_dev;"
```

#### Rule

**Create the database BEFORE starting the application.**

### 6.4 relation does not exist

#### Error Message

```
error: relation "schema.table" does not exist
QueryFailedError: relation "myschema.users" does not exist
```

#### Cause

- Table doesn't exist
- Schema doesn't exist
- Wrong schema name in entity

#### Diagnostic Steps

```bash
# Check if schema exists
psql -d app_dev -c "SELECT schema_name FROM information_schema.schemata;"

# Check if table exists
psql -d app_dev -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'myschema';"
```

#### Fix

```bash
# Create schema
psql -d app_dev -c "CREATE SCHEMA IF NOT EXISTS myschema;"

# Run setup script
psql -d app_dev -f scripts/setup-database.sql
```

#### Entity Check

```typescript
// Verify schema name matches
@Entity({ schema: 'myschema', name: 'users' })  // Must match DB schema
```

#### Resolution Order

1. Check the schema name in the entity matches the database
2. Run migrations or the setup script
3. Verify `synchronize: true` in development (never in production)

### 6.5 No overload matches repository.create

#### Error Message

```
TS2769: No overload matches this call.
  Type 'Date | null' is not assignable to type 'DeepPartial<Date | undefined>'.
```

#### Cause

Passing `null` to `repository.create()` but the entity expects `undefined`.

#### Bad Code

```typescript
const entity = this.repository.create({
  eventDate: dto.eventDate ? new Date(dto.eventDate) : null,  // BROKEN
});
```

#### Fix

```typescript
const entity = this.repository.create({
  eventDate: dto.eventDate ? new Date(dto.eventDate) : undefined,  // FIXED
});
```

### 6.6 Cannot find module

#### Error Message

```
Error: Cannot find module './entities/user.entity'
```

#### Cause

- Wrong import path
- File doesn't exist
- TypeScript compilation issue
- Entity glob pattern in the TypeORM config does not match the built output

#### Fix

1. Verify the file exists at the specified path
2. Check for typos in the import
3. Run `npm run build` to verify compilation
4. Clear the dist folder and rebuild: `rm -rf dist && npm run build`
5. Verify the entity glob pattern in the TypeORM config

```bash
npm run build                   # confirm the entity compiles
rm -rf dist && npm run build    # or force a clean rebuild
ls dist/entities/               # confirm the compiled .js entities are there
```

```typescript
TypeOrmModule.forRoot({
  entities: [__dirname + '/**/*.entity{.ts,.js}'],
  // or
  entities: [User, Order, Product],  // Explicit imports
})
```

A glob that ends `.ts` only will resolve in development and fail in a compiled
container, where only `.js` exists. Keep the `{.ts,.js}` pair.

### 6.7 EntityMetadataNotFoundError

#### Error Message

```
EntityMetadataNotFoundError: No metadata for "User" was found.
```

#### Cause

Entity not registered in the TypeORM module.

#### Fix

```typescript
// In app.module.ts
TypeOrmModule.forRoot({
  entities: [User, Order, Product],  // Add missing entity
  // OR
  entities: [__dirname + '/**/*.entity{.ts,.js}'],  // Auto-discover
})
```

## 7. Project Structure

### Recommended Structure

```
apps/api/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── entities/                    # All TypeORM entities
│   │   ├── user.entity.ts
│   │   ├── order.entity.ts
│   │   └── index.ts                 # Re-export all entities
│   ├── modules/
│   │   ├── users/
│   │   │   ├── users.module.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   └── dto/
│   │   │       ├── create-user.dto.ts
│   │   │       └── update-user.dto.ts
│   │   └── orders/
│   │       └── ...
│   ├── guards/
│   │   ├── auth.guard.ts
│   │   └── roles.guard.ts
│   └── common/
│       ├── decorators/
│       └── interceptors/
├── package.json
└── tsconfig.json
```

The module, controller, service, guard, and DTO shapes that fill this tree are in
[nestjs-patterns](../nestjs-patterns/SKILL.md).

### Entity Index File Pattern

```typescript
// src/entities/index.ts
export * from './user.entity';
export * from './order.entity';
export * from './product.entity';
```

Then import in module:

```typescript
// app.module.ts
import { User, Order, Product } from './entities';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      entities: [User, Order, Product],
      // ...
    }),
  ],
})
export class AppModule {}
```

## 8. Quick Reference Checklist

### Before Writing Entities

- [ ] `emitDecoratorMetadata: true` in tsconfig.json
- [ ] `experimentalDecorators: true` in tsconfig.json
- [ ] Database and schema exist

### For Every Nullable Column

- [ ] Use `?` optional syntax, NOT `| null` union
- [ ] Explicitly specify `type` in `@Column` decorator
- [ ] Set `nullable: true` in decorator options

### For Every Service Method

- [ ] Use `undefined` instead of `null` for optional fields
- [ ] Handle DTO optional fields with `|| undefined`

### Before Starting API

- [ ] Database exists
- [ ] Schema exists (if custom)
- [ ] Environment variables set
- [ ] Migrations run (production) or synchronize enabled (development)

### Before Merging an Entity Change

- [ ] No `| null` union types were introduced
- [ ] Every new column has an explicit `type` in the decorator
- [ ] `bigint` ids are normalized with `Number()` before map/set/compare
- [ ] Foreign-key writes on entities loaded with relations use a query builder
- [ ] A migration accompanies the entity change (production runs with `synchronize: false`)

## Quick Fixes Cheat Sheet

| Problem | Quick Fix |
|---------|-----------|
| `Object` type error | Change `prop: T \| null` to `prop?: T` |
| `null` assignment error | Change `= null` to `= undefined` |
| Database missing | `psql -d postgres -c "CREATE DATABASE x;"` |
| Schema missing | `psql -d x -c "CREATE SCHEMA y;"` |
| Entity not found | Add to `entities` array in TypeOrmModule |
| Metadata `Object` on every column | Set `emitDecoratorMetadata: true` |
| FK column not written on save | Use `createQueryBuilder().update().set(...)` |
| `bigint` id misses a Map lookup | Wrap with `Number(...)` before the lookup |

## Templates

### Nullable Column Quick Template

```typescript
// String
@Column({ type: 'varchar', length: 255, nullable: true })
name?: string;

// Text
@Column({ type: 'text', nullable: true })
description?: string;

// Integer
@Column({ type: 'int', nullable: true })
count?: number;

// BigInt (FK)
@Column({ name: 'related_id', type: 'bigint', nullable: true })
relatedId?: number;

// Decimal
@Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
price?: number;

// Date
@Column({ name: 'event_date', type: 'timestamptz', nullable: true })
eventDate?: Date;
```

### Service Layer Quick Template

```typescript
// Creating with optional fields
const entity = this.repository.create({
  requiredField: dto.requiredField,
  optionalField: dto.optionalField,  // undefined if not provided
  dateField: dto.dateField ? new Date(dto.dateField) : undefined,
});

// Updating optional fields
entity.notes = dto.notes || undefined;  // NOT: || null
```

### Entity Template

```typescript
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Generated,
  ManyToOne,
  JoinColumn,
} from 'typeorm';

@Entity({ schema: 'myschema', name: 'my_table' })
export class MyEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'uuid', unique: true })
  @Generated('uuid')
  uuid: string;

  // Required string
  @Column({ length: 255 })
  name: string;

  // Optional string - USE THIS PATTERN
  @Column({ type: 'varchar', length: 500, nullable: true })
  description?: string;

  // Optional number
  @Column({ type: 'int', nullable: true })
  count?: number;

  // Optional foreign key
  @Column({ name: 'related_id', type: 'bigint', nullable: true })
  relatedId?: number;

  @ManyToOne(() => RelatedEntity, { nullable: true })
  @JoinColumn({ name: 'related_id' })
  related?: RelatedEntity;

  // JSONB with default
  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, unknown>;

  // Timestamps
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
```

## Related Skills

- [nestjs-patterns](../nestjs-patterns/SKILL.md) — modules, controllers, services,
  guards, DTOs, repositories, and testing around these entities
- [database-migrations](../database-migrations/SKILL.md) — the production replacement for
  `synchronize: true`, plus rollback and zero-downtime patterns
- [postgres-patterns](../postgres-patterns/SKILL.md) — query, index, and JSONB behaviour
  underneath the ORM

## Related Documents

- [TypeORM Official Documentation](https://typeorm.io/)
- [NestJS TypeORM Integration](https://docs.nestjs.com/techniques/database)

## In this pipeline

- Work is a work order: open it with `wo new`, size it honestly, fill the SPEC before code.
- Verification means behavioural tests that **ran**: `wo verify <n> --run <suite>` writes the status from the exit code. `NOT EXECUTED — PLAN ONLY` is honest; a typed `PASS` is not.
- Search the playbooks before building: `playbook search "<problem>"`.
- Route by area: `wo new --area`, `bug new --category`; the routing tables are in `core/rules/common/`.
