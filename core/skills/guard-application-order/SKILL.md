---
name: guard-application-order
description: The execution order of request guards - authentication, then tenant/context resolution, then authorization, then rate limiting - plus global vs controller vs route scope, what breaks when the order is wrong, and how to prove the real order at runtime. Use when adding or reviewing a guard, securing a new endpoint, or debugging a 401/403/empty-result that depends on guard sequence.
---

# Guard Application Order and Rules

Guards are the only thing standing between an unauthenticated request and your data, and
they are order-sensitive. A guard that runs one position too early reads a context that
does not exist yet; a guard that runs one position too late protects nothing. This skill
defines the canonical order, the scope rules that produce it, the failures each
misordering causes, and the commands that prove the real order at runtime.

## When to Activate

- Adding a new guard, or changing where an existing guard is registered
- Securing a new endpoint and choosing between public, session, machine, or dual auth
- Reviewing a pull request that touches `APP_GUARD`, `@UseGuards`, or a guard class
- Debugging a 401 on a route that should be public, or a 403 on a route the user can use
- Debugging an authorization check that reads an empty tenant or user context
- Debugging rate limiting that counts the wrong identity, or does not count at all
- Writing tests that assert the guard chain runs in the intended sequence
- Onboarding: answering "what actually protects this endpoint?"

---

## Overview

The API uses framework guards for authentication and authorization. This document defines
exactly **when** each guard runs, **where** it is registered, and **how** to apply each
guard type.

| Field | Value |
|---|---|
| Purpose | Define explicit rules for applying and ordering guards on API endpoints |
| Audience | Developers, automated agents, code reviewers |
| Status | Canonical platform rule |

---

## The Canonical Order

Every request passes through the chain in exactly this sequence. Each stage depends on
the stage before it having already run.

```text
Request
  -> 1. Authentication      (who is this?)
  -> 2. Context resolution  (which tenant / which row scope?)
  -> 3. Authorization       (may they do this?)
  -> 4. Rate limiting       (how often may they do this?)
  -> Controller
```

| # | Stage | Guard | Reads | Writes | Fails with |
|---|---|---|---|---|---|
| 1 | Authentication | `JwtAuthGuard` | `Authorization` header, session cookie | `request.user` | 401 Unauthorized |
| 2 | Context resolution | `RlsContextGuard` | `request.user` | `request.tenantId`, database row-level security context | 400 / 403 |
| 3 | Authorization | `PrivilegeGuard` | `request.user`, `@RequirePrivilege()` metadata | nothing | 403 Forbidden |
| 4 | Rate limiting | `RateLimitGuard` | `request.user`, `request.tenantId` | counter in cache | 429 Too Many Requests |

Why this order and no other:

1. **Authentication first.** Nothing downstream can key on an identity that has not been
   established. Every later stage reads `request.user`.
2. **Context resolution second.** Tenant isolation is a data-access concern, so it has to
   be set before any query runs, and it needs the identity from stage 1 to know which
   tenant to select.
3. **Authorization third.** A privilege check is meaningless without both the identity and
   the tenant scope. Checking privileges before tenant resolution lets a user's privilege
   in one tenant authorize an action in another.
4. **Rate limiting last.** A per-user or per-tenant limit needs the user and the tenant to
   key its counter on. A coarse per-IP throttle is a different thing entirely: it belongs
   in the edge proxy or in middleware ahead of the whole guard chain, because it must
   protect the login endpoint itself, which by definition has no identity yet.

---

## Scope Levels

The framework resolves guards by scope, and scope determines order:

```text
global guards (APP_GUARD, in registration order)
  -> controller guards (@UseGuards on the class, in argument order)
    -> route guards (@UseGuards on the method, in argument order)
      -> handler
```

