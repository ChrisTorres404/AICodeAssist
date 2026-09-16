# Test Accounts Registry — Template

**WO-NNNN | Created: YYYY-MM-DD | Environment: Development Only**

---

## How to use this template

Behavioural suites need accounts that exist, with known roles and known
states, or every run starts with somebody hand-making a user. This registry is
the shared list of those accounts: what exists, in which tenant, in which
state, and what each one is for.

1. Copy to `{{TESTING_DIR}}/TEST-ACCOUNTS-REGISTRY.md`.
2. Fill the tables from your seed script — not from the database by hand. The
   seed script is the source of truth; this document describes what it
   creates, so that regenerating the environment reproduces the registry.
3. Keep one row per account, with a stated purpose. An account nobody can
   explain gets deleted at the next cleanup.
4. Read the warning below before you type a single password into it.

Every value in this template is a placeholder. The addresses are all in
IANA-reserved example domains that can never receive mail, and the passwords
are of the deliberate shape `example-pass-N` so that nobody mistakes one for a
credential.

---

## WARNING: Development credentials only

These credentials are for **DEVELOPMENT and TESTING only**.
NEVER use these in production. NEVER commit real production credentials.

This file is committed to the repository and readable by everyone with access
to it. It is not a secret store, and it must never become one.

**Never put in this file:**

- A password, token, or key that works against production or staging
- A password a person also uses anywhere else
- A real customer's e-mail address, name, or tenant name
- A raw API key, client secret, or signing secret from any environment
- A live OAuth client secret — record the *shape* (`secret_{client_id}`), not the value

**Keeping secrets out of it:**

- Seed test accounts from a script that reads its passwords from environment
  variables, with the weak defaults used here only when the variable is unset:

  ```bash
  SEED_ADMIN_PASSWORD="${SEED_ADMIN_PASSWORD:-example-pass-1}"
  ```

- Keep the real values in the environment's secret manager, or in a
  `.env.local` that is listed in `.gitignore` and never committed.
- Give test accounts passwords that are obviously test passwords. A test
  password that looks plausible will eventually be reused somewhere real.
- Scope the whole environment: test accounts exist only in the development
  database, and the seed script refuses to run against any other.
- Run a secret scanner in the pre-commit hook and in CI, so a key pasted into
  this file is caught before it is pushed.
- If a real credential does land here, treat it as disclosed: rotate it first,
  then rewrite the history. Deleting the line is not a fix.

---

## Tenant Overview

| Tenant | Slug | Tier | Subdomain | Domain | Account ID | Tenant ID |
|--------|------|------|-----------|--------|------------|-----------|
| Tenant One | tenant-one | pro | tenant-one | tenant-one.example.com | 26 | 29 |
| Tenant Two | tenant-two | enterprise | tenant-two | tenant-two.example.org | 102 | 105 |

---

## Primary Accounts (6 Users)

One account per role, per tenant: the accounts a suite logs in as by default.

### Tenant One (Pro Tier)

| Email | Password | user_type | RBAC Role | Tenant Role | Purpose |
|-------|----------|-----------|-----------|-------------|---------|
| admin@example.com | example-pass-1 | tenant_admin | tenant_admin | owner | Tenant owner, full admin access |
| member@example.com | example-pass-2 | app_user | member | member | Client/customer-plane testing |
| owner@example.com | example-pass-3 | tenant_admin | member | admin | Admin-plane RBAC testing |

### Tenant Two (Enterprise Tier)

| Email | Password | user_type | RBAC Role | Tenant Role | Purpose |
|-------|----------|-----------|-----------|-------------|---------|
| admin@example.org | example-pass-1 | tenant_admin | tenant_admin | owner | Enterprise tenant owner |
| member@example.org | example-pass-2 | app_user | member | member | Enterprise app user testing |
| owner@example.org | example-pass-3 | tenant_admin | tenant_admin | admin | Enterprise admin testing |

---

## Edge-Case Test Users

One account per account state, so that a suite never has to mutate a shared
account into the state it needs.

### Tenant One Edge Cases (8 Users)

| Email | Password | user_type | auth_status | Special |
|-------|----------|-----------|-------------|---------|
| viewer@example.com | example-pass-4 | app_user | ACTIVE | viewer RBAC role |
| mfa-totp@example.com | example-pass-5 | app_user | ACTIVE | mfa_enabled=true |
| mfa-pending@example.com | example-pass-6 | app_user | PENDING_MFA_SETUP | Must enroll MFA before login |
| unverified@example.com | example-pass-7 | app_user | PENDING_EMAIL_VERIFICATION | Email not verified |
| suspended@example.com | example-pass-8 | app_user | SUSPENDED | Account suspended |
| disabled@example.com | example-pass-9 | app_user | DISABLED | Account disabled, is_active=false |
| locked@example.com | example-pass-10 | app_user | ACTIVE | is_locked=true |
| multi-tenant@example.com | example-pass-11 | tenant_admin | ACTIVE | Member of BOTH tenant-one and tenant-two |

### Tenant Two Edge Cases (4 Users)

