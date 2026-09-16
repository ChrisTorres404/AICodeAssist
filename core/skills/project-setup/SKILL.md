---
name: project-setup
description: Monorepo project setup patterns - workspace layout, package.json scripts, environment file precedence, database bootstrap, TypeScript config inheritance, port allocation, and the first-run developer workflow. Use when scaffolding a new repository, adding an app or package to an existing monorepo, or fixing a broken local setup.
---

# Project Setup Patterns

Patterns for setting up a monorepo with a backend API service, one or more frontend apps,
and PostgreSQL. Everything here is meant to be copied into a new repository and edited,
not read once and forgotten.

## When to Activate

- Scaffolding a new monorepo from an empty directory
- Adding a new app under `apps/` or a shared package under `packages/`
- Deciding which environment file a value belongs in, and in what order files load
- Bootstrapping a local database and its schema for the first time
- Setting up TypeScript config inheritance across workspaces
- Allocating ports so local and container environments never collide
- Writing the "clone to running" section of a README
- Diagnosing a setup that works on one machine and not another

## Table of Contents

1. [Monorepo Structure](#1-monorepo-structure)
2. [Package.json Patterns](#2-packagejson-patterns)
3. [Environment Configuration](#3-environment-configuration)
4. [Database Setup](#4-database-setup)
5. [TypeScript Configuration](#5-typescript-configuration)
6. [Development Workflow](#6-development-workflow)
7. [Quick Reference](#7-quick-reference)
8. [Setup Verification](#8-setup-verification)

---

## 1. Monorepo Structure

### Recommended Structure

```text
project-root/
├── apps/
│   ├── api/                    # Backend service (NestJS)
│   │   ├── src/
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── nest-cli.json
│   └── web/                    # Frontend app (Next.js)
│       ├── app/
│       ├── package.json
│       ├── tsconfig.json
│       └── next.config.js
├── packages/                   # Shared packages
│   └── types/                  # Shared TypeScript types
│       ├── src/
│       └── package.json
├── scripts/                    # Setup & utility scripts
│   └── setup-database.sql
├── package.json                # Root workspace config
├── tsconfig.json               # Base TS config
└── README.md
```

### Key Principles

1. **Apps are deployable** - Each app in `/apps` can be deployed independently
2. **Packages are shared** - Code in `/packages` is used by multiple apps
3. **Scripts are utilities** - Database setup, migrations, etc.
4. **One lockfile** - The lockfile lives at the root; per-app lockfiles are a bug
5. **No cross-app imports** - An app imports from `packages/`, never from another app

### Naming Convention

| Directory | Workspace name | Example |
|---|---|---|
| `apps/api` | `@{{PROJECT_NAME}}/api` | Backend service |
| `apps/web` | `@{{PROJECT_NAME}}/web` | Public frontend |
| `apps/admin` | `@{{PROJECT_NAME}}/admin` | Admin console |
| `packages/types` | `@{{PROJECT_NAME}}/types` | Shared types |
| `packages/sdk` | `@{{PROJECT_NAME}}/sdk` | Client SDK |

Pick one scope (`@{{PROJECT_NAME}}`) and use it for every workspace. Mixed scopes break
`--workspace=` targeting and make dependency graphs hard to read.

---

## 2. Package.json Patterns

### Root package.json (Workspace)

```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "dev": "npm run dev:api & npm run dev:web",
    "dev:api": "npm run dev --workspace=apps/api",
    "dev:web": "npm run dev --workspace=apps/web",
    "build": "npm run build --workspaces",
    "build:api": "npm run build --workspace=apps/api",
    "build:web": "npm run build --workspace=apps/web",
    "test": "npm run test --workspaces --if-present",
    "lint": "npm run lint --workspaces --if-present",
    "clean": "rm -rf apps/*/dist apps/*/.next node_modules"
  },
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
```

The root has no runtime dependencies. It only orchestrates. Anything a single app needs
belongs in that app's `package.json`.

### API package.json (NestJS)

```json
{
  "name": "@{{PROJECT_NAME}}/api",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "build": "nest build",
    "dev": "nest start --watch",
    "start": "node dist/main",
    "start:prod": "NODE_ENV=production node dist/main",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:cov": "jest --coverage",
    "lint": "eslint \"{src,test}/**/*.ts\" --fix",
    "migration:generate": "typeorm migration:generate -d dist/data-source.js",
    "migration:run": "typeorm migration:run -d dist/data-source.js"
  },
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/config": "^3.1.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/platform-express": "^10.3.0",
    "@nestjs/typeorm": "^10.0.1",
    "class-transformer": "^0.5.1",
    "class-validator": "^0.14.0",
    "cookie-parser": "^1.4.6",
    "pg": "^8.11.3",
    "reflect-metadata": "^0.2.1",
    "rxjs": "^7.8.1",
    "typeorm": "^0.3.19"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.3.0",
    "@nestjs/schematics": "^10.1.0",
    "@nestjs/testing": "^10.3.0",
    "@types/cookie-parser": "^1.4.6",
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.11",
    "@types/node": "^20.10.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.1",
    "typescript": "^5.3.0"
  }
}
```

### Web package.json (Next.js)

```json
{
  "name": "@{{PROJECT_NAME}}/web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3004",
    "build": "next build",
    "start": "next start -p 3004",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.1.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@tanstack/react-query": "^5.17.0",
    "lucide-react": "^0.303.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.3.0"
  }
}
```

Hard-code the port in the `dev` and `start` scripts. A frontend that picks a free port at
random breaks every callback URL, CORS allowlist and proxy rule you wrote down.

### Script Naming Rules

| Script | Must do | Must not do |
|---|---|---|
| `dev` | Start with watch/reload on the assigned port | Build for production |
| `build` | Produce the deployable artifact | Run tests |
| `start` | Run the already-built artifact | Compile from source |
| `test` | Run the unit suite non-interactively | Require a live database |
| `lint` | Check and autofix source | Fail on generated output |

Every workspace exposes the same script names. The root then fans out with
`--workspaces --if-present` and never needs to know what each app is.

---

## 3. Environment Configuration

### Environment File Pattern

```text
apps/api/
├── .env                    # Shared defaults (committed)
├── .env.development        # Dev defaults (committed)
├── .env.local              # Local overrides (gitignored)
└── .env.production         # Production (gitignored or CI/CD)
```

Rule of thumb: committed files hold values that are the same for every developer.
Gitignored files hold values that differ per machine, and secrets.

### .env.development (API)

```env
# Server
NODE_ENV=development
PORT=3001

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=app_user
DB_NAME={{DB_NAME}}

# External Services
AUTH_API_URL=http://localhost:3006

# Feature Flags
ENABLE_SWAGGER=true
LOG_LEVEL=debug
```

### .env.local (Web)

```env
# API
NEXT_PUBLIC_API_URL=http://localhost:3001

# Auth
NEXT_PUBLIC_AUTH_URL=http://localhost:3006
NEXT_PUBLIC_AUTH_KEY=pk_test_xxx

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false
```

Anything prefixed `NEXT_PUBLIC_` is compiled into the browser bundle. Never put a secret
behind that prefix; treat it as published the moment it is set.

### Loading Priority

Backend config module:

```typescript
ConfigModule.forRoot({
  envFilePath: ['.env.local', '.env.development', '.env'],
  isGlobal: true,
})
```

First file in the list wins. Next.js applies the same idea automatically:

1. `.env.local` (highest priority)
2. `.env.development` or `.env.production`
3. `.env` (lowest priority)

### Validate Config at Boot

```typescript
// apps/api/src/config/validation.ts
import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').required(),
  PORT: Joi.number().default(3001),
  DB_HOST: Joi.string().required(),
  DB_PORT: Joi.number().default(5432),
  DB_USER: Joi.string().required(),
  DB_NAME: Joi.string().required(),
});
```

A service that boots with a missing variable and fails on the first request is harder to
debug than one that refuses to start. Fail at boot, with the variable name in the message.

### .gitignore Pattern

```gitignore
# Environment (local overrides)
.env.local
.env.*.local
*.local

# Keep defaults committed
!.env
!.env.development
!.env.example
```

Commit a `.env.example` listing every variable with empty or dummy values. It is the only
reliable inventory of what the app needs.

---

## 4. Database Setup

### Setup Script Pattern

```sql
-- scripts/setup-database.sql

-- Create schema
CREATE SCHEMA IF NOT EXISTS app;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables
CREATE TABLE app.users (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  uuid UUID UNIQUE DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_users_email ON app.users(email);

-- Seed data
INSERT INTO app.users (email, name) VALUES
  ('admin@{{PROJECT_DOMAIN}}', 'Admin User'),
  ('user@{{PROJECT_DOMAIN}}', 'Test User');
```

The dual-key shape above (`id BIGINT` internal, `uuid UUID` external) is worth adopting
from day one: URLs and API payloads carry the `uuid`, joins and foreign keys carry the
`id`. Retrofitting it later means rewriting every route.

Note that PostgreSQL `BIGINT` columns come back from the driver as JavaScript **strings**,
not numbers. Normalize with `Number()` before using an id as a `Map` or `Set` key.

### Database Creation Commands

```bash
# Create database
psql -h localhost -p 5432 -d postgres -c "CREATE DATABASE app_dev;"

# Run setup script
psql -h localhost -p 5432 -d app_dev -f scripts/setup-database.sql

# Verify
psql -h localhost -p 5432 -d app_dev -c "SELECT * FROM app.users;"
```

### TypeORM DataSource Pattern

```typescript
// apps/api/src/data-source.ts
import { DataSource } from 'typeorm';
import { config } from 'dotenv';

config({ path: '.env.development' });

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: ['src/**/*.entity.ts'],
  migrations: ['src/migrations/*.ts'],
  synchronize: false,
  logging: true,
});
```

`synchronize: false` is not optional. Schema autosync silently drops columns; migrations
are the only reviewable record of what changed.

### Database Safety Rules

Never run these against a shared or production database without an explicit, written
instruction naming the database:

```bash
# Destructive - require explicit approval every time
dropdb app_dev
psql -d app_dev -c "DROP DATABASE app_dev;"
psql -d app_dev -c "DROP SCHEMA app CASCADE;"
```

If a migration fails, stop and diagnose. Do not reset the database to get a green run.

---

## 5. TypeScript Configuration

### Root tsconfig.json (Base)

```json
{
  "compilerOptions": {
    "target": "ES2021",
    "lib": ["ES2021"],
    "module": "commonjs",
    "moduleResolution": "node",
    "strict": true,
    "strictNullChecks": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

### API tsconfig.json

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "module": "commonjs",
    "outDir": "./dist",
    "baseUrl": "./",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Web tsconfig.json

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "ES2017"],
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### Config Inheritance Rules

| Setting | Where it belongs | Why |
|---|---|---|
| `strict`, `target`, `lib` baseline | Root | One answer for the whole repo |
| `outDir`, `module`, decorators | App | Build output differs per runtime |
| `paths` aliases | App | Alias roots differ per app |
| `jsx`, DOM libs | Frontend app only | Backend has no DOM |

Never redeclare `strict: false` in a leaf config to make a file compile. Fix the file.

---

## 6. Development Workflow

### Initial Setup Checklist

```bash
# 1. Clone and install
git clone <repo>
cd <project>
npm install

# 2. Create database
psql -h localhost -p 5432 -d postgres -c "CREATE DATABASE app_dev;"

# 3. Run setup script
psql -h localhost -p 5432 -d app_dev -f scripts/setup-database.sql

# 4. Copy environment files
cp apps/api/.env.example apps/api/.env.local
cp apps/web/.env.example apps/web/.env.local

# 5. Start development
npm run dev
```

Track the same steps as a checklist so a new contributor can report exactly where it broke:

- [ ] Repository cloned and `npm install` completed with no peer-dependency errors
- [ ] Database created and reachable with `psql`
- [ ] Setup script applied; expected tables present
- [ ] `.env.local` created for every app from its `.env.example`
- [ ] API starts and responds on its assigned port
- [ ] Frontend starts and can reach the API
- [ ] `npm test` passes from a clean checkout
- [ ] `npm run build` succeeds for every workspace

### Daily Development Commands

```bash
# Start all services
npm run dev

# Start individual services
npm run dev:api    # API on port 3001
npm run dev:web    # Web on port 3004

# Run tests
npm test
npm run test --workspace=apps/api -- --watch

# Build for production
npm run build

# Clean build artifacts
npm run clean
```

### Port Allocation Strategy

Give the project a written port-allocation standard and never assign a port outside it.
Two blocks, one for processes running directly on the developer machine and one for
containers, so both can run at the same time without conflict.

| Service | Local dev | Container | Description |
|---|---|---|---|
| Admin console | 3000 | 4000 | Admin frontend |
| API | 3001 | 4001 | Backend service |
| Portal | 3002 | 4002 | Customer-facing frontend |
| Dev console | 3003 | 4003 | Internal developer console |
| Web | 3004 | 4004 | Public/marketing frontend |
| CMS | 3005 | 4005 | Content service |
| Auxiliary services | 3006-3009 | 4006-4009 | Extra backends |
| PostgreSQL | 5432 | 4032 | Database |
| Redis | 6379 | 4039 | Cache |
| Mail catcher | - | 4025/4026 | SMTP test UI / SMTP |
| Reverse proxy | 80 | 4080 | Hostname routing |

Two rules keep this honest:

1. A service's local port and its container port differ by a fixed offset, so you can tell
   at a glance which environment a log line or a browser tab belongs to.
2. The port is written in the app's `package.json` and in the container compose file, and
   nowhere else.

### Hostname Routing

Browsers treat `localhost` as a public suffix, so cookies cannot be shared across
`*.localhost` subdomains. Any flow that depends on a shared cookie across subdomains
(single sign-on, multi-tenant subdomains, cross-app sessions) must be tested behind a
reverse proxy using real hostnames pointed at the loopback address.

```bash
# Point every development hostname at the loopback interface.
# /etc/hosts takes one "<address> <hostname>" line per hostname.
LOOPBACK=$(python3 -c 'import socket; print(socket.gethostbyname("localhost"))')
for host in example.com api.example.com admin.example.com portal.example.com; do
  printf '%s %s\n' "$LOOPBACK" "$host" | sudo tee -a /etc/hosts
done

# Verify resolution before starting the proxy
ping -c 1 api.example.com

# Local proxy on port 80 (needs elevated privileges).
# Substitute the reverse proxy this project uses and its own config file.
sudo <reverse-proxy> --config <proxy config for local>

# Container proxy on port 4080 (no elevated privileges)
<reverse-proxy> --config <proxy config for containers>
```

| Hostname | Local target | Container target |
|---|---|---|
| `api.example.com` | localhost:3001 | localhost:4001 |
| `admin.example.com` | localhost:3000 | localhost:4000 |
| `portal.example.com` | localhost:3002 | localhost:4002 |
| `example.com` | localhost:3004 | localhost:4004 |

### Git Workflow

```bash
# Feature branch
git checkout -b feature/my-feature

# Make changes, commit
git add .
git commit -m "feat: add feature description"

# Push and create PR
git push -u origin feature/my-feature
gh pr create --title "Add feature" --body "Description"
```

### Commit Message Convention

```text
type(scope): description

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code restructuring
- test: Adding tests
- chore: Maintenance

Examples:
- feat(api): add order creation endpoint
- fix(web): resolve login redirect issue
- docs: update README with setup instructions
```

---

## 7. Quick Reference

### Create New NestJS Module

```bash
cd apps/api
npx nest g module modules/feature-name
npx nest g controller modules/feature-name
npx nest g service modules/feature-name
```

### Create New Next.js Page

```bash
# Create page directory
mkdir -p "apps/web/app/(customer)/feature-name"

# Create page file
touch "apps/web/app/(customer)/feature-name/page.tsx"
```

### Create New Shared Package

```bash
mkdir -p packages/types/src
cd packages/types
npm init -y
npm pkg set name="@{{PROJECT_NAME}}/types" private=true main="src/index.ts"
```

### Database Commands

```bash
# Connect to database
psql -h localhost -p 5432 -d app_dev

# List schemas
\dn

# List tables in schema
\dt app.*

# Describe table
\d app.users

# Run SQL file
\i scripts/migration.sql
```

### Migration Commands

```bash
# Generate a migration from entity changes
npm run migration:generate --workspace=apps/api -- -n AddUserStatus

# Apply pending migrations
npm run migration:run --workspace=apps/api

# Show applied migrations
psql -h localhost -p 5432 -d app_dev -c "SELECT name FROM migrations ORDER BY id DESC LIMIT 10;"
```

---

## 8. Setup Verification

Run these before declaring a machine set up, and again after any dependency bump.

```bash
# Every workspace installs and builds from clean
rm -rf node_modules apps/*/node_modules && npm install && npm run build

# API answers on its port
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3001/health

# Frontend answers on its port
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3004

# Exactly one process owns each port
lsof -ti :3001 | wc -l
lsof -ti :3004 | wc -l

# Database reachable with the configured credentials
psql -h localhost -p 5432 -d app_dev -c "SELECT 1;"
```

- [ ] `npm install` from a clean checkout produces no errors
- [ ] `npm run build` succeeds in every workspace
- [ ] Each service answers HTTP 200 on its documented port
- [ ] Exactly one process is bound to each port
- [ ] Database connects with the credentials in the committed env defaults
- [ ] No secret appears in any committed file
- [ ] `.env.example` lists every variable the app reads

### Common Setup Failures

| Symptom | Cause | Fix |
|---|---|---|
| Port already in use | Stale watcher from an earlier session | `lsof -ti :<port> \| xargs kill -9`, then restart |
| Code change has no effect | A stale process is serving an old build | Verify process start time is later than the build output |
| Works locally, fails in container | Env value hard-coded to `localhost` | Use the service name inside the container network |
| Cookie not sent across subdomains | Testing on `localhost` instead of real hostnames | Route through the reverse proxy |
| Types resolve in the editor, fail in build | Alias declared in app config only | Declare `paths` where the build reads it |
| Migration fails on a teammate's machine | Schema created by hand, not by migration | Re-create from migrations only |

---

## Document History

Keep a history table at the bottom of the setup document in each repository.

| Date | Change |
|---|---|
| YYYY-MM-DD | Initial creation |
| YYYY-MM-DD | Added container port block |

---

## Related Skills

- [nestjs-patterns](../nestjs-patterns/SKILL.md) - backend module, guard and config structure
- [docker-patterns](../docker-patterns/SKILL.md) - container builds and compose wiring
- [deployment-patterns](../deployment-patterns/SKILL.md) - promoting a working local setup
- [database-migrations](../database-migrations/SKILL.md) - migration discipline after bootstrap
- [postgres-patterns](../postgres-patterns/SKILL.md) - schema and query practice
- [git-workflow](../git-workflow/SKILL.md) - branch, commit and PR conventions
- [api-design](../api-design/SKILL.md) - the contract the frontend consumes
- [security-review](../security-review/SKILL.md) - secrets and exposure checks before shipping
- [project-onboarding](../project-onboarding/SKILL.md) - getting a new contributor productive

## In this pipeline

- Setting up or restructuring a repository is a work order: open it with `wo new`, record
  the port allocation and env inventory in the SPEC before touching files.
- Verification means the commands in section 8 actually ran. `NOT EXECUTED - PLAN ONLY` is
  an honest status; a typed `PASS` is not.
- Search the playbooks before inventing a layout: `playbook search "monorepo setup"`.