| Scope | Declared as | Runs | Use for |
|---|---|---|---|
| Global | `{ provide: APP_GUARD, useClass: X }` in `app.module.ts` | First, in registration order | Rules that must hold for the whole API |
| Controller | `@UseGuards(X)` on the controller class | After all global guards | A whole surface with distinct auth (webhooks, machine API) |
| Route | `@UseGuards(X)` on the handler method | Last | One endpoint that differs from its controller |

Two consequences developers get wrong:

- **Registration order is the execution order for global guards.** Reordering the
  `APP_GUARD` providers in `app.module.ts` silently reorders the security chain. Treat
  that array as ordered configuration, not as a set.
- **A route-scoped guard can never run before a global guard.** If you need something to
  happen before authentication, it is middleware, not a guard.

---

## Guard Types

### 1. JwtAuthGuard - GLOBAL (Applied Automatically)

**Location:** `{{API_APP}}/src/modules/auth/guards/jwt-auth.guard.ts`

**Application:** GLOBAL - Applied to ALL routes by default

**Order position:** 1 of 4, first global guard registered

**Configured in:** `app.module.ts`

```typescript
{
  provide: APP_GUARD,
  useClass: JwtAuthGuard,
}
```

**Behavior:**
- Validates JWT tokens from `Authorization: Bearer <jwt>` header
- Populates `request.user` with decoded JWT payload
- Skips routes marked with `@Public()` decorator

**To Skip JWT Auth:**

```typescript
import { Public } from '@common/decorators/public.decorator';

@Public()
@Post('/auth/login')
async login() {
  // No JWT required
}
```

`@Public()` skips this guard only. Guards registered after it still execute, and must
themselves tolerate an absent `request.user`. A downstream guard that assumes a user
exists will throw a 500 on every public route.

---

### 2. RlsContextGuard - GLOBAL (Applied Automatically)

**Location:** `{{API_APP}}/src/common/guards/rls-context.guard.ts`

**Application:** GLOBAL - Applied to ALL routes

**Order position:** 2 of 4, after `JwtAuthGuard`, before `PrivilegeGuard`

**Configured in:** `app.module.ts`

```typescript
{
  provide: APP_GUARD,
  useClass: RlsContextGuard,
}
```

**Behavior:**
- Reads `request.user` from `JwtAuthGuard`
- Sets the database row-level security context for the connection
- Enables automatic tenant isolation
- Runs BEFORE `PrivilegeGuard`

**Developer Action:** None required (automatic)

This is the guard whose ordering is most often broken, because breaking it produces no
error. If it runs before authentication there is no user to derive a tenant from, the
context is set to null, and queries silently return zero rows or, worse, every row.

---

### 3. PrivilegeGuard - GLOBAL (Applied Automatically)

**Location:** `{{API_APP}}/src/common/guards/privilege.guard.ts`

**Application:** GLOBAL - Applied to ALL routes

**Order position:** 3 of 4, after context resolution

**Configured in:** `app.module.ts`

```typescript
{
  provide: APP_GUARD,
  useClass: PrivilegeGuard,
}
```

**Behavior:**
- Checks for `@RequirePrivilege()` decorator metadata
- Validates user has required privilege
- Allows platform owner bypass (unless disabled)
- Returns 403 Forbidden if privilege missing

**To Require Privilege:**

```typescript
import { RequirePrivilege } from '@common/decorators/require-privilege.decorator';

@Get('/users')
@RequirePrivilege('user:read')
async listUsers() {
  // Requires 'user:read' privilege
}
```

**Routes WITHOUT `@RequirePrivilege()`:**
- No privilege check performed
- Still get the row-level security context (tenant isolation)
- Accessible to all authenticated users

---

### 4. RateLimitGuard - GLOBAL (Applied Last)

**Location:** `{{API_APP}}/src/common/guards/rate-limit.guard.ts`

**Application:** GLOBAL - Applied to ALL routes

**Order position:** 4 of 4, the last global guard registered

**Configured in:** `app.module.ts`

```typescript
{
  provide: APP_GUARD,
  useClass: RateLimitGuard,
}
```