| Email | Password | user_type | auth_status | Special |
|-------|----------|-----------|-------------|---------|
| security@example.org | example-pass-12 | tenant_admin | ACTIVE | viewer RBAC, Security Team group |
| auditor@example.org | example-pass-13 | app_user | ACTIVE | viewer RBAC, audit log viewer |
| contractor@example.org | example-pass-14 | app_user | ACTIVE | Contractors group, attribute-restricted |
| suspended@example.org | example-pass-15 | app_user | SUSPENDED | Suspended enterprise user |

---

## Service Accounts (2 Users)

Machine identities. They have no password: they authenticate with a credential
issued at seed time and printed once to the seed log.

| Email | user_type | Tenant | Purpose |
|-------|-----------|--------|---------|
| sync-service@service.example.com | service_account | tenant-one | Automated sync |
| ci-pipeline@service.example.org | service_account | tenant-two | CI/CD pipeline |

---

## OAuth Clients

Publishable keys are safe to write down — that is what "publishable" means.
Client secrets are not: record the pattern the seed script uses, never a value.

### Public Clients (PKCE)

| Publishable Key | Tenant | Name | Grant Types |
|-----------|--------|------|-------------|
| pk_test_EXAMPLE_PUBLIC_CLIENT_ONE | tenant-one | Tenant One Web App | authorization_code, refresh_token |
| pk_test_EXAMPLE_PUBLIC_CLIENT_TWO | tenant-two | Tenant Two Web App | authorization_code, refresh_token |

### Confidential Clients (M2M)

| Publishable Key | Tenant | Name | Grant Types | Secret Pattern |
|-----------|--------|------|-------------|----------------|
| pk_test_EXAMPLE_CONFIDENTIAL_ONE | tenant-one | Tenant One Backend Service | client_credentials | secret_{client_id} |
| pk_test_EXAMPLE_CONFIDENTIAL_TWO | tenant-two | Tenant Two M2M Service | client_credentials | secret_{client_id} |

---

## API Keys

| Tenant | Key Name | Notes |
|--------|----------|-------|
| tenant-one | Tenant One Default API Key | Raw key logged during seed run; never written here |
| tenant-two | Tenant Two Default API Key | Raw key logged during seed run; never written here |

---

## Attribute-Based Policies (Tenant Two)

| Policy | Effect | Resources | Actions |
|--------|--------|-----------|---------|
| Deny Contractors Audit Access | DENY | audit:* | read, list, export |
| Allow Security Team Full Auth | ALLOW | auth:*, users:* | * |

---

## Groups

### Tenant One (7 pre-existing)
Engineering, Product, Marketing, Support, Backend, Frontend, DevOps

### Tenant Two (4 created by the seed script)
All Employees, Security Team, Engineering, Contractors

---

## Proxy URLs for Testing

Subdomain routing through the local reverse proxy. See
`PORT-ALLOCATION-STANDARD.md` in this directory for the port scheme.

| URL | Service |
|-----|---------|
| http://tenant-one.example.com | Tenant One portal (via the proxy) |
| http://tenant-two.example.com | Tenant Two portal (via the proxy) |
| http://api.example.com | API (via the proxy) |

---

## Quick Login Commands

```bash
# Tenant One admin (owner)
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "example-pass-1"}'

# Tenant One member
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "member@example.com", "password": "example-pass-2"}'

# Tenant Two admin (owner)
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.org", "password": "example-pass-1"}'

# Tenant Two member
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "member@example.org", "password": "example-pass-2"}'
```

In a suite, read the password from the environment instead of inlining it:

```bash
: "${TEST_ADMIN_EMAIL:=admin@example.com}"
: "${TEST_ADMIN_PASSWORD:=example-pass-1}"

curl -sS -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_ADMIN_EMAIL\", \"password\": \"$TEST_ADMIN_PASSWORD\"}"
```

---

## Verification Queries

```sql
-- All users created by this seed run
SELECT email, user_type, auth_status, is_locked, mfa_enabled, is_active
FROM core.users
WHERE public_metadata->>'wo' = 'NNNN'
ORDER BY email;

-- Primary accounts
SELECT email, user_type, auth_status
FROM core.users
WHERE email IN (
  'admin@example.com','member@example.com','owner@example.com',
  'admin@example.org','member@example.org','owner@example.org'
)
ORDER BY email;

-- Tenant Two provisioning status
SELECT
  (SELECT plan FROM core.accounts WHERE id = 102) as account_plan,
  (SELECT subscription_tier FROM core.tenants WHERE id = 105) as tenant_tier,
  (SELECT domain FROM core.tenant_domains WHERE tenant_id = 105 LIMIT 1) as domain,
  (SELECT COUNT(*) FROM core.oauth_clients WHERE tenant_id = 105 AND deleted_at IS NULL) as oauth_clients,
  (SELECT COUNT(*) FROM core.groups WHERE tenant_id = 105 AND deleted_at IS NULL) as groups,
  (SELECT COUNT(*) FROM settings.tenant_settings WHERE tenant_id = 105) as settings;
```

---

## Maintenance

- [ ] Every account in this registry is created by the seed script
- [ ] Every account has a stated purpose
- [ ] No password here works in any environment except local development
- [ ] No real customer data appears anywhere in the file
- [ ] No raw API key, client secret, or signing secret appears in the file
- [ ] The file is covered by the repository's secret scanner
- [ ] Removed accounts are removed from the seed script and from this table together

---

**Last Updated:** YYYY-MM-DD
**Work Order:** WO-NNNN
