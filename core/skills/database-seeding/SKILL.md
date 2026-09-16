---
name: database-seeding
description: Multi-tier database seeding for multi-tenant PostgreSQL applications — system/tenant-template/dev-test seed categories, idempotent transactional seeders, RLS-aware seeding, tenant provisioning, and environment safety rails, with a working NestJS/TypeORM reference implementation. Use when writing database seeds, bootstrapping an environment, or provisioning a new tenant.
---

# Database Seeding

Seed data architecture for a multi-tenant platform on PostgreSQL: what belongs in
seeds, what belongs in the provisioning API, and how to keep both idempotent,
transactional and safe to run against production.

## When to Activate

- Writing or reviewing database seed files
- Bootstrapping a new environment (local, CI, staging, production)
- Deciding whether data belongs in a migration, a seed, or the provisioning API
- Adding a tenant template (default roles, privileges, settings) for new customers
- Debugging a failed or half-applied seed run
- Reviewing seeding for security problems (plaintext passwords, RLS bypass, test data in production)

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Quick Start](#quick-start)
3. [Multi-Tenancy Approaches](#multi-tenancy-approaches)
4. [Architecture Decisions](#architecture-decisions)
5. [Seed Data Categories](#seed-data-categories)
6. [Environment-Specific Strategies](#environment-specific-strategies)
7. [Tenant Provisioning Workflow](#tenant-provisioning-workflow)
8. [Implementation Details](#implementation-details)
9. [Available npm Scripts](#available-npm-scripts)
10. [CLI Options](#cli-options)
11. [How Seeds Work](#how-seeds-work)
12. [Writing a Seed File](#writing-a-seed-file)
13. [Security Considerations](#security-considerations)
14. [Testing](#testing)
15. [Troubleshooting](#troubleshooting)
16. [Reference Implementation](#reference-implementation)
17. [Best Practices](#best-practices)

---

## Executive Summary

The platform is a B2B service that other companies use for their own
authentication. When a customer signs up, they become a **tenant** in a shared
database isolated by PostgreSQL Row-Level Security (RLS). Seed data therefore
splits into three tiers: what every deployment needs, what every tenant needs,
and what only developers need.

### Key Architecture Decisions

- **Multi-Tenancy Model:** Shared database with RLS (PostgreSQL native security)
- **Isolation Strategy:** Row-Level Security policies on all tenant-scoped tables
- **Tenant Provisioning:** Automated via API endpoint (Tenant Provisioning Service)
- **Seed Data Categories:** System (required), Tenant Template (per-tenant), Dev/Test (development only)
- **Seeding Approach:** TypeScript seeders with ORM integration, run inside one transaction

### Quick Reference

| Environment | System Seeds | Tenant Seeds | Dev/Test Seeds |
|-------------|--------------|--------------|----------------|
| **Development** | Yes | Yes (multiple test tenants) | Yes (all test data) |
| **Staging** | Yes | Yes (1-2 test tenants) | Limited (verification only) |
| **Production** | Yes | No (created on signup) | No |

### Migration vs Seed vs Provisioning

| Kind of data | Where it belongs | Runs when |
|---|---|---|
| Table shape, constraints, indexes | Migration | Every deploy |
| Rows the application cannot boot without (system roles, privileges, settings) | System seed | Every deploy, idempotently |
| Rows a tenant cannot operate without (tenant roles, default privileges) | Tenant template, applied by the provisioning service | Tenant signup |
| Sample tenants, sample users, sample audit events | Dev/test seed | Development only |

---

## Quick Start

```bash
# Development: full seeding with test data
npm run seed:dev

# Staging: system seeds + minimal test data
npm run seed:staging

# Production: system seeds ONLY (requires --confirm)
npm run seed:production -- --confirm

# Force re-seed (deletes and recreates)
npm run seed:force

# Fresh database (reset + seed)
npm run db:seed:fresh
```

### Overview

The platform uses a **multi-tier seeding system** with different seed categories
for different purposes:

| Category | Purpose | Environments | Idempotent |
|----------|---------|--------------|------------|
| **001-system/** | Platform infrastructure (required) | All | Yes |
| **002-tenant-template/** | Template for new tenant signup | Prod (API), Dev/Staging (seeds) | Per-tenant |
| **003-dev-test/** | Test data and sample tenants | Dev only | Yes |

---

## Multi-Tenancy Approaches

Two industry patterns bracket the design space. Both were evaluated before
settling on the approach below.

### Pattern A: Application-Level Isolation

Used by hosted identity vendors that expose an "organizations" primitive.

#### Database Architecture

- **Approach:** Shared database with tenant isolation
- **Organizations Feature:** Built-in multi-tenancy support via an "organization" record
- **User Model:** Users can belong to multiple organizations/tenants
- **Data Isolation:** Application-level isolation with `tenant_id` in JWT claims

#### Tenant Provisioning

1. Customer signs up for an account
2. Organization record created automatically
3. First user becomes organization owner
4. Default RBAC roles assigned (owner, admin, member)
5. API keys generated for the organization
6. Webhook endpoints can be configured

#### Key Insights

- **Production-Ready Speed:** A packaged multi-tenancy primitive lands in under a week, versus person-years to build isolation, invitations, roles and audit from scratch
- **Infrastructure as Code:** Tenant provisioning is automated and repeatable
- **No Separate Databases:** All tenants share the same database infrastructure
- **Scalability:** Adding a new customer does not require provisioning new infrastructure

### Pattern B: Database-Level Isolation with RLS

Used by Postgres-native backend platforms.

#### Database Architecture

- **Approach:** Shared database with PostgreSQL Row-Level Security (RLS)
- **Isolation Mechanism:** RLS policies enforced at database level
- **Security:** Defense-in-depth — even if the application is bypassed, RLS blocks unauthorized access
- **Performance:** RLS adds an implicit `WHERE tenant_id = X` to all queries

#### RLS Best Practices

**1. Use application-controlled metadata (NOT user-editable metadata)**

```typescript
// SECURE - cannot be modified by the user
auth.users.app_metadata = { tenant_id: '123' }

// INSECURE - the user can modify this!
auth.users.user_metadata = { tenant_id: '123' }
```

**2. Enable RLS on ALL public tables**

```sql
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE my_table FORCE ROW LEVEL SECURITY; -- even for the table owner
```

**3. Create helper functions**

```sql
-- Helper to get tenant_id from the JWT
CREATE FUNCTION auth.tenant_id() RETURNS UUID AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID;
$$ LANGUAGE sql STABLE;
```

**4. Design specific policies**

```sql
-- Specific policy per operation
CREATE POLICY tenant_select ON my_table
  FOR SELECT USING (tenant_id = auth.tenant_id());

CREATE POLICY tenant_insert ON my_table
  FOR INSERT WITH CHECK (tenant_id = auth.tenant_id());
```

**5. Index design for performance**

```sql
-- Always add tenant_id to indexes
CREATE INDEX idx_users_tenant_email ON users(tenant_id, email);
CREATE INDEX idx_sessions_tenant_user ON sessions(tenant_id, user_id);
```

#### Key Insights

- **Complete Data Isolation:** Users NEVER see data from other tenants, even with SQL injection
- **Database-Level Security:** RLS is enforced by PostgreSQL itself, not the application layer
- **Performance Consideration:** All queries are implicitly filtered by `tenant_id`
- **Defense-in-Depth:** Application-level AND database-level security

---

## Architecture Decisions

### Why Shared Database + RLS?

**Chosen approach:** a single PostgreSQL database with Row-Level Security.

#### Comparison of Multi-Tenancy Approaches

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Database-per-Tenant** | Maximum isolation, custom schema per tenant | High infrastructure cost, complex backups, scaling problems | Rejected |
| **Schema-per-Tenant** | Good isolation, easier than separate DBs | Still complex, painful migrations, limited by DB connections | Rejected |
| **Shared DB + RLS** | Cost-efficient, simple operations, PostgreSQL-native security | Requires careful policy design, performance tuning for large datasets | **SELECTED** |

#### Why RLS is the Right Choice

1. **Cost-Effective:** One database cluster serves all tenants
2. **Simple Operations:** Single backup, single migration, single deployment
3. **PostgreSQL Native:** RLS is a core PostgreSQL feature, stable since 9.5
4. **Security by Default:** Even with SQL injection, tenants cannot see each other's data
5. **Industry Standard:** The dominant pattern for shared-database SaaS

### Reference RLS Implementation

**Status:** RLS policies are part of the v1 schema, created by migrations, not by seeds.

#### Key Helper Functions

```sql
-- Get current user ID from the JWT
auth.uid() RETURNS UUID

-- Get current tenant ID from the JWT
auth.tenant_id() RETURNS UUID

-- Check if the user is a platform owner
auth.is_platform_owner() RETURNS BOOLEAN

-- Get current organization ID
auth.organization_id() RETURNS UUID

-- Check a user privilege
auth.has_privilege(privilege_code VARCHAR) RETURNS BOOLEAN
```

#### Example RLS Policy (auth.users table)

```sql
-- Users can only see users in their own tenant
CREATE POLICY users_view_own_tenant ON auth.users
  FOR SELECT
  USING (tenant_id = auth.tenant_id() OR auth.is_platform_owner());

-- Platform owners can manage all tenants
CREATE POLICY platform_owners_manage_tenants ON auth.tenants
  USING (auth.is_platform_owner());
```

#### Tables with RLS Enabled

- `auth.tenants` — tenant isolation
- `auth.users` — per-tenant users
- `auth.sessions` — per-tenant sessions
- `auth.api_keys` — per-tenant API keys
- `rbac.roles` — per-tenant roles
- `rbac.privileges` — per-tenant privileges
- `webhooks.endpoints` — per-tenant webhooks
- `audit.events` — per-tenant audit logs
- `org.organizations` — per-tenant organizations

**Verification query:**

```sql
SELECT * FROM auth.verify_rls_enabled();
```

---

## Seed Data Categories

### 1. System Seeds (001-system/)

**Purpose:** Required for the platform to function
**When:** Always present in ALL environments
**Idempotent:** Safe to run multiple times

#### What Gets Seeded

**Platform Owner Account**

- Email: `owner@{{PROJECT_DOMAIN}}` (from `SEED_OWNER_EMAIL`)
- Password: hashed with bcrypt, cost 10, value read from `SEED_OWNER_PASSWORD`
- Tenant: the platform tenant (a special tenant that owns the deployment)
- Role: Platform Administrator
- Privileges: ALL (superuser)

**System Roles (rbac.roles)**

- `platform_admin` — full system access (platform owners only)
- `tenant_admin` — full tenant access (the customer's admin)
- `member` — standard user access (default for new users)
- `viewer` — read-only access

**System Privileges (rbac.privileges)**

- Core privileges that every tenant needs
- Example: `users:read`, `users:create`, `sessions:revoke`, `api_keys:manage`

**System Settings**

- Default password policies
- Session timeout defaults
- Rate limiting defaults
- Data-protection and retention settings

**Notification Definitions**

- Notification event catalogue
- Notification templates
- Notification providers

#### When to Run

- Initial deployment (all environments)
- After a database reset
- After migrations, when the schema changed

#### What It Creates

```text
Platform Tenant:
  - Name: {{PROJECT_NAME}} Platform
  - Slug: platform
  - Subdomain: platform.{{PROJECT_DOMAIN}}

Platform Owner:
  - Email: owner@{{PROJECT_DOMAIN}}
  - Password: from SEED_OWNER_PASSWORD (rotate immediately in production)
  - Platform Administrator role

System Roles:
  - platform_admin (superuser)
  - tenant_admin (full tenant access)
  - member (standard user - default)
  - viewer (read-only)
```

#### Files Created

```text
{{API_APP}}/src/database/seeds/
└── 001-system/
    ├── 001-platform-tenant.seed.ts
    ├── 002-platform-owner.seed.ts
    ├── 003-system-roles.seed.ts
    ├── 004-system-privileges.seed.ts
    └── 005-system-settings.seed.ts
```

### 2. Tenant Template Seeds (002-tenant-template/)

**Purpose:** Template applied when a new customer signs up
**When:** Production (on signup), Dev/Staging (for test tenants)
**Idempotent:** Applied per tenant, not globally

**Not implemented as standalone seeds** in production — the same template code is
called by the Tenant Provisioning Service API.

#### What Gets Seeded

**Per-Tenant Resources:**

1. **Default RBAC Roles**
   - `admin` — tenant administrator
   - `member` — standard user
   - `viewer` — read-only user

2. **Default Privileges**
   - Basic permission set for a new tenant
   - Can be customized later by the tenant admin

3. **Welcome Resources**
   - Welcome email template
   - Default webhook endpoints (optional)
   - API key for initial integration (optional)

4. **Tenant Admin User**
   - Created from signup form data
   - Email verification sent
   - Assigned the `admin` role
   - No default password (set during signup)

#### Tenant Provisioning Flow

```typescript
// When a customer signs up at https://{{PROJECT_DOMAIN}}/signup
async function provisionNewTenant(signupData) {
  // 1. Create tenant record
  const tenant = await createTenant({
    name: signupData.company_name,
    slug: generateSlug(signupData.company_name),
    subdomain: signupData.subdomain,
  });

  // 2. Apply tenant template seeds
  await applyTenantTemplate(tenant.id, {
    admin_email: signupData.email,
    admin_name: signupData.name,
  });

  // 3. Send welcome email
  await sendWelcomeEmail(tenant, signupData);

  return tenant;
}
```

#### Files Created

```text
{{API_APP}}/src/database/seeds/
└── 002-tenant-template/
    ├── 001-tenant-roles.template.ts
    ├── 002-tenant-privileges.template.ts
    ├── 003-tenant-admin-user.template.ts
    └── 004-welcome-resources.template.ts
```

### 3. Dev/Test Seeds (003-dev-test/)

**Purpose:** Development and testing convenience
**When:** Development only, limited staging
**Idempotent:** Safe to reset and re-run

#### What Gets Seeded

**Test Tenants (3-5 sample companies)**

- "Tenant One" (`tenant-one`) — technology company
- "Tenant Two" (`tenant-two`) — small startup
- "Demo Tenant" (`demo-tenant`) — enterprise customer

**Test Users (10-15 with known passwords)**

| Account | Password source | Purpose |
|---|---|---|
| `admin@{{PROJECT_DOMAIN}}` | `SEED_DEV_PASSWORD` | Tenant admin |
| `user@{{PROJECT_DOMAIN}}` | `SEED_DEV_PASSWORD` | Standard user |
| `viewer@{{PROJECT_DOMAIN}}` | `SEED_DEV_PASSWORD` | Read-only user |
| `mfa@{{PROJECT_DOMAIN}}` | `SEED_DEV_PASSWORD` | MFA-enrolled user |
| `locked@{{PROJECT_DOMAIN}}` | `SEED_DEV_PASSWORD` | Locked account |

All dev accounts share one password taken from `SEED_DEV_PASSWORD`, defaulting to
`DevPassw0rd!` on a local machine. Never set that variable in staging or production.

**Sample Data**

- Active sessions (for testing session management)
- API keys (for testing API key flows)
- Webhook endpoints (for testing webhook delivery)
- Audit events (for testing audit logs)
- Organizations (for testing org hierarchy)

**Test Credentials File**

- All test accounts documented in `003-dev-test/TEST-CREDENTIALS.md`
- Passwords clearly listed (dev values only)
- Purpose of each account explained

#### Files Created

```text
{{API_APP}}/src/database/seeds/
└── 003-dev-test/
    ├── 000-tenant-roles.seed.ts
    ├── 001-test-tenants.seed.ts
    ├── 002-test-users.seed.ts
    ├── 003-user-role-assignments.seed.ts
    ├── 004-test-organizations.seed.ts
    ├── 005-test-webhooks.seed.ts
    └── TEST-CREDENTIALS.md
```

---

## Environment-Specific Strategies

### Development Environment

**Database:** `{{DB_NAME}}` (example `app_dev`, local PostgreSQL)
**Goal:** Full testing capabilities with sample data

```bash
# Full development seeding
npm run seed:dev

# What gets seeded:
# yes - System seeds (platform owner, system roles)
# yes - Tenant template seeds (3 test tenants)
# yes - Dev/test seeds (10-15 test users, sample data)
```

**Characteristics:**

- Multiple test tenants with realistic data
- Known test credentials (documented)
- Sample sessions, API keys, webhooks
- Safe to reset and re-seed at any time
- RLS policies active (isolation is exercised, not disabled)

### Staging/Test Environment

**Database:** `app_staging` (cloud PostgreSQL)
**Goal:** Production-like testing with minimal test data

```bash
# Staging seeding
npm run seed:staging

# What gets seeded:
# yes   - System seeds (platform owner, system roles)
# yes   - Tenant template seeds (1 test tenant only)
# maybe - Dev/test seeds (minimal - 2-3 test users)
```

**Characteristics:**

- Production-like configuration
- Minimal test data (verify flows work)
- Real email delivery testing
- Load testing capabilities
- Security testing environment

### Production Environment

**Database:** `app_production` (cloud PostgreSQL)
**Goal:** Secure, production-ready platform

```bash
# Production seeding (ONLY run during initial deployment)
npm run seed:production -- --confirm

# What gets seeded:
# yes - System seeds (platform owner, system roles)
# no  - Tenant template seeds (created via API instead)
# no  - Dev/test seeds (security risk)
```

**Characteristics:**

- System seeds only (platform infrastructure)
- Real tenants created via the signup API
- No test data whatsoever
- Monitoring and alerts enabled
- Automated backups configured — see [database-backup](../database-backup/SKILL.md)

### Environment-Specific Behaviour

#### Development

```bash
npm run seed:dev
```

**What runs:**

1. System seeds (platform tenant, owner, roles)
2. Dev/test seeds (3 test tenants, 10+ test users)

**Result:** full testing environment with sample data

#### Staging

```bash
npm run seed:staging
```

**What runs:**

1. System seeds (platform tenant, owner, roles)
2. Optional: 1 test tenant for verification

**Result:** production-like with minimal test data

#### Production

```bash
npm run seed:production -- --confirm
```

**What runs:**

1. System seeds ONLY (platform tenant, owner, roles)
2. NO test data
3. Requires an explicit `--confirm` flag

**Result:** clean production platform ready for real tenants

**Real tenants created via:**

- Tenant Provisioning API endpoint
- `POST /api/v1/tenants/signup`

---

## Tenant Provisioning Workflow

### Signup Flow (Customer Self-Service)

```typescript
/**
 * TENANT PROVISIONING API ENDPOINT
 * POST /api/v1/tenants/signup
 */

interface TenantSignupRequest {
  // Company information
  company_name: string;        // "Tenant One"
  subdomain: string;           // "tenant-one" -> tenant-one.example.com
  industry?: string;           // Optional

  // Admin user information
  admin_email: string;         // the admin address at the customer domain
  admin_first_name: string;    // given name
  admin_last_name: string;     // family name
  admin_password: string;      // Must meet password policy

  // Optional
  phone?: string;
  timezone?: string;
  custom_domain?: string;      // For enterprise customers
}

interface TenantProvisioningResponse {
  tenant: {
    id: string;
    name: string;
    slug: string;
    subdomain: string;
    status: 'active' | 'pending_verification';
  };
  admin_user: {
    id: string;
    email: string;
    email_verification_sent: boolean;
  };
  resources_created: {
    roles: number;
    privileges: number;
    api_keys: number;
  };
  next_steps: string[];
}
```

### Provisioning Implementation

```typescript
// {{API_APP}}/src/modules/tenants/services/tenant-provisioning.service.ts

@Injectable()
export class TenantProvisioningService {

  async provisionTenant(
    signupData: TenantSignupRequest,
  ): Promise<TenantProvisioningResponse> {

    // Step 1: Validate subdomain availability
    await this.validateSubdomain(signupData.subdomain);

    // Step 2: Create tenant record
    const tenant = await this.createTenant({
      name: signupData.company_name,
      slug: this.generateSlug(signupData.company_name),
      subdomain: signupData.subdomain,
      custom_domain: signupData.custom_domain,
      settings: {
        industry: signupData.industry,
        timezone: signupData.timezone || 'UTC',
      },
    });

    // Step 3: Apply tenant template (TRANSACTIONAL)
    await this.queryRunner.startTransaction();

    try {
      // Create default RBAC roles
      const roles = await this.createTenantRoles(tenant.id);

      // Create default privileges
      const privileges = await this.createTenantPrivileges(tenant.id);

      // Create admin user
      const adminUser = await this.createTenantAdmin(tenant.id, {
        email: signupData.admin_email,
        first_name: signupData.admin_first_name,
        last_name: signupData.admin_last_name,
        password: signupData.admin_password,
        phone: signupData.phone,
      });

      // Assign admin role to admin user
      await this.assignRole(adminUser.id, roles.admin.id);

      // Create initial API key (optional)
      const apiKey = await this.createInitialApiKey(tenant.id, adminUser.id);

      // Log provisioning event
      await this.auditService.log({
        action: 'tenant.provisioned',
        actor_type: 'system',
        resource_type: 'tenant',
        resource_id: tenant.id,
        metadata: {
          tenant_name: tenant.name,
          admin_email: adminUser.email,
        },
        severity: 'info',
      });

      await this.queryRunner.commitTransaction();

      // Step 4: Send welcome email (async, non-blocking)
      await this.emailService.sendWelcomeEmail(tenant, adminUser);

      return {
        tenant: {
          id: tenant.id,
          name: tenant.name,
          slug: tenant.slug,
          subdomain: tenant.subdomain,
          status: 'active',
        },
        admin_user: {
          id: adminUser.id,
          email: adminUser.email,
          email_verification_sent: true,
        },
        resources_created: {
          roles: roles.length,
          privileges: privileges.length,
          api_keys: apiKey ? 1 : 0,
        },
        next_steps: [
          'Verify your email address',
          'Complete your profile',
          'Configure authentication settings',
          'Invite team members',
        ],
      };

    } catch (error) {
      await this.queryRunner.rollbackTransaction();
      throw error;
    }
  }

  private async createTenantRoles(tenantId: string) {
    // Apply role template
    const adminRole = await this.rolesRepository.save({
      tenant_id: tenantId,
      key: 'admin',
      name: 'Administrator',
      description: 'Full tenant administration access',
      permissions: ['*'], // All permissions
      is_system: true,
      is_default: false,
    });

    const memberRole = await this.rolesRepository.save({
      tenant_id: tenantId,
      key: 'member',
      name: 'Member',
      description: 'Standard user access',
      permissions: ['users:read', 'sessions:read', 'profile:update'],
      is_system: true,
      is_default: true, // Default for new users
    });

    const viewerRole = await this.rolesRepository.save({
      tenant_id: tenantId,
      key: 'viewer',
      name: 'Viewer',
      description: 'Read-only access',
      permissions: ['users:read', 'sessions:read'],
      is_system: true,
      is_default: false,
    });

    return { admin: adminRole, member: memberRole, viewer: viewerRole };
  }

  private async createTenantAdmin(
    tenantId: string,
    adminData: CreateAdminUserDto,
  ) {
    const hashedPassword = await bcrypt.hash(adminData.password, 10);

    const adminUser = await this.usersRepository.save({
      tenant_id: tenantId,
      email: adminData.email,
      first_name: adminData.first_name,
      last_name: adminData.last_name,
      phone: adminData.phone,
      encrypted_password: hashedPassword,
      email_verified_at: null, // Must verify email
      is_active: true,
      is_platform_owner: false,
    });

    return adminUser;
  }
}
```

---

## Implementation Details

### File Structure

```text
{{API_APP}}/
├── src/
│   ├── database/
│   │   └── seeds/
│   │       ├── 001-system/
│   │       │   ├── 001-platform-tenant.seed.ts
│   │       │   ├── 002-platform-owner.seed.ts
│   │       │   ├── 003-system-roles.seed.ts
│   │       │   ├── 004-system-privileges.seed.ts
│   │       │   └── 005-system-settings.seed.ts
│   │       ├── 002-notifications/
│   │       │   ├── 001-notification-events.seed.ts
│   │       │   ├── 002-notification-templates.seed.ts
│   │       │   └── 003-notification-providers.seed.ts
│   │       ├── 002-tenant-template/
│   │       │   ├── 001-tenant-roles.template.ts
│   │       │   ├── 002-tenant-privileges.template.ts
│   │       │   ├── 003-tenant-admin-user.template.ts
│   │       │   └── 004-welcome-resources.template.ts
│   │       ├── 003-dev-test/
│   │       │   ├── 000-tenant-roles.seed.ts
│   │       │   ├── 001-test-tenants.seed.ts
│   │       │   ├── 002-test-users.seed.ts
│   │       │   ├── 003-user-role-assignments.seed.ts
│   │       │   ├── 004-test-organizations.seed.ts
│   │       │   ├── 005-test-webhooks.seed.ts
│   │       │   └── TEST-CREDENTIALS.md
│   │       ├── seeder.service.ts
│   │       ├── seeder.module.ts
│   │       ├── cli.ts
│   │       └── README.md
│   └── modules/
│       └── tenants/
│           ├── services/
│           │   └── tenant-provisioning.service.ts
│           └── controllers/
│               └── tenant-signup.controller.ts
└── package.json
```

### TypeScript Seeder Service

The full file is in [`reference/seeder.service.ts`](reference/seeder.service.ts).
The shape of it:

```typescript
// {{API_APP}}/src/database/seeds/seeder.service.ts

import { Injectable, Logger } from '@nestjs/common';
import { DataSource, QueryRunner } from 'typeorm';

export interface SeederOptions {
  environment: 'development' | 'staging' | 'production';
  force?: boolean; // Re-seed even if data exists
  verbose?: boolean;
}

@Injectable()
export class SeederService {
  private readonly logger = new Logger(SeederService.name);
  private queryRunner: QueryRunner;

  constructor(private dataSource: DataSource) {}

  async seed(options: SeederOptions): Promise<void> {
    this.queryRunner = this.dataSource.createQueryRunner();
    await this.queryRunner.connect();
    await this.queryRunner.startTransaction();

    try {
      this.logger.log(`Starting ${options.environment} seeding...`);

      // ALWAYS run system seeds
      await this.runSystemSeeds(options);

      // Environment-specific seeding
      if (options.environment === 'development') {
        await this.runTenantTemplateSeeds(options);
        await this.runDevTestSeeds(options);
      } else if (options.environment === 'staging') {
        await this.runTenantTemplateSeeds(options);
        // Minimal dev/test seeds for staging
      }
      // Production: ONLY system seeds

      await this.queryRunner.commitTransaction();
      this.logger.log('Seeding completed successfully');

    } catch (error) {
      await this.queryRunner.rollbackTransaction();
      this.logger.error('Seeding failed:', error);
      throw error;
    } finally {
      await this.queryRunner.release();
    }
  }

  private async runSystemSeeds(options: SeederOptions): Promise<void> {
    this.logger.log('Running system seeds...');

    // Import and run all system seeds. Order matters.
    await import('./001-system/001-platform-tenant.seed').then((m) =>
      m.default(this.queryRunner, options),
    );
    await import('./001-system/002-platform-owner.seed').then((m) =>
      m.default(this.queryRunner, options),
    );
    await import('./001-system/003-system-roles.seed').then((m) =>
      m.default(this.queryRunner, options),
    );
    await import('./001-system/004-system-privileges.seed').then((m) =>
      m.default(this.queryRunner, options),
    );
  }

  private async runTenantTemplateSeeds(options: SeederOptions): Promise<void> {
    this.logger.log('Running tenant template seeds...');
    // Applied per-tenant, not globally
  }

  private async runDevTestSeeds(options: SeederOptions): Promise<void> {
    this.logger.log('Running dev/test seeds...');

    await import('./003-dev-test/001-test-tenants.seed').then((m) =>
      m.default(this.queryRunner, options),
    );
    await import('./003-dev-test/002-test-users.seed').then((m) =>
      m.default(this.queryRunner, options),
    );
  }
}
```

Two import styles work. `await import(...)` is the ESM form shown above;
`require(seedPath)` in a loop, as the reference file does, keeps the seed list as
data and survives `ts-node` under CommonJS. Pick one and use it consistently.

### Seeder Module

```typescript
// {{API_APP}}/src/database/seeds/seeder.module.ts

@Module({
  imports: [TypeOrmModule.forFeature([])],
  providers: [SeederService],
  exports: [SeederService],
})
export class SeederModule {}
```

Full file: [`reference/seeder.module.ts`](reference/seeder.module.ts).

### Seeder CLI

The CLI parses flags, refuses to touch production without `--confirm`, verifies
the schema, then delegates to `SeederService.seed()`. Full file:
[`reference/cli.ts`](reference/cli.ts).

### npm Scripts

```json
{
  "scripts": {
    "seed": "npm run seed:dev",
    "seed:dev": "NODE_ENV=development ts-node -r tsconfig-paths/register src/database/seeds/cli.ts",
    "seed:staging": "NODE_ENV=staging ts-node -r tsconfig-paths/register src/database/seeds/cli.ts",
    "seed:production": "NODE_ENV=production ts-node -r tsconfig-paths/register src/database/seeds/cli.ts --confirm",
    "seed:system": "ts-node -r tsconfig-paths/register src/database/seeds/cli.ts --system-only",
    "seed:force": "NODE_ENV=development ts-node -r tsconfig-paths/register src/database/seeds/cli.ts --force",
    "seed:reset": "npm run db:reset && npm run seed:dev",
    "db:seed:fresh": "npm run db:reset && npm run migration:run && npm run seed:dev",
    "db:reset": "psql -h localhost -U app -d app_dev -f scripts/reset-database.sql"
  }
}
```

---

## Available npm Scripts

### Seeding Commands

```bash
# Run development seeds (default)
npm run seed
npm run seed:dev

# Run staging seeds
npm run seed:staging

# Run production seeds (requires confirmation)
npm run seed:production -- --confirm

# System seeds only
npm run seed:system

# Force re-seed (even if data exists)
npm run seed:force

# Verbose output
npm run seed:dev -- --verbose
```

### Database Management

```bash
# Reset database (DANGEROUS - deletes all data!)
npm run db:reset

# Reset + fresh seed
npm run db:seed:fresh

# Show pending migrations
npm run migration:show

# Run migrations
npm run migration:run

# Revert last migration
npm run migration:revert
```

---

## CLI Options

### Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--verbose` / `-v` | Detailed logging | `npm run seed:dev -- --verbose` |
| `--force` | Re-seed even if data exists | `npm run seed:dev -- --force` |
| `--confirm` | Production confirmation (required) | `npm run seed:production -- --confirm` |
| `--system-only` | Run system seeds and stop | `npm run seed:system` |

### Environment Variables

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `NODE_ENV` | development, staging, production | development | Controls which seeds run |
| `SEED_OWNER_EMAIL` | any address | `owner@` + `SEED_DOMAIN` | Platform owner account |
| `SEED_OWNER_PASSWORD` | any string | unset — required outside development | Platform owner password before first rotation |
| `SEED_DOMAIN` | a domain | `example.test` | Domain used to build seeded addresses |
| `SEED_DEV_PASSWORD` | any string | `DevPassw0rd!` | Shared password for dev/test accounts |

---

## How Seeds Work

### 1. Idempotency

All seeds are **idempotent** — safe to run multiple times without duplicating data.

```typescript
// Example: check before insert
const existing = await queryRunner.query(
  'SELECT id FROM auth.tenants WHERE slug = $1',
  ['platform'],
);

if (existing.length === 0) {
  // Create only if it does not exist
  await queryRunner.query('INSERT INTO auth.tenants ...');
}
```

An `INSERT ... ON CONFLICT DO NOTHING` against the natural key is equivalent and
is one round trip instead of two:

```sql
INSERT INTO rbac.roles (tenant_id, key, name, is_system)
VALUES ($1, 'member', 'Member', true)
ON CONFLICT (tenant_id, key) DO NOTHING;
```

### 2. Transaction Safety

All seeds run in a **single transaction**:

- Either ALL seeds succeed, or NONE do
- Database rollback on any error
- No partial seeding

### 3. Password Hashing

All passwords use **bcrypt with cost 10**:

```typescript
import * as bcrypt from 'bcrypt';

const hashedPassword = await bcrypt.hash(process.env.SEED_DEV_PASSWORD!, 10);
```

### 4. RLS Compliance

Seeds respect Row-Level Security policies:

- Uses the platform owner context
- Verifies RLS is enabled before seeding

### 5. Ordering

Seed order is a hard dependency, not a preference. Rows that other rows point at
come first:

```text
platform tenant -> platform owner -> system roles -> system privileges
                -> notification events -> templates -> providers
test tenants -> tenant roles -> test users -> role assignments -> orgs -> webhooks
```

Keep the order explicit in one list in the seeder service; never rely on
directory listing order, which differs between filesystems.

---

## Writing a Seed File

### Anatomy

Every seed file exports one default function taking the shared `QueryRunner` and
the run options, so the seeder can drive them all the same way.

```typescript
import { QueryRunner } from 'typeorm';
import { SeederOptions } from '../seeder.service';

export default async function seed(
  queryRunner: QueryRunner,
  options: SeederOptions,
): Promise<void> {
  // 1. Read what already exists
  // 2. Insert only what is missing (or update when options.force)
  // 3. Log one line per created object when options.verbose
}
```

### Worked Example: system roles seed

```typescript
// {{API_APP}}/src/database/seeds/001-system/003-system-roles.seed.ts

import { QueryRunner } from 'typeorm';
import { SeederOptions } from '../seeder.service';

const SYSTEM_ROLES = [
  { key: 'platform_admin', name: 'Platform Administrator', is_default: false },
  { key: 'tenant_admin', name: 'Tenant Administrator', is_default: false },
  { key: 'member', name: 'Member', is_default: true },
  { key: 'viewer', name: 'Viewer', is_default: false },
];

export default async function seed(
  queryRunner: QueryRunner,
  options: SeederOptions,
): Promise<void> {
  const [platform] = await queryRunner.query(
    'SELECT id FROM auth.tenants WHERE slug = $1',
    ['platform'],
  );

  if (!platform) {
    throw new Error('Platform tenant not found - run 001-platform-tenant.seed first');
  }

  for (const role of SYSTEM_ROLES) {
    const result = await queryRunner.query(
      `INSERT INTO rbac.roles (tenant_id, key, name, is_system, is_default)
       VALUES ($1, $2, $3, true, $4)
       ON CONFLICT (tenant_id, key) DO NOTHING
       RETURNING id`,
      [platform.id, role.key, role.name, role.is_default],
    );

    if (options.verbose) {
      const verb = result.length > 0 ? 'created' : 'already present';
      console.log(`  role ${role.key}: ${verb}`);
    }
  }
}
```

Expected output on a second run, which proves idempotency:

```text
  role platform_admin: already present
  role tenant_admin: already present
  role member: already present
  role viewer: already present
```

---

## Security Considerations

### Password Hashing

**CRITICAL:** all passwords MUST use bcrypt with cost factor 10 or higher.

```typescript
import * as bcrypt from 'bcrypt';

// CORRECT
const hashedPassword = await bcrypt.hash(plainPassword, 10);

// WRONG - never store plain passwords
const user = { password: 'example-pass-1' }; // BAD
```

### Idempotency

All seed files MUST be idempotent (safe to run multiple times).

```typescript
// CORRECT - check before insert
const existing = await queryRunner.manager.findOne(User, {
  where: { email: ownerEmail },
});

if (!existing) {
  await queryRunner.manager.save(User, { /* ... */ });
}

// WRONG - will fail on the second run
await queryRunner.manager.save(User, { /* ... */ });
```

### RLS Verification

Seeds must respect RLS policies.

```typescript
// Disable RLS for seeding (use with caution!)
await queryRunner.query('SET LOCAL row_security = off;');

// Run seeds...

// Re-enable RLS
await queryRunner.query('SET LOCAL row_security = on;');
```

`SET LOCAL` scopes the change to the surrounding transaction, so a crash cannot
leave row security off. Prefer seeding as a role that the policies already admit.

### Production Safety

Production seeds MUST require confirmation.

```typescript
// CLI confirmation for production
if (process.env.NODE_ENV === 'production' && !args.includes('--confirm')) {
  console.error('ERROR: Production seeding requires --confirm flag');
  process.exit(1);
}
```

### Secrets and Credentials

- Seeds read passwords and API keys from the environment; never from a literal
- Nothing that runs in production has a default password baked in
- The dev credentials file is documentation for a throwaway database, and is
  excluded from production images
- Rotate the platform owner password immediately after the first production seed

---

## Testing

### Verify Database Schema

```bash
# Run verification before seeding
psql -U app -d app_dev -c "SELECT * FROM auth.verify_rls_enabled();"
```

### Test Login with Seeded Users

```bash
# Platform owner
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"owner@${SEED_DOMAIN}\", \"password\": \"${SEED_OWNER_PASSWORD}\"}"

# Test tenant admin
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"admin@${SEED_DOMAIN}\", \"password\": \"${SEED_DEV_PASSWORD}\"}"
```

### Verify Multi-Tenant Isolation

```sql
-- Log in as the tenant-one admin, then try to read tenant-two users.
-- RLS should return nothing.
SELECT * FROM auth.users WHERE tenant_id != 'tenant-one-id';
-- Returns 0 rows (RLS blocks cross-tenant access)
```

### Seed Verification Checklist

- [ ] Migrations ran before the seed (`npm run migration:show` is clean)
- [ ] Seed run is green end to end with `--verbose`
- [ ] Second consecutive run creates nothing new (idempotency proven)
- [ ] Row counts match expectations for tenants, users, roles, privileges
- [ ] Platform owner can log in
- [ ] A tenant admin can log in and sees only their own tenant
- [ ] Cross-tenant read returns 0 rows
- [ ] No test tenant or test user exists in staging or production
- [ ] No plaintext password anywhere in the database
- [ ] `SELECT * FROM auth.verify_rls_enabled()` reports every table enabled and forced

Row-count check after a development seed:

```bash
psql -h localhost -p 5432 -d app_dev -c "
SELECT 'tenants' AS table_name, COUNT(*) FROM auth.tenants
UNION ALL SELECT 'users', COUNT(*) FROM auth.users
UNION ALL SELECT 'roles', COUNT(*) FROM rbac.roles;
"
```

```text
 table_name | count
------------+-------
 tenants    |     4
 users      |    13
 roles      |    16
(3 rows)
```

---

## Troubleshooting

### Error: "Platform tenant not found"

**Cause:** seeds ran out of order.

**Fix:**

```bash
npm run seed:dev -- --force
```

### Error: "Database verification failed"

**Cause:** migrations not run, or the schema is incorrect.

**Fix:**

```bash
# Run migrations first
npm run migration:run

# Then seed
npm run seed:dev
```

### Error: "Unique violation on email"

**Cause:** trying to create a user that already exists.

**Fix:**

```bash
# Force re-seed (deletes and recreates)
npm run seed:force

# OR manually delete conflicting data
psql -U app -d app_dev -c "DELETE FROM auth.users WHERE email = '${SEED_OWNER_EMAIL}';"
```

### Error: "Permission denied for schema auth"

**Cause:** the database user lacks permissions.

**Fix:**

```sql
-- Grant permissions
GRANT ALL ON SCHEMA auth TO app;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO app;
```

### Error: "current transaction is aborted, commands ignored until end of transaction block"

**Cause:** an earlier statement in the single seeding transaction failed, and the
seeder kept issuing statements.

**Fix:** find the first error in the log, not the last. Wrap any statement that is
expected to fail in a savepoint:

```typescript
await queryRunner.query('SAVEPOINT seed_step');
try {
  await queryRunner.query(/* the risky statement */);
} catch {
  await queryRunner.query('ROLLBACK TO SAVEPOINT seed_step');
}
```

### Error: "new row violates row-level security policy"

**Cause:** the seeding role is subject to a policy that rejects the insert, usually
because no tenant context is set on the session.

**Fix:** set the claims the policy reads, for the transaction only:

```sql
SET LOCAL request.jwt.claims = '{"tenant_id":"<platform tenant uuid>","role":"platform_admin"}';
```

### Seeding hangs and never finishes

**Cause:** another connection holds a lock on a seeded table — commonly an open
`psql` session with an uncommitted transaction.

**Fix:**

```bash
psql -d app_dev -c "SELECT pid, state, query FROM pg_stat_activity WHERE state <> 'idle';"
```

---

## Reference Implementation

Three working files ship with this skill and can be copied into an API project
as-is:

| File | Purpose |
|---|---|
| [`reference/seeder.service.ts`](reference/seeder.service.ts) | Transactional seeder: phase logging, ordered seed lists, schema and RLS verification |
| [`reference/seeder.module.ts`](reference/seeder.module.ts) | The module that provides and exports `SeederService` |
| [`reference/cli.ts`](reference/cli.ts) | Command-line entry point: flag parsing, production guard, schema check, exit codes |

To adopt them:

```bash
# 1. Copy into the API app
mkdir -p src/database/seeds
cp reference/seeder.service.ts reference/seeder.module.ts reference/cli.ts src/database/seeds/

# 2. Register the module
#    imports: [SeederModule] in app.module.ts

# 3. Create the seed directories the service lists
mkdir -p src/database/seeds/001-system src/database/seeds/002-notifications src/database/seeds/003-dev-test

# 4. Wire the npm scripts from the section above, then run
npm run seed:dev -- --verbose
```

`cli.ts` expects `AppModule` two directories up (`../../app.module`); adjust the
import if the seeds live somewhere else.

---

## Best Practices

### DO

- Run migrations before seeds
- Use `--verbose` when debugging
- Review the dev credentials file for test account info
- Use `seed:force` to reset test data
- Verify RLS is enabled before seeding
- Keep the seed order explicit and dependency-ordered
- Make every seed idempotent, then prove it by running it twice
- Read every credential from the environment

### DON'T

- Run production seeds without `--confirm`
- Commit production credentials to version control
- Use test passwords in production
- Seed production with test data
- Disable RLS during seeding (security risk)
- Put schema changes in a seed — they belong in a migration
- Depend on filesystem ordering for seed order
- Let a seed silently swallow an error

---

## Related Skills

- [database-migrations](../database-migrations/SKILL.md) — schema changes that must run before any seed
- [database-backup](../database-backup/SKILL.md) — backup and restore around destructive reseeds
- [postgres-patterns](../postgres-patterns/SKILL.md) — query, index and RLS patterns
- [nestjs-patterns](../nestjs-patterns/SKILL.md) — module, provider and CLI wiring