**Behavior:**
- Builds a counter key from `request.user` and `request.tenantId`
- Falls back to the client address when no identity is present
- Returns 429 Too Many Requests with a `Retry-After` header when the window is exhausted

Register it last so that rejected requests have already been identified and scoped. A
rate limiter registered first counts every caller as anonymous and shares one bucket
across your entire user base, so a single noisy client locks out everyone.

---

### 5. ApiKeyAuthGuard - OPT-IN (Manual Application Required)

**Location:** `{{API_APP}}/src/modules/auth/guards/api-key-auth.guard.ts`

**Application:** OPT-IN - NEVER applied globally

**Order position:** after every global guard, because route and controller guards always
run last

**CRITICAL RULE:**

This guard is **INTENTIONALLY** not global. You **MUST** explicitly apply it to each
endpoint that needs API key authentication.

**How to Enable:**

```typescript
import { UseGuards } from '@nestjs/common';
import { ApiKeyAuthGuard } from '@modules/auth/guards/api-key-auth.guard';

@Controller('server-to-server')
export class ServerController {
  @UseGuards(ApiKeyAuthGuard)
  @Get('/webhook-callback')
  async handleWebhook(@Req() req) {
    // API key authentication active
    // req.apiKey contains the validated ApiKey entity
    // req.tenantId contains tenant_id from the key
    // req.authType === 'api_key'
  }
}
```

**Behavior:**
- Validates `Authorization: Bearer sk_live_...` header
- Performs hash comparison against the stored key digest
- Checks revoked/expired/inactive status
- Updates usage metadata
- Sets the row-level security context for the tenant
- Attaches API key metadata to the request

**When to Use:**
- Server-to-server data sync endpoints
- External webhook callbacks
- Partner integration endpoints
- CI/CD automation endpoints
- Background job triggers

**When NOT to Use:**
- User-facing endpoints (use JWT)
- Frontend API calls (use JWT)
- Admin console endpoints (use JWT)
- Any endpoint that should not accept machine auth

**Rationale:**
1. **Security:** Prevents accidental exposure
2. **Separation:** Keeps human/machine auth distinct
3. **Control:** Allows per-endpoint decisions
4. **Clarity:** Explicit over implicit

Because this guard runs after the global chain, it has to set the tenant context itself.
That duplication is deliberate: the global context guard had no `request.user` to work
from on a machine-authenticated request.

---

## Guard Execution Order

**Global guards run in registration order:**

```text
Request -> JwtAuthGuard -> RlsContextGuard -> PrivilegeGuard -> RateLimitGuard -> Controller
```

1. **JwtAuthGuard** - Validates JWT, sets `request.user`
2. **RlsContextGuard** - Sets the row-level security context from `request.user`
3. **PrivilegeGuard** - Checks `@RequirePrivilege()` metadata
4. **RateLimitGuard** - Counts the request against the identified caller

**Route-specific guards** (like `@UseGuards(ApiKeyAuthGuard)`) run **AFTER** all global
guards.

**For API Key Routes:**

```text
Request
  -> JwtAuthGuard    (skips - no JWT)
  -> RlsContextGuard (skips - no user)
  -> PrivilegeGuard  (skips - no user)
  -> RateLimitGuard  (counts by client address)
  -> ApiKeyAuthGuard (authenticates, sets tenant context)
  -> Controller
```

**For Public Routes:**

```text
Request
  -> JwtAuthGuard    (skipped by @Public())
  -> RlsContextGuard (no user; sets no context)
  -> PrivilegeGuard  (no metadata; passes)
  -> RateLimitGuard  (counts by client address)
  -> Controller
```

Registration in `app.module.ts` is the single source of truth for this order:

```typescript
@Module({
  providers: [
    // ORDER IS SIGNIFICANT - see the guard application order rules.
    { provide: APP_GUARD, useClass: JwtAuthGuard },      // 1. authenticate
    { provide: APP_GUARD, useClass: RlsContextGuard },   // 2. resolve tenant context
    { provide: APP_GUARD, useClass: PrivilegeGuard },    // 3. authorize
    { provide: APP_GUARD, useClass: RateLimitGuard },    // 4. throttle
  ],
})
export class AppModule {}
```

---

## What Breaks When the Order Is Wrong

| Misordering | Visible symptom | Real cause | Fix |
|---|---|---|---|
| Context before authentication | Queries return zero rows for every authenticated user | `request.user` is undefined, so the tenant context is set to null | Register the auth guard first |
| Context before authentication (permissive fallback) | A user sees another tenant's data | Null context falls back to "no filter" instead of "no rows" | Register auth first, and make a null context deny |
| Authorization before context | User with a privilege in tenant A can act in tenant B | Privilege resolved without a tenant scope | Register the context guard before the privilege guard |
| Authorization before authentication | 403 instead of 401 on anonymous requests | Privilege check on an undefined user | Register auth first; let the auth guard own 401 |
| Rate limiting first | One noisy client throttles everyone | Every request keyed as anonymous, single shared bucket | Register the limiter last |
| Rate limiting first on login | Legitimate logins rejected during a burst | Shared anonymous bucket includes all unauthenticated traffic | Use a dedicated per-address limit at the edge for auth endpoints |
| Machine-auth guard registered globally | Every user-facing endpoint starts demanding an API key | The guard runs on routes that were never meant to accept it | Apply it per route only |
| Route guard expected to run first | Endpoint returns 401 before the route guard is reached | Route guards always run after global guards | Move the logic to middleware, or make the global guard tolerate it |

### Wrong and right: registration order

```typescript
// WRONG - context guard registered before authentication.
// Nothing throws. Queries just silently see the wrong scope.
providers: [
  { provide: APP_GUARD, useClass: RlsContextGuard },
  { provide: APP_GUARD, useClass: JwtAuthGuard },
  { provide: APP_GUARD, useClass: PrivilegeGuard },
]
```

```typescript
// CORRECT - authenticate, then scope, then authorize, then throttle.
providers: [
  { provide: APP_GUARD, useClass: JwtAuthGuard },
  { provide: APP_GUARD, useClass: RlsContextGuard },
  { provide: APP_GUARD, useClass: PrivilegeGuard },
  { provide: APP_GUARD, useClass: RateLimitGuard },
]
```

### Wrong and right: a guard that assumes its predecessor ran

```typescript
// WRONG - throws a 500 on every @Public() route, because request.user is undefined.
canActivate(context: ExecutionContext): boolean {
  const request = context.switchToHttp().getRequest();
  this.contextService.setTenant(request.user.tenantId);
  return true;
}
```

```typescript
// CORRECT - absence of a user is a valid state at this position in the chain.
canActivate(context: ExecutionContext): boolean {
  const request = context.switchToHttp().getRequest();
  const tenantId = request.user?.tenantId;
  if (!tenantId) {
    // No identity yet: leave the context unset so queries default to deny.
    return true;
  }
  this.contextService.setTenant(tenantId);
  return true;
}
```

### Wrong and right: rate limiting the wrong key

```typescript
// WRONG - registered first, so there is never a user to key on.
private buildKey(request: Request): string {
  return `rl:${request.ip}`;
}
```

```typescript
// CORRECT - registered last; prefers identity, falls back to address.
private buildKey(request: Request): string {
  const tenantId = request.tenantId;
  const userId = request.user?.sub;
  return userId ? `rl:t${tenantId}:u${userId}` : `rl:ip:${request.ip}`;
}
```

---

## Common Patterns

### Pattern 1: Public Route (No Auth)

```typescript
@Public()
@Post('/auth/login')
async login() {
  // Skips: JWT auth. Context, privilege and rate-limit guards still run.
}
```

### Pattern 2: Authenticated Route (JWT Only)

```typescript
@Get('/profile')
async getProfile(@Req() req) {
  // JWT auth required (global)
  // No privilege check
  // Tenant context set
}
```

### Pattern 3: Authenticated + Privilege Required

```typescript
@Get('/admin/users')
@RequirePrivilege('user:read')
async listUsers() {
  // JWT auth required
  // 'user:read' privilege required
  // Tenant context set
}
```

### Pattern 4: API Key Only

```typescript
@UseGuards(ApiKeyAuthGuard)
@Post('/external/webhook')
async handleWebhook(@Req() req) {
  // API key auth required
  // No user context
  // Tenant context set from the key
}
```

### Pattern 5: Dual Auth (JWT OR API Key)

```typescript
import { AnyAuthGuard } from '@auth/guards/any-auth.guard';

@UseGuards(AnyAuthGuard)
@Get('/flexible')
async flexibleEndpoint(@Req() req) {
  // Accepts either JWT or API key
  // Check req.authType to determine which was used
}
```

### Pattern 6: Whole Controller Behind Machine Auth

```typescript
// Controller-scoped guard: runs after every global guard,
// before any route-scoped guard on the same handler.
@UseGuards(ApiKeyAuthGuard)
@Controller('integrations')
export class IntegrationsController {
  @Post('/sync')
  async sync() {
    // Every route on this controller requires an API key.
  }
}
```

---

## Decision Matrix

**Use this flowchart to decide which guards to apply:**

```text
Is this a server-to-server endpoint?
│
├─ YES -> @UseGuards(ApiKeyAuthGuard)
│         Should it also accept JWT?
│         ├─ YES -> @UseGuards(AnyAuthGuard)
│         └─ NO  -> @UseGuards(ApiKeyAuthGuard) only
│
└─ NO -> Does it need authentication?
         │
         ├─ NO  -> @Public()
         │
         └─ YES -> Does it need specific privilege?
                  │
                  ├─ NO  -> (use the global JwtAuthGuard - no decorator needed)
                  │
                  └─ YES -> @RequirePrivilege('privilege:code')
```

---

## Validation Checklist

Before deploying any new endpoint:

- [ ] Determined correct auth type (public/JWT/API key/dual)
- [ ] Applied appropriate decorators
- [ ] If using `@UseGuards(ApiKeyAuthGuard)`, documented WHY in a code comment
- [ ] If using `@RequirePrivilege()`, the privilege exists in the database
- [ ] Tested authentication works correctly
- [ ] Tested authorization (privilege checks) work
- [ ] Verified the tenant context sets correctly
- [ ] No accidental exposure of sensitive data

Before merging any change to a guard or to `app.module.ts`:

- [ ] Global guard registration order is unchanged, or the change is justified in the PR
- [ ] Every guard reads only context written by a guard registered before it
- [ ] Every guard tolerates a missing `request.user` (public routes reach all of them)
- [ ] A null or missing tenant context denies access rather than widening it
- [ ] Rate limiting still keys on identity, not only on client address
- [ ] The runtime order was observed, not assumed (see the next section)
- [ ] An ordering test exists and fails if the registration order is changed

---

## Proving the Order at Runtime

Never assume the chain runs as written. Observe it.

### Temporary probe guard

Register a probe in each position while diagnosing, then remove it before merging.

```typescript
@Injectable()
export class GuardOrderProbe implements CanActivate {
  constructor(private readonly label: string, private readonly logger: Logger) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    this.logger.debug(
      `[guard-order] ${this.label} user=${request.user?.sub ?? 'none'} ` +
        `tenant=${request.tenantId ?? 'none'} authType=${request.authType ?? 'none'}`,
    );
    return true;
  }
}
```

A correct chain logs `user=none` at position 1 and a populated user at positions 2 to 4.

### Inspect the registered chain

```bash
# List the global guard registrations in declaration order
grep -n "APP_GUARD" -A 1 apps/api/src/app.module.ts

# Find every route-scoped or controller-scoped guard in the codebase
grep -rn "@UseGuards(" apps/api/src --include="*.ts"

# Find endpoints that opt into machine authentication
grep -rn "ApiKeyAuthGuard" apps/api/src --include="*.ts"

# Find public routes, which must survive every downstream guard
grep -rn "@Public()" apps/api/src --include="*.ts" | wc -l
```

### Observe a live request

```bash
# 1. Anonymous request to a protected route must fail at stage 1 with 401
curl -s -o /dev/null -w "%{http_code}\n" http://api.example.com/api/v1/users

# 2. Authenticated but unprivileged request must fail at stage 3 with 403
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $LOW_PRIVILEGE_JWT" \
  http://api.example.com/api/v1/users

# 3. Authenticated and privileged request must reach the controller with 200
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $ADMIN_JWT" \
  http://api.example.com/api/v1/users

# 4. Exhausting the window must fail at stage 4 with 429, not 401 or 403
for i in $(seq 1 120); do
  curl -s -o /dev/null -w "%{http_code} " \
    -H "Authorization: Bearer $ADMIN_JWT" \
    http://api.example.com/api/v1/users
done; echo

# 5. Machine credential on an opt-in route must reach the controller
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $API_KEY" \
  -X POST http://api.example.com/api/v1/external/webhook

# 6. Machine credential on a user-facing route must NOT be accepted
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $API_KEY" \
  http://api.example.com/api/v1/profile
```

The status codes are the proof. `401` means the chain stopped at authentication, `403` at
authorization, `429` at rate limiting. Getting `403` where you expected `401` is the
signature of an authorization guard that runs before authentication.

### Watch the guard chain in the logs

```bash
# Follow the API log and keep only guard decisions
tail -f logs/api.log | grep -E "guard-order|Unauthorized|Forbidden|Too Many"

# Confirm tenant context is set before any query runs
tail -f logs/api.log | grep -E "set_tenant_context|SELECT .* FROM"
```

### Lock the order with a test

```typescript
it('registers global guards in the canonical order', () => {
  const guards = moduleRef
    .get<Array<{ constructor: { name: string } }>>(APP_GUARD, { each: true });

  expect(guards.map((g) => g.constructor.name)).toEqual([
    'JwtAuthGuard',
    'RlsContextGuard',
    'PrivilegeGuard',
    'RateLimitGuard',
  ]);
});
```

```bash
# Run the ordering test on its own
npm test --workspace=apps/api -- --testPathPattern="guard-order"
```

This test is the reason a future reordering gets caught in review instead of in
production.

---

## Anti-Patterns

### WRONG: Applying ApiKeyAuthGuard Globally

```typescript
// NEVER DO THIS
{
  provide: APP_GUARD,
  useClass: ApiKeyAuthGuard,  // WRONG - breaks user endpoints
}
```

### WRONG: Assuming Guard is Global

```typescript
// WRONG - Guard won't be active
@Get('/webhook')
async handleWebhook(@Req() req) {
  // This endpoint does NOT have API key auth.
  // Must add @UseGuards(ApiKeyAuthGuard)
}
```

### WRONG: Mixing Auth Types Incorrectly

```typescript
// WRONG - This will try both guards and may behave unexpectedly
@UseGuards(JwtAuthGuard, ApiKeyAuthGuard)
@Get('/data')
async getData() {
  // Use AnyAuthGuard instead for dual auth
}
```

### WRONG: Reordering Global Guards to Silence an Error

```typescript
// WRONG - moving the privilege guard first "fixes" a crash by
// turning every anonymous 401 into a confusing 403, and the
// tenant context is never set before the check.
providers: [
  { provide: APP_GUARD, useClass: PrivilegeGuard },
  { provide: APP_GUARD, useClass: JwtAuthGuard },
  { provide: APP_GUARD, useClass: RlsContextGuard },
]
```

### CORRECT: Explicit Guard Application

```typescript
// CORRECT
@UseGuards(ApiKeyAuthGuard)
@Post('/external/webhook')
async handleWebhook(@Req() req) {
  // API key auth explicitly enabled
  // Purpose clear from decorator
}
```

---

## AI Agent Rules

**For all automated coding agents working in this repository:**

### MUST
- **NEVER** auto-apply `@UseGuards(ApiKeyAuthGuard)` without an explicit request
- **NEVER** suggest making `ApiKeyAuthGuard` global
- **NEVER** reorder the `APP_GUARD` registrations to make a test or an error go away
- **ALWAYS** ask before adding API key auth to any endpoint
- **ALWAYS** document WHY API key auth is needed in a code comment
- **ALWAYS** state which position in the chain a new guard occupies, and why

### MUST NOT
- Add `@UseGuards(ApiKeyAuthGuard)` to user-facing endpoints
- Remove `@UseGuards(ApiKeyAuthGuard)` from server-to-server endpoints
- Suggest global application patterns for opt-in guards
- Write a guard that reads context a later guard produces

### When Implementing New Endpoints

**Agent must ask:**
1. "Is this endpoint for server-to-server communication?"
2. "Should this accept API key authentication?"
3. "Should this ALSO accept JWT authentication (dual auth)?"

**Only add `@UseGuards(ApiKeyAuthGuard)` if answers are:**
1. YES
2. YES
3. NO (if YES to #3, use `AnyAuthGuard` instead)

### When Adding a New Guard

**Agent must answer, in the pull request description:**
1. Which stage does it belong to - authentication, context, authorization, or throttling?
2. What does it read from the request, and which guard wrote that?
3. What does it write to the request, and which guard consumes it?
4. What happens on a `@Public()` route where no user exists?
5. Which test proves its position in the chain?

---

## References

### Documentation

Point these at the equivalent documents in your own repository:

- **Platform spec:** `{{DOCS_DIR}}/platform/platform-master-spec.md` (auth and guards section)
- **System design:** `{{DOCS_DIR}}/system-design/security/api-keys.md`
- **Project rules:** `.claude/PROJECT_RULES.md` (auth and security section)

### Code

- **JwtAuthGuard:** `{{API_APP}}/src/modules/auth/guards/jwt-auth.guard.ts`
- **ApiKeyAuthGuard:** `{{API_APP}}/src/modules/auth/guards/api-key-auth.guard.ts`
- **RlsContextGuard:** `{{API_APP}}/src/common/guards/rls-context.guard.ts`
- **PrivilegeGuard:** `{{API_APP}}/src/common/guards/privilege.guard.ts`
- **RateLimitGuard:** `{{API_APP}}/src/common/guards/rate-limit.guard.ts`
- **Registration order:** `{{API_APP}}/src/app.module.ts`

### Examples

- **Auth module:** `{{API_APP}}/src/modules/auth/`
- **Webhooks module:** `{{API_APP}}/src/modules/webhooks/` (machine-auth use case)

---

## Related Skills

- [nestjs-patterns](../nestjs-patterns/SKILL.md) - guards, interceptors and module structure
- [security-review](../security-review/SKILL.md) - reviewing auth changes before they ship
- [api-design](../api-design/SKILL.md) - status codes and endpoint contracts
- [backend-patterns](../backend-patterns/SKILL.md) - request pipeline and layering
- [behavioral-testing](../behavioral-testing/SKILL.md) - proving the chain against a live API
- [error-handling](../error-handling/SKILL.md) - which stage owns which failure code

## In this pipeline

- Status: canonical platform rule. Applies to all API development.
- A change to guard registration order is a work order in its own right: open it with
  `wo new`, and record the before and after order in the SPEC.
- Verification means the curl probes and the ordering test actually ran.
  `NOT EXECUTED - PLAN ONLY` is an honest status; a typed `PASS` is not.
- Search the playbooks before debugging by trial and error:
  `playbook search "guard order"`.
