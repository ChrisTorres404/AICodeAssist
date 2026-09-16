---
name: sdk-standards
description: Engineering standards for a client SDK — layered architecture, HTTP client behaviour, typed error model, cookie and token handling, React and framework adapters, bundle budgets, testing, documentation, and release policy. Use when designing, implementing, reviewing, or releasing an SDK or client library for a platform API.
---

# SDK Standards

The authoritative standard for every client SDK the platform ships. It covers how the
client is constructed, how requests are made and retried, how errors are typed and
surfaced, how sessions and tokens are handled, how framework adapters behave, what the
bundle may cost, how it is tested and documented, and how it is released.

Every SDK implementation MUST comply with these standards. Where a section says MUST,
a reviewer should block the change; where it says SHOULD, a deviation needs a reason
recorded in the pull request.

## When to Activate

- Designing or scaffolding a new SDK package or client library
- Adding or changing a resource namespace, HTTP behaviour, or retry policy
- Writing or refactoring the SDK error hierarchy, or mapping API responses to errors
- Implementing login, session refresh, CSRF, or logout in a client
- Building React hooks, a provider, or a framework adapter (Next.js, Remix, SvelteKit, Node)
- Reviewing an SDK pull request, or auditing an existing SDK against the standard
- Planning a release: versioning, changelog, deprecation, or a breaking change
- Investigating SDK bundle size, request duplication, or refresh storms

## Contents

| Section | Topic |
|---|---|
| [Placeholders](#placeholders-and-naming-conventions) | Names and tokens used throughout |
| [Executive Summary](#executive-summary) | What every SDK optimises for |
| [1](#1-architecture-principles) | Architecture principles |
| [2](#2-http-client-standards) | HTTP client standards |
| [3](#3-error-handling-standards) | Error handling standards |
| [4](#4-authentication-standards) | Authentication standards |
| [5](#5-react-integration-standards) | React integration standards |
| [6](#6-performance-standards) | Performance standards |
| [7](#7-security-standards) | Security standards |
| [8](#8-testing-standards) | Testing standards |
| [9](#9-documentation-standards) | Documentation standards |
| [10](#10-release-standards) | Release standards |
| [11](#11-framework-adapters) | Framework adapters |
| [Appendix A](#appendix-a-file-structure) | File structure |
| [Appendix B](#appendix-b-capability-baseline) | Capability baseline |
| [Appendix C](#appendix-c-review-checklists) | Review checklists |

## Placeholders and Naming Conventions

Substitute the project's own names for these tokens. They are used consistently in every
example below so that the examples remain runnable once substituted.

| Token | Meaning | Example value |
|---|---|---|
| `{{SDK_PKG}}` | Monorepo path of the core SDK package | `packages/sdk` |
| `@{{PROJECT_SLUG}}/sdk` | Published npm name of the core SDK | `@app/sdk` |
| `{{PROJECT_DOMAIN}}` | Public domain of the platform | `example.com` |
| `PlatformClient` | The SDK's root client class | — |
| `SdkError` | Base error class exported by the SDK | — |
| `AuthProvider` / `AuthContext` | React provider and context | — |
| `<prefix>-` | Cookie name prefix, one word, lowercase | `app-` |
| `APP_SDK__` | Environment variable prefix for SDK config | — |

**Cookie naming convention.** All SDK cookies share a single lowercase prefix followed by
a hyphen, so that a browser's cookie list groups them and a proxy can match them with one
pattern. The standard set is:

| Cookie | Flags | Purpose |
|---|---|---|
| `app-session` | HttpOnly, Secure, SameSite=Lax | Short-lived access/session token |
| `app-refresh` | HttpOnly, Secure, SameSite=Lax, narrow `Path` | Refresh token |
| `app-csrf-token` | Secure, SameSite=Lax, readable by JS | Double-submit CSRF value |

Only `app-csrf-token` is readable from JavaScript; the other two MUST be HttpOnly.

## Executive Summary

These standards are enterprise-grade baselines for the performance, security, and
developer experience of every client SDK the platform publishes.

**Primary Goals:**

1. **Developer experience** — intuitive APIs that are obvious without reading source
2. **Security** — zero-trust, defence in depth, no token ever reachable from script
3. **Performance** — minimal overhead, minimal bundle, minimal network chatter
4. **Reliability** — graceful degradation, automatic recovery from transient failure
5. **Maintainability** — clean layering, comprehensive tests, no hidden global state

---

## 1. Architecture Principles

### 1.1 Modular Design

```text
┌─────────────────────────────────────────────────────────────────┐
│                         SDK PUBLIC API                          │
├─────────────────────────────────────────────────────────────────┤
│  client.auth    │  client.users    │  client.tenants   │  ...  │
├─────────────────────────────────────────────────────────────────┤
│                       RESOURCE LAYER                            │
│         (AuthResource, UsersResource, TenantsResource)          │
├─────────────────────────────────────────────────────────────────┤
│                       HTTP CLIENT LAYER                         │
│    (Request Building, Retry Logic, Error Handling, Caching)     │
├─────────────────────────────────────────────────────────────────┤
│                       TRANSPORT LAYER                           │
│              (Fetch Abstraction, Cookie Management)             │
└─────────────────────────────────────────────────────────────────┘
```

**Rules:**
- Each layer has a single responsibility
- Dependencies flow downward only (no circular dependencies)
- Resource classes are pure data transformers (no business logic)
- HTTP layer handles ALL network concerns (retries, timeouts, errors)
- Transport layer is pluggable (browser fetch, Node fetch, custom)

### 1.2 Client Instantiation

```typescript
// GOOD: Single client instance, explicit configuration
const client = new PlatformClient({
  baseUrl: 'https://api.example.com',
  // Authentication (mutually exclusive)
  apiKey: 'sk_live_xxx',              // Server-side
  // OR
  useCookies: true,                   // Browser-side (HttpOnly cookies)

  // Optional configuration
  timeout: 30000,                     // Request timeout (ms)
  maxRetries: 3,                      // Automatic retry count
  debug: false,                       // Enable debug logging
});

// Access resources via namespaces
await client.auth.login({ email, password });
await client.users.getMe();
await client.tenants.list();
```

**Rules:**
- Single client instance per application
- All configuration at instantiation time
- Resource namespaces for logical grouping
- No global state or singletons
- Configuration is immutable after creation

### 1.3 Zero-Configuration Defaults

Every SDK option MUST have a sensible default:

| Option | Default | Rationale |
|--------|---------|-----------|
| `timeout` | 30000ms | Balance between fast failures and slow networks |
| `maxRetries` | 3 | Handles transient failures without infinite loops |
| `retryDelay` | 1000ms (base) | Exponential backoff starting point |
| `debug` | false | No production log leakage |
| `apiVersion` | 'v1' | Latest stable API version |
| `useCookies` | true in browser, false in Node | Matches the safe mode for each runtime |

### 1.4 Configuration Precedence and Environment Variables

Explicit constructor options always win. Environment variables are a fallback for
server-side usage, so that a deployment can be reconfigured without a rebuild.

Precedence, highest first:

1. Option passed to `new PlatformClient({ ... })`
2. Environment variable with the `APP_SDK__` prefix
3. Built-in default from the table in 1.3

| Environment variable | Maps to option |
|---|---|
| `APP_SDK__BASE_URL` | `baseUrl` |
| `APP_SDK__API_KEY` | `apiKey` |
| `APP_SDK__API_VERSION` | `apiVersion` |
| `APP_SDK__TIMEOUT` | `timeout` (milliseconds) |
| `APP_SDK__MAX_RETRIES` | `maxRetries` |
| `APP_SDK__DEBUG` | `debug` (`1`/`true` enables) |

```typescript
// Resolution happens once, at construction. Never read process.env at request time.
function resolveConfig(options: ClientOptions): ResolvedConfig {
  const env = typeof process !== 'undefined' ? process.env : ({} as NodeJS.ProcessEnv);

  return {
    baseUrl: options.baseUrl ?? env.APP_SDK__BASE_URL ?? 'https://api.example.com',
    apiKey: options.apiKey ?? env.APP_SDK__API_KEY,
    apiVersion: options.apiVersion ?? env.APP_SDK__API_VERSION ?? 'v1',
    timeout: options.timeout ?? numberFromEnv(env.APP_SDK__TIMEOUT) ?? 30000,
    maxRetries: options.maxRetries ?? numberFromEnv(env.APP_SDK__MAX_RETRIES) ?? 3,
    debug: options.debug ?? boolFromEnv(env.APP_SDK__DEBUG) ?? false,
    useCookies: options.useCookies ?? typeof document !== 'undefined',
  };
}
```

`APP_SDK__API_KEY` MUST NOT be read in a browser bundle. Bundlers that inline
`process.env` are required to allowlist only the non-secret keys above.

---

## 2. HTTP Client Standards

### 2.1 Request Lifecycle

```text
┌──────────────────────────────────────────────────────────────────────┐
│                          REQUEST LIFECYCLE                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. PREPARE        2. EXECUTE         3. HANDLE          4. RETURN   │
│  ┌─────────┐      ┌─────────┐       ┌─────────┐       ┌─────────┐   │
│  │ Build   │ ──▶  │ Fetch   │ ──▶   │ Parse   │ ──▶   │ Return  │   │
│  │ Request │      │ + Retry │       │ Response│       │ Data    │   │
│  └─────────┘      └─────────┘       └─────────┘       └─────────┘   │
│       │                │                 │                  │        │
│       ▼                ▼                 ▼                  ▼        │
│  - URL building   - Timeout        - Status check     - Type-safe   │
│  - Headers        - Retry logic    - Error mapping    - Validated   │
│  - Body JSON      - Deduplication  - JSON parsing     - Transformed │
│  - Auth tokens    - Circuit break  - Validation                      │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.2 URL Building

```typescript
// GOOD: Centralized path building with API versioning
function buildUrl(baseUrl: string, path: string, version: string = 'v1'): string {
  // Normalize path (remove leading slash)
  const normalizedPath = path.startsWith('/') ? path.slice(1) : path;

  // Build versioned path
  const versionedPath = normalizedPath.startsWith('v')
    ? normalizedPath  // Already versioned
    : `${version}/${normalizedPath}`;

  // Combine with base URL
  return `${baseUrl.replace(/\/$/, '')}/${versionedPath}`;
}

// Examples:
// buildUrl('https://api.example.com', '/auth/login')
// → 'https://api.example.com/v1/auth/login'
// buildUrl('https://api.example.com/', 'v2/users/me')
// → 'https://api.example.com/v2/users/me'
```

### 2.3 Automatic Retries

```typescript
interface RetryConfig {
  maxRetries: number;      // Default: 3
  baseDelay: number;       // Default: 1000ms
  maxDelay: number;        // Default: 30000ms
  retryableStatuses: number[];  // Default: [408, 429, 500, 502, 503, 504]
  retryableErrors: string[];    // Default: ['ETIMEDOUT', 'ECONNRESET', 'ECONNREFUSED']
}

async function fetchWithRetry(
  url: string,
  init: RequestInit,
  config: RetryConfig
): Promise<Response> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
    try {
      const response = await fetch(url, init);

      // Success or non-retryable error
      if (!config.retryableStatuses.includes(response.status)) {
        return response;
      }

      // Retryable status - check for Retry-After header
      const retryAfter = response.headers.get('Retry-After');
      const delay = retryAfter
        ? parseInt(retryAfter) * 1000
        : calculateBackoff(attempt, config);

      await sleep(delay);
    } catch (error) {
      lastError = error as Error;

      // Check if error is retryable
      if (!isRetryableError(error, config)) {
        throw error;
      }

      await sleep(calculateBackoff(attempt, config));
    }
  }

  throw new NetworkError('Max retries exceeded', lastError);
}

// Exponential backoff with jitter (prevents thundering herd)
function calculateBackoff(attempt: number, config: RetryConfig): number {
  const exponentialDelay = config.baseDelay * Math.pow(2, attempt);
  const jitter = Math.random() * 0.3 * exponentialDelay; // 0-30% jitter
  return Math.min(exponentialDelay + jitter, config.maxDelay);
}
```

Only idempotent methods (GET, HEAD, PUT, DELETE) are retried automatically. A POST is
retried only when it carries an idempotency key (see 2.5).

### 2.4 Request Deduplication

```typescript
// Prevent duplicate in-flight requests (especially for GET)
class RequestDeduplicator {
  private pending = new Map<string, Promise<Response>>();

  async dedupe(key: string, executor: () => Promise<Response>): Promise<Response> {
    // Check for existing request
    const existing = this.pending.get(key);
    if (existing) {
      return existing;
    }

    // Create new request
    const promise = executor();
    this.pending.set(key, promise);

    try {
      return await promise;
    } finally {
      this.pending.delete(key);
    }
  }

  generateKey(method: string, url: string, body?: unknown): string {
    let key = `${method}:${url}`;
    if (body && method === 'POST') {
      key += `:${hashBody(body)}`;
    }
    return key;
  }
}

// Deduplication rules:
// - GET: Always dedupe (idempotent)
// - POST: Dedupe only for whitelisted endpoints (e.g., /session/validate)
// - PUT/PATCH/DELETE: Never dedupe (not idempotent)
```

### 2.5 Idempotency Keys

```typescript
// For mutation operations, support idempotency keys
interface MutationOptions {
  idempotencyKey?: string;  // Client-provided or auto-generated UUID
}

async function post<T>(
  path: string,
  body: unknown,
  options?: MutationOptions
): Promise<T> {
  const headers: Record<string, string> = {};

  if (options?.idempotencyKey) {
    headers['Idempotency-Key'] = options.idempotencyKey;
  }

  return this.request({ method: 'POST', path, body, headers });
}

// Usage:
await client.licenses.create(
  { tier: 'enterprise' },
  { idempotencyKey: 'create-license-abc123' }
);
```

### 2.6 Timeouts and Cancellation

Every request MUST be abortable, and every request MUST have a deadline. A caller's own
`AbortSignal` is composed with the SDK's timeout signal so that neither one is lost.

```typescript
interface RequestOptions {
  signal?: AbortSignal;   // Caller cancellation (e.g. React effect cleanup)
  timeout?: number;       // Per-request override of the client default
}

function withDeadline(
  timeoutMs: number,
  callerSignal?: AbortSignal
): { signal: AbortSignal; dispose: () => void } {
  const controller = new AbortController();
  const timer = setTimeout(
    () => controller.abort(new TimeoutError(`Request exceeded ${timeoutMs}ms`)),
    timeoutMs
  );

  const onAbort = () => controller.abort(callerSignal?.reason);
  callerSignal?.addEventListener('abort', onAbort, { once: true });

  return {
    signal: controller.signal,
    dispose: () => {
      clearTimeout(timer);
      callerSignal?.removeEventListener('abort', onAbort);
    },
  };
}
```

**Rules:**
- A timeout produces a `TimeoutError` (retryable), not a bare `AbortError`
- A caller-initiated abort is never retried and never reported as a failure metric
- `dispose()` runs in a `finally` block so timers cannot leak

---

## 3. Error Handling Standards

### 3.1 Error Hierarchy

```typescript
// Base error class with rich context
export class SdkError extends Error {
  readonly code: string;           // Machine-readable error code
  readonly statusCode?: number;    // HTTP status if applicable
  readonly requestId?: string;     // For support/debugging
  readonly retryable: boolean;     // Can this be retried?
  readonly userMessage: string;    // Safe for end-user display

  constructor(params: SdkErrorParams) {
    super(params.message);
    this.name = 'SdkError';
    this.code = params.code;
    this.statusCode = params.statusCode;
    this.requestId = params.requestId;
    this.retryable = params.retryable ?? false;
    this.userMessage = params.userMessage ?? 'An error occurred';
  }
}

// Specific error types (for instanceof checks)
export class AuthenticationError extends SdkError {
  constructor(params: Omit<SdkErrorParams, 'code'>) {
    super({ ...params, code: 'authentication_error', retryable: false });
    this.name = 'AuthenticationError';
  }
}

export class UnauthorizedError extends AuthenticationError {
  constructor(message: string, requestId?: string) {
    super({
      message,
      statusCode: 401,
      requestId,
      userMessage: 'Your session has expired. Please log in again.',
    });
    this.name = 'UnauthorizedError';
  }
}

export class ForbiddenError extends AuthenticationError {
  constructor(message: string, requestId?: string) {
    super({
      message,
      statusCode: 403,
      requestId,
      userMessage: 'You do not have permission to perform this action.',
    });
    this.name = 'ForbiddenError';
  }
}

export class ValidationError extends SdkError {
  readonly field?: string;
  readonly errors?: Record<string, string[]>;

  constructor(params: ValidationErrorParams) {
    super({ ...params, code: 'validation_error', retryable: false });
    this.name = 'ValidationError';
    this.field = params.field;
    this.errors = params.errors;
  }
}

export class RateLimitError extends SdkError {
  readonly retryAfter: number;  // Seconds until retry is allowed

  constructor(retryAfter: number, requestId?: string) {
    super({
      message: `Rate limit exceeded. Retry after ${retryAfter} seconds.`,
      code: 'rate_limit_error',
      statusCode: 429,
      requestId,
      retryable: true,
      userMessage: 'Too many requests. Please wait a moment and try again.',
    });
    this.name = 'RateLimitError';
    this.retryAfter = retryAfter;
  }
}

export class NetworkError extends SdkError {
  constructor(message: string, cause?: Error) {
    super({
      message,
      code: 'network_error',
      retryable: true,
      userMessage: 'Unable to connect. Please check your internet connection.',
    });
    this.name = 'NetworkError';
    this.cause = cause;
  }
}

export class TimeoutError extends SdkError {
  constructor(message: string) {
    super({
      message,
      code: 'timeout',
      retryable: true,
      userMessage: 'Request timed out. Please try again.',
    });
    this.name = 'TimeoutError';
  }
}

export class ServerError extends SdkError {
  constructor(message: string, statusCode: number, requestId?: string) {
    super({
      message,
      code: 'server_error',
      statusCode,
      requestId,
      retryable: true,
      userMessage: 'Something went wrong on our end. Please try again later.',
    });
    this.name = 'ServerError';
  }
}
```

The hierarchy at a glance:

| Class | Extends | Code | HTTP | Retryable |
|---|---|---|---|---|
| `SdkError` | `Error` | varies | varies | varies |
| `AuthenticationError` | `SdkError` | `authentication_error` | 401/403 | No |
| `UnauthorizedError` | `AuthenticationError` | `authentication_error` | 401 | No |
| `ForbiddenError` | `AuthenticationError` | `authentication_error` | 403 | No |
| `ValidationError` | `SdkError` | `validation_error` | 400/422 | No |
| `RateLimitError` | `SdkError` | `rate_limit_error` | 429 | Yes |
| `NetworkError` | `SdkError` | `network_error` | — | Yes |
| `TimeoutError` | `SdkError` | `timeout` | — | Yes |
| `ServerError` | `SdkError` | `server_error` | 5xx | Yes |

### 3.2 Response Error Mapping

```typescript
function mapResponseToError(response: Response, body: unknown): SdkError {
  const requestId = response.headers.get('X-Request-Id') ?? undefined;
  const errorBody = body as { message?: string; code?: string; errors?: unknown };

  switch (response.status) {
    case 400:
      return new ValidationError({
        message: errorBody.message ?? 'Invalid request',
        statusCode: 400,
        requestId,
        userMessage: 'Please check your input and try again.',
        errors: errorBody.errors as Record<string, string[]>,
      });

    case 401:
      return new UnauthorizedError(
        errorBody.message ?? 'Authentication required',
        requestId
      );

    case 403:
      return new ForbiddenError(
        errorBody.message ?? 'Access denied',
        requestId
      );

    case 404:
      return new SdkError({
        message: errorBody.message ?? 'Resource not found',
        code: 'not_found',
        statusCode: 404,
        requestId,
        retryable: false,
        userMessage: 'The requested resource was not found.',
      });

    case 429:
      const retryAfter = parseInt(response.headers.get('Retry-After') ?? '60');
      return new RateLimitError(retryAfter, requestId);

    case 500:
    case 502:
    case 503:
    case 504:
      return new ServerError(
        errorBody.message ?? 'Internal server error',
        response.status,
        requestId
      );

    default:
      return new SdkError({
        message: errorBody.message ?? `HTTP ${response.status}`,
        code: 'unknown_error',
        statusCode: response.status,
        requestId,
        retryable: response.status >= 500,
        userMessage: 'An unexpected error occurred.',
      });
  }
}
```

### 3.3 User-Friendly Error Messages

```typescript
// Centralized error message mapping for end-user display
const USER_MESSAGES: Record<string, string> = {
  // Authentication
  'invalid_credentials': 'Invalid email or password.',
  'session_expired': 'Your session has expired. Please log in again.',
  'mfa_required': 'Please complete two-factor authentication.',
  'account_locked': 'Your account has been locked. Please contact support.',
  'admin_access_denied': 'Admin console access is restricted to platform administrators.',

  // Authorization
  'forbidden': 'You do not have permission to perform this action.',
  'tenant_access_denied': 'You do not have access to this organization.',

  // Validation
  'email_invalid': 'Please enter a valid email address.',
  'password_weak': 'Password must be at least 8 characters with uppercase, lowercase, and numbers.',
  'field_required': 'This field is required.',

  // Rate Limiting
  'rate_limited': 'Too many attempts. Please wait a moment and try again.',

  // Network
  'network_error': 'Unable to connect. Please check your internet connection.',
  'timeout': 'Request timed out. Please try again.',

  // Server
  'server_error': 'Something went wrong on our end. Please try again later.',
};

export function getUserFriendlyMessage(error: SdkError): string {
  // First check for specific code mapping
  if (error.code && USER_MESSAGES[error.code]) {
    return USER_MESSAGES[error.code];
  }

  // Fall back to error's userMessage
  return error.userMessage;
}
```

### 3.4 Error Handling Rules

- Every failure path throws an `SdkError` subclass. The SDK never throws a raw `Error`,
  never returns `null` to signal failure, and never resolves with an `{ ok: false }` shape.
- `message` is for engineers (logs, traces). `userMessage` is the only string that may be
  rendered to an end user. A `message` MUST NOT contain a token, password, or secret.
- `requestId` is populated from `X-Request-Id` whenever the response carries one, so that
  a support ticket can be joined to a server-side trace.
- `retryable` is decided at construction, not at the call site. Callers branch on the
  flag; they do not re-derive it from the status code.
- Callers discriminate with `instanceof`, so every subclass sets `this.name` explicitly
  (transpiled class hierarchies otherwise collapse the name).

```typescript
// Worked example: a caller handling the full hierarchy
try {
  await client.users.update(userId, { name });
} catch (error) {
  if (error instanceof ValidationError) {
    setFieldErrors(error.errors ?? {});
  } else if (error instanceof UnauthorizedError) {
    router.push('/login');
  } else if (error instanceof ForbiddenError) {
    toast.error(getUserFriendlyMessage(error));
  } else if (error instanceof RateLimitError) {
    toast.error(`Please wait ${error.retryAfter}s and try again.`);
  } else if (error instanceof SdkError) {
    toast.error(getUserFriendlyMessage(error));
    logger.error('sdk_error', { code: error.code, requestId: error.requestId });
  } else {
    throw error; // Not ours - do not swallow
  }
}
```

---

## 4. Authentication Standards

### 4.1 Authentication Modes

The SDK MUST support two mutually exclusive authentication modes:

```typescript
// MODE 1: API Key (Server-Side)
const client = new PlatformClient({
  apiKey: 'sk_live_xxx',  // Added to Authorization header
});

// MODE 2: Cookie-Based (Browser-Side)
const client = new PlatformClient({
  useCookies: true,  // Uses HttpOnly session cookies
});
```

**Rules:**
- API Key mode: Token added to `Authorization: Bearer {apiKey}` header
- Cookie mode: `credentials: 'include'` for all requests
- NEVER expose API keys in browser-side code
- Cookie mode requires proper CORS and SameSite configuration
- Passing both `apiKey` and `useCookies: true` is a configuration error and MUST throw at
  construction time, not at first request

### 4.2 Login Flow (Cookie Mode)

```typescript
interface LoginRequest {
  email: string;
  password: string;
  audience?: 'admin' | 'developer' | 'portal';  // Determines session context
  remember_me?: boolean;
}

interface LoginResponse {
  user: User;
  mfa_required?: boolean;
  mfa_methods?: string[];
  // Note: Tokens are set as HttpOnly cookies, not returned in body
}

async function login(params: LoginRequest): Promise<LoginResponse> {
  // IMPORTANT: Login is a special case - no CSRF token required
  // CSRF protection is for authenticated mutations only

  const response = await this.http.post<LoginResponse>('/auth/login', params, {
    skipCsrf: true,  // Login doesn't require CSRF (no session exists yet)
  });

  return response;
}
```

### 4.3 CSRF Protection (Double-Submit Pattern)

```typescript
// For authenticated mutations, include CSRF token
private buildHeaders(method: string): Record<string, string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Add CSRF token for mutating requests in cookie mode
  if (this.config.useCookies && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
    const csrfToken = this.getCsrfToken();
    if (csrfToken) {
      headers['X-CSRF-Token'] = csrfToken;
    }
  }

  return headers;
}

// CSRF token is stored in a readable cookie (not HttpOnly)
private getCsrfToken(): string | null {
  if (typeof document === 'undefined') return null;

  const match = document.cookie.match(/app-csrf-token=([^;]+)/);
  return match ? match[1] : null;
}
```

### 4.4 Session Refresh

```typescript
class SessionManager {
  private refreshPromise: Promise<void> | null = null;
  private lastRefresh: number = 0;
  private readonly minRefreshInterval = 5000; // Prevent refresh storms

  async ensureValidSession(): Promise<void> {
    // Debounce rapid refresh calls
    if (Date.now() - this.lastRefresh < this.minRefreshInterval) {
      return this.refreshPromise ?? Promise.resolve();
    }

    // Deduplicate concurrent refresh calls
    if (this.refreshPromise) {
      return this.refreshPromise;
    }

    this.refreshPromise = this.doRefresh();

    try {
      await this.refreshPromise;
    } finally {
      this.refreshPromise = null;
      this.lastRefresh = Date.now();
    }
  }

  private async doRefresh(): Promise<void> {
    try {
      await this.http.post('/auth/refresh', undefined, { skipCsrf: true });
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        // Session truly expired - notify app
        this.onSessionExpired();
      }
      throw error;
    }
  }
}
```

### 4.5 Logout

```typescript
async function logout(): Promise<void> {
  try {
    // Call backend to invalidate session
    await this.http.post('/auth/logout');
  } finally {
    // Clear any client-side state regardless of API success
    this.clearLocalState();

    // Redirect to login (optional, configurable)
    if (this.config.logoutRedirect) {
      window.location.href = this.config.logoutRedirect;
    }
  }
}
```

### 4.6 Cookie Scope and the Stale-Cookie Failure Mode

Cookie attributes are part of the contract between the API and the SDK. Changing a
cookie's `Domain` or `Path` after sessions exist creates a failure that is hard to
diagnose, because the browser will send BOTH the old and the new cookie and the server
reads whichever appears first.

**Worked example of the failure.**

| Day | Change | Cookie written |
|---|---|---|
| Day 1 | Initial release | `app-refresh; Domain=example.com; Path=/v1/auth/refresh` |
| Day 30 | Refresh broadened | `app-refresh; Domain=example.com; Path=/` |
| Day 45 | Console scoped to its own subdomain | `app-refresh; Domain=admin.example.com; Path=/` |

A browser that authenticated before day 30 now holds two `app-refresh` cookies. Both are
sent on `POST /v1/auth/refresh`. The server reads the first one, its hash lookup misses,
and refresh fails. The visible symptom is a user being returned to the login screen every
minute or two while a page reload still works.

```typescript
// Clearing a cookie MUST repeat every (domain, path) pair the cookie has ever used.
function clearSessionCookies(res: Response, domain: string): void {
  const paths = ['/', '/v1/auth/refresh'];        // current and historical paths
  const domains = [domain, `.${domain}`];          // host-only and parent-domain forms

  for (const d of domains) {
    for (const p of paths) {
      res.clearCookie('app-refresh', { domain: d, path: p });
      res.clearCookie('app-session', { domain: d, path: p });
      res.clearCookie('app-csrf-token', { domain: d, path: p });
    }
  }
}
```

**Rules:**
- Record every `(name, domain, path)` triple the platform has ever issued, and clear all
  of them on logout and on a failed refresh
- Never narrow a cookie's `Path` or `Domain` without a clearing migration in the same release
- Log a `session.refresh_failed` audit event carrying a short token-hash prefix; a run of
  events with the same prefix is the signature of a shadowing stale cookie
- Prefer one cookie scope for the whole platform over per-subdomain scopes; cross-subdomain
  sessions need a parent-domain cookie and a real domain (a `localhost` host cannot carry one)

---

## 5. React Integration Standards

See also [react-patterns](../react-patterns/SKILL.md) for general component and hook
discipline; this section covers only the SDK-specific surface.

### 5.1 Provider Pattern

```typescript
// Context for SDK instance
const AuthContext = createContext<PlatformClient | null>(null);

// Provider component
export function AuthProvider({
  children,
  baseUrl,
  useCookies = true,
  onSessionExpired,
  ...config
}: AuthProviderProps) {
  // Single SDK instance
  const client = useMemo(() => {
    return new PlatformClient({
      baseUrl,
      useCookies,
      ...config,
    });
  }, [baseUrl, useCookies]);

  // Register session expiry callback
  useEffect(() => {
    if (onSessionExpired) {
      client.onSessionExpired(onSessionExpired);
    }
  }, [client, onSessionExpired]);

  return (
    <AuthContext.Provider value={client}>
      {children}
    </AuthContext.Provider>
  );
}

// Hook to get client
export function usePlatformClient(): PlatformClient {
  const client = useContext(AuthContext);
  if (!client) {
    throw new Error('usePlatformClient must be used within AuthProvider');
  }
  return client;
}
```

### 5.2 Authentication Hook

```typescript
interface AuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: User | null;
  error: SdkError | null;
}

interface AuthActions {
  login: (params: LoginRequest) => Promise<LoginResponse>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
}

export function useAuth(): AuthState & AuthActions {
  const client = usePlatformClient();
  const queryClient = useQueryClient();

  // Query for current session
  const {
    data: user,
    isLoading,
    error,
    refetch
  } = useQuery({
    queryKey: ['platform', 'session'],
    queryFn: async () => {
      try {
        return await client.users.getMe();
      } catch (e) {
        if (e instanceof UnauthorizedError) {
          return null; // Not logged in
        }
        throw e;
      }
    },
    staleTime: 5 * 60 * 1000,     // 5 minutes
    gcTime: 30 * 60 * 1000,       // 30 minutes
    retry: false,                  // Don't retry auth checks
    refetchOnWindowFocus: true,    // Re-check on tab focus
  });

  // Login mutation
  const loginMutation = useMutation({
    mutationFn: (params: LoginRequest) => client.auth.login(params),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['platform'] });
    },
  });

  // Logout mutation
  const logoutMutation = useMutation({
    mutationFn: () => client.auth.logout(),
    onSuccess: () => {
      queryClient.clear(); // Clear all cached data
    },
  });

  return {
    isAuthenticated: !!user,
    isLoading,
    user: user ?? null,
    error: error as SdkError | null,
    login: loginMutation.mutateAsync,
    logout: logoutMutation.mutateAsync,
    refresh: refetch,
  };
}
```

### 5.3 Protected Route Pattern

```typescript
export function RequireAuth({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    }
  }, [isAuthenticated, isLoading, router]);

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return null; // Will redirect
  }

  return <>{children}</>;
}
```

### 5.4 RBAC-Protected Pages Pattern (Preventing "Access Denied" Flash)

When using `useHasPrivilege` for RBAC checks, the hook returns `false` while authentication
is loading (fail-safe design). This can cause a flash of "Access Denied" before the actual
permission state is determined.

**The Problem:**
```typescript
// BAD: Shows "Access Denied" flash while auth is loading
export default function AdminPage() {
  const canView = useHasPrivilege('admin.users.view');

  // This shows immediately because canView is false during auth loading!
  if (!canView) {
    return <BlockedState title="Access Denied" />;
  }

  return <PageContent />;
}
```

**The Solution:**
```typescript
// GOOD: Check auth loading state BEFORE checking privileges
import { useHasPrivilege, useAuth } from '@{{PROJECT_SLUG}}/sdk/react';
import { LoadingState, BlockedState } from '@/components/states';

export default function AdminPage() {
  // Step 1: Get auth loading state
  const { isLoading: isAuthLoading } = useAuth();

  // Step 2: RBAC checks
  const canView = useHasPrivilege('admin.users.view');
  const canManage = useHasPrivilege('admin.users.manage');

  // ... other hooks and state ...

  // Step 3: Show loading while auth is initializing (prevents flash)
  if (isAuthLoading) {
    return <LoadingState message="Checking permissions..." />;
  }

  // Step 4: Access denied (only show AFTER auth has loaded)
  if (!canView) {
    return (
      <BlockedState
        title="Access Denied"
        message="You do not have permission to view this page."
        requiredPrivilege="admin.users.view"
      />
    );
  }

  // Step 5: Render page content
  return <PageContent canManage={canManage} />;
}
```

**Rules:**
1. **ALWAYS** check `isAuthLoading` from `useAuth()` before checking `useHasPrivilege` results
2. Show `LoadingState` with "Checking permissions..." while auth is loading
3. Only show `BlockedState` after auth has finished loading and confirmed no permission
4. This pattern applies to ALL pages that use `useHasPrivilege` for access control

**Why This Works:**
- `useHasPrivilege` returns `false` during loading (fail-safe behavior)
- `useAuth().isLoading` tells us when authentication state is being determined
- By checking loading state first, we show an appropriate loading indicator
- Users only see "Access Denied" when they genuinely lack permission

### 5.5 Hook Inventory

Every React adapter exposes the same named surface so that an application can move
between frameworks without rewriting its components.

| Hook | Returns | Notes |
|---|---|---|
| `usePlatformClient()` | `PlatformClient` | Throws outside `AuthProvider` |
| `useAuth()` | `AuthState & AuthActions` | Single source of `isLoading` |
| `useHasPrivilege(code)` | `boolean` | `false` while loading (fail-safe) |
| `useTenant()` | `{ tenant, isLoading }` | Active tenant context |
| `useSession()` | `{ session, refresh }` | Raw session metadata |

---

## 6. Performance Standards

### 6.1 Bundle Size Targets

| Package | Max Gzipped Size | Target |
|---------|-----------------|--------|
| `@{{PROJECT_SLUG}}/sdk` (core) | < 15 KB | Minimal footprint |
| `@{{PROJECT_SLUG}}/sdk/react` | < 5 KB | React hooks only |
| `@{{PROJECT_SLUG}}/sdk/nextjs` | < 10 KB | SSR support |
| `@{{PROJECT_SLUG}}/sdk/node` | < 12 KB | Server-side, API key mode |

**Rules:**
- Tree-shakeable exports
- No heavy dependencies (date/utility mega-libraries)
- Lazy loading for optional features
- Code splitting for resource namespaces

Budgets are enforced in CI, not by convention:

```bash
# Measure the gzipped size of every entry point
npm run build --workspace={{SDK_PKG}}
npx size-limit --workspace={{SDK_PKG}}

# Fail the build when a budget is exceeded
npx size-limit --why   # attribute the regression to a dependency
```

### 6.2 Network Optimization

```typescript
// Request deduplication for GET requests
// See Section 2.4

// Response caching (React Query handles this for React apps)
// For non-React: implement simple TTL cache
class ResponseCache {
  private cache = new Map<string, { data: unknown; expiry: number }>();

  get<T>(key: string): T | undefined {
    const entry = this.cache.get(key);
    if (!entry) return undefined;
    if (Date.now() > entry.expiry) {
      this.cache.delete(key);
      return undefined;
    }
    return entry.data as T;
  }

  set(key: string, data: unknown, ttlMs: number): void {
    this.cache.set(key, {
      data,
      expiry: Date.now() + ttlMs,
    });
  }
}
```

### 6.3 Lazy Loading

```typescript
// Resources are lazy-loaded on first access
class PlatformClient {
  private _auth?: AuthResource;
  private _users?: UsersResource;
  private _tenants?: TenantsResource;

  get auth(): AuthResource {
    return this._auth ??= new AuthResource(this.http);
  }

  get users(): UsersResource {
    return this._users ??= new UsersResource(this.http);
  }

  get tenants(): TenantsResource {
    return this._tenants ??= new TenantsResource(this.http);
  }
}
```

---

## 7. Security Standards

### 7.1 Never Trust Client Input

```typescript
// BAD: Client controls sensitive parameters
await client.users.update({
  is_admin: true,  // Never allow client to set this
  tenant_id: 'other-tenant',  // Never allow tenant switching
});

// GOOD: Backend enforces authorization
// Client can only update allowed fields
await client.users.updateProfile({
  name: 'New Name',
  email: 'new@example.com',
});
```

### 7.2 Secure Token Handling

```typescript
// NEVER expose tokens in:
// - URL parameters
// - localStorage (XSS vulnerable)
// - sessionStorage (XSS vulnerable)
// - console.log
// - error messages

// ALWAYS use:
// - HttpOnly cookies for session tokens
// - Secure flag for HTTPS-only
// - SameSite=Strict or Lax for CSRF protection
// - Short-lived access tokens with refresh rotation
```

### 7.3 Debug Mode Safety

```typescript
// Debug logging MUST be:
// 1. Off by default
// 2. Never log sensitive data (tokens, passwords)
// 3. Configurable at runtime

class HttpClient {
  private debug: boolean;

  private log(message: string, data?: unknown): void {
    if (!this.debug) return;

    // Sanitize sensitive data
    const sanitized = this.sanitizeForLogging(data);
    console.log(`[SDK] ${message}`, sanitized);
  }

  private sanitizeForLogging(data: unknown): unknown {
    if (!data || typeof data !== 'object') return data;

    const sensitiveKeys = ['password', 'token', 'apiKey', 'secret', 'authorization'];
    const sanitized = { ...data as Record<string, unknown> };

    for (const key of Object.keys(sanitized)) {
      if (sensitiveKeys.some(s => key.toLowerCase().includes(s))) {
        sanitized[key] = '[REDACTED]';
      }
    }

    return sanitized;
  }
}
```

### 7.4 Supply Chain

The SDK is installed into other people's applications, so its dependency surface is part
of its security posture.

```bash
# Run before every release
npm audit --omit=dev --workspace={{SDK_PKG}}
npm ls --all --workspace={{SDK_PKG}} | grep -c ''    # transitive dependency count
npm pack --dry-run --workspace={{SDK_PKG}}           # confirm published file list
```

**Rules:**
- Zero runtime dependencies is the target; each one added needs a reason in the PR
- `peerDependencies` for React and framework packages, never `dependencies`
- The published tarball contains `dist/`, `README.md`, and `LICENSE` only — no tests,
  no source maps pointing at absolute paths, no fixtures
- A dependency with a post-install script is rejected

---

## 8. Testing Standards

### 8.1 Unit Test Coverage

| Component | Required Coverage |
|-----------|------------------|
| HTTP Client | 100% |
| Error Handling | 100% |
| Authentication | 100% |
| Resource Methods | 90%+ |
| React Hooks | 90%+ |

```bash
# Run the SDK test suite with coverage and enforce the thresholds above
npm test --workspace={{SDK_PKG}}
npm run test:cov --workspace={{SDK_PKG}}
npm test --workspace={{SDK_PKG}} -- --testPathPattern="http/retry"
```

### 8.2 Integration Test Scenarios

```typescript
describe('Authentication Flow', () => {
  it('should login with valid credentials', async () => {
    const result = await client.auth.login({
      email: 'test@example.com',
      password: 'example-pass-1',
    });
    expect(result.user).toBeDefined();
  });

  it('should handle invalid credentials', async () => {
    await expect(client.auth.login({
      email: 'test@example.com',
      password: 'example-wrong-pass',
    })).rejects.toThrow(AuthenticationError);
  });

  it('should handle rate limiting', async () => {
    // Trigger rate limit
    const attempts = Array(10).fill(null).map(() =>
      client.auth.login({ email: 'test@example.com', password: 'example-wrong-pass' })
    );

    await expect(Promise.all(attempts)).rejects.toThrow(RateLimitError);
  });

  it('should refresh session automatically', async () => {
    // Login
    await client.auth.login({ email: 'test@example.com', password: 'example-pass-1' });

    // Wait for token to expire (or mock)
    jest.advanceTimersByTime(TOKEN_EXPIRY);

    // Next request should auto-refresh
    const user = await client.users.getMe();
    expect(user).toBeDefined();
  });
});
```

### 8.3 Mocking Strategy

```typescript
// Use MSW (Mock Service Worker) for realistic API mocking
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

const server = setupServer(
  http.post('*/v1/auth/login', async ({ request }) => {
    const body = await request.json();
    if (body.password === 'example-pass-1') {
      return HttpResponse.json({ user: mockUser });
    }
    return HttpResponse.json(
      { message: 'Invalid credentials' },
      { status: 401 }
    );
  }),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Mock at the network boundary, never by stubbing the SDK's own `HttpClient`. Stubbing the
client means the retry, deduplication, CSRF, and error-mapping layers are never exercised,
which is exactly where SDK bugs live.

### 8.4 Behavioural Verification Against a Running API

Unit tests prove the SDK's logic. A behavioural run proves the SDK and the API still agree.
Run it against a local API before every release.

```bash
# Start the API, then exercise the real contract
BASE_URL="http://api.example.com:3001"

# 1. Login and capture the cookie jar
curl -s -c /tmp/sdk-jar.txt -X POST "$BASE_URL/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"owner@example.com","password":"example-pass-1","audience":"admin"}'

# 2. The session cookie must be HttpOnly and the CSRF cookie must not be
grep -E 'app-session|app-refresh|app-csrf-token' /tmp/sdk-jar.txt

# 3. An authenticated read must succeed with the jar alone
curl -s -b /tmp/sdk-jar.txt "$BASE_URL/v1/users/me" | head -c 400

# 4. A mutation without the CSRF header must be rejected with 403
curl -s -o /dev/null -w '%{http_code}\n' -b /tmp/sdk-jar.txt \
  -X PATCH "$BASE_URL/v1/users/me" -H 'Content-Type: application/json' -d '{"name":"x"}'

# 5. Refresh must succeed and rotate the refresh cookie
curl -s -b /tmp/sdk-jar.txt -c /tmp/sdk-jar.txt -X POST "$BASE_URL/v1/auth/refresh" -o /dev/null -w '%{http_code}\n'

# 6. Logout must clear every cookie at every historical path
curl -s -b /tmp/sdk-jar.txt -X POST "$BASE_URL/v1/auth/logout" -o /dev/null -w '%{http_code}\n'
rm -f /tmp/sdk-jar.txt
```

Expected output for a healthy build: step 2 prints three cookie lines, step 3 prints a
user object, step 4 prints `403`, steps 5 and 6 print `200`. Record the actual output in
the release notes. A test is only `PASS` when it was executed and its output captured; a
test that was written but not run is `NOT EXECUTED`.

---

## 9. Documentation Standards

### 9.1 API Documentation (TSDoc)

```typescript
/**
 * Authenticates a user and establishes a session.
 *
 * @remarks
 * This method handles both standard login and MFA challenges.
 * On success, session cookies are automatically set.
 *
 * @param params - Login credentials
 * @param params.email - User's email address
 * @param params.password - User's password
 * @param params.audience - Session context ('admin' | 'developer' | 'portal')
 *
 * @returns Login result with user data and optional MFA challenge
 *
 * @throws {@link AuthenticationError} Invalid credentials
 * @throws {@link RateLimitError} Too many login attempts
 * @throws {@link ValidationError} Invalid input format
 *
 * @example
 * ```typescript
 * try {
 *   const result = await client.auth.login({
 *     email: 'user@example.com',
 *     password: 'example-pass-1',
 *     audience: 'admin',
 *   });
 *
 *   if (result.mfa_required) {
 *     // Handle MFA challenge
 *     router.push('/mfa');
 *   } else {
 *     // Login successful
 *     router.push('/dashboard');
 *   }
 * } catch (error) {
 *   if (error instanceof AuthenticationError) {
 *     toast.error('Invalid email or password');
 *   }
 * }
 * ```
 */
async login(params: LoginRequest): Promise<LoginResponse>;
```

Every exported symbol carries TSDoc. Every method that can throw documents each error
class with `@throws`. Every non-trivial method carries at least one `@example`.

### 9.2 README Template

Each SDK package MUST include:

1. **Quick Start** - 5-line getting started example
2. **Installation** - npm/yarn/pnpm commands
3. **Configuration** - All options with defaults
4. **Core Concepts** - Authentication, errors, typing
5. **API Reference** - Link to generated docs
6. **Migration Guide** - Breaking changes between versions
7. **Troubleshooting** - Common issues and solutions

The Quick Start must be copy-pasteable and must work against a fresh install:

```bash
npm install @{{PROJECT_SLUG}}/sdk
# or
yarn add @{{PROJECT_SLUG}}/sdk
# or
pnpm add @{{PROJECT_SLUG}}/sdk
```

```typescript
import { PlatformClient } from '@{{PROJECT_SLUG}}/sdk';

const client = new PlatformClient({ baseUrl: 'https://api.example.com', useCookies: true });
await client.auth.login({ email: 'user@example.com', password: 'example-pass-1' });
const me = await client.users.getMe();
console.log(me.email); // user@example.com
```

---

## 10. Release Standards

### 10.1 Semantic Versioning

- **MAJOR** (X.0.0): Breaking API changes
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, backward compatible

A change to a default value in section 1.3, a change to a cookie name or scope, or a
removal of an exported symbol is MAJOR even when the TypeScript types still compile.

### 10.2 Changelog Format

```markdown
# Changelog

## [1.2.0] - YYYY-MM-DD

### Added
- Support for idempotency keys in mutation operations
- New `onSessionExpired` callback in React provider

### Changed
- Improved error messages for authentication failures

### Fixed
- Fixed race condition in session refresh logic

### Security
- Updated dependencies to address CVE-XXXX-XXXX
```

### 10.3 Deprecation Policy

1. Mark deprecated methods with `@deprecated` JSDoc
2. Log warning when deprecated methods are used
3. Maintain deprecated methods for 2 major versions
4. Document migration path in release notes

```typescript
/**
 * @deprecated Since 1.2.0. Use {@link PlatformClient.users.updateProfile} instead.
 * Removed in 3.0.0.
 */
async updateUser(params: LegacyUpdateParams): Promise<User> {
  warnOnce('updateUser is deprecated; use users.updateProfile (removed in 3.0.0)');
  return this.users.updateProfile(params);
}
```

### 10.4 Release Sequence

```bash
# 1. Clean build from the committed tree
npm run build --workspace={{SDK_PKG}}

# 2. Types, lint, and the full test suite must all be green
npm run type-check --workspace={{SDK_PKG}}
npm run lint --workspace={{SDK_PKG}}
npm run test:cov --workspace={{SDK_PKG}}

# 3. Budgets and supply chain
npx size-limit --workspace={{SDK_PKG}}
npm audit --omit=dev --workspace={{SDK_PKG}}

# 4. Verify the published surface before it is public
npm pack --dry-run --workspace={{SDK_PKG}}

# 5. Version, tag, publish
npm version minor --workspace={{SDK_PKG}}
npm publish --workspace={{SDK_PKG}} --access public

# 6. Smoke-test the published artifact in a clean directory
mkdir -p /tmp/sdk-smoke && cd /tmp/sdk-smoke && npm init -y >/dev/null
npm install @{{PROJECT_SLUG}}/sdk@latest
node -e "const {PlatformClient}=require('@{{PROJECT_SLUG}}/sdk'); console.log(typeof PlatformClient)"
```

Step 6 must print `function`. If it prints `undefined`, the package's `exports` map or
build output is wrong and the release must be deprecated immediately.

---

## 11. Framework Adapters

Adapters are thin. An adapter translates a framework's conventions into calls on the core
client; it never reimplements retry, error mapping, or session logic.

| Adapter | Entry point | Responsibility |
|---|---|---|
| Core | `@{{PROJECT_SLUG}}/sdk` | `PlatformClient`, errors, resources |
| React | `@{{PROJECT_SLUG}}/sdk/react` | `AuthProvider`, hooks from 5.5 |
| Next.js | `@{{PROJECT_SLUG}}/sdk/nextjs` | Server-side client, middleware, route handlers |
| Remix | `@{{PROJECT_SLUG}}/sdk/remix` | Loader/action client, session forwarding |
| SvelteKit | `@{{PROJECT_SLUG}}/sdk/sveltekit` | `handle` hook, `locals.user` |
| Node | `@{{PROJECT_SLUG}}/sdk/node` | API-key client for server-to-server calls |

**Rules:**
- Each adapter is a separate export path with its own bundle budget (6.1)
- Framework packages are `peerDependencies`, never `dependencies`
- An adapter re-exports the core error classes rather than defining its own
- Server-side adapters forward the incoming request's cookie header; they never read a
  cookie from a global

```typescript
// Next.js: a request-scoped client that forwards the caller's cookies
import { cookies } from 'next/headers';
import { PlatformClient } from '@{{PROJECT_SLUG}}/sdk';

export async function serverClient(): Promise<PlatformClient> {
  const jar = await cookies();
  return new PlatformClient({
    baseUrl: process.env.APP_SDK__BASE_URL!,
    useCookies: true,
    headers: { cookie: jar.toString() },   // request-scoped, never cached
  });
}
```

```typescript
// Node: an API-key client for server-to-server calls, created once per process
import { PlatformClient } from '@{{PROJECT_SLUG}}/sdk/node';

export const platform = new PlatformClient({
  baseUrl: process.env.APP_SDK__BASE_URL ?? 'https://api.example.com',
  apiKey: process.env.APP_SDK__API_KEY,
  maxRetries: 5,
});
```

---

## Appendix A: File Structure

```text
{{SDK_PKG}}/
├── src/
│   ├── index.ts              # Public exports
│   ├── client.ts             # PlatformClient class
│   ├── config.ts             # Configuration types
│   ├── errors/
│   │   ├── index.ts          # Error exports
│   │   ├── base.ts           # SdkError base class
│   │   ├── auth.ts           # Authentication errors
│   │   ├── network.ts        # Network errors
│   │   └── validation.ts     # Validation errors
│   ├── http/
│   │   ├── index.ts
│   │   ├── client.ts         # HttpClient class
│   │   ├── retry.ts          # Retry logic
│   │   ├── dedup.ts          # Request deduplication
│   │   └── cache.ts          # Response caching
│   ├── resources/
│   │   ├── index.ts
│   │   ├── auth.ts           # AuthResource
│   │   ├── users.ts          # UsersResource
│   │   └── tenants.ts        # TenantsResource
│   ├── react/
│   │   ├── index.ts          # React exports
│   │   ├── provider.tsx      # AuthProvider
│   │   └── hooks/
│   │       ├── useAuth.ts
│   │       └── useClient.ts
│   └── types/
│       ├── index.ts
│       ├── auth.ts
│       ├── users.ts
│       └── tenants.ts
├── tests/
│   ├── unit/
│   ├── integration/
│   └── mocks/
├── package.json
├── tsconfig.json
├── tsup.config.ts
└── README.md
```

---

## Appendix B: Capability Baseline

The capabilities an SDK is expected to ship, and the section that defines each.

| Capability | Required | Defined in | Notes |
|---------|----------|--------|-------|
| Automatic Retries | Yes | 2.3 | Exponential backoff with jitter, honours `Retry-After` |
| Idempotency Keys | Yes | 2.5 | Required before any POST may be retried |
| Request Deduplication | Yes | 2.4 | GET always; POST only on an allowlist |
| Typed Errors | Yes | 3.1 | `instanceof`-discriminable hierarchy |
| Cookie Auth | Yes | 4.1 | HttpOnly session, double-submit CSRF |
| React Hooks | Yes | 5.1-5.5 | Separate export path, own bundle budget |
| SSR Support | Yes | 11 | Request-scoped client, forwarded cookies |
| Tree Shakeable | Yes | 6.1 | ESM output, `sideEffects: false` |
| Zero Dependencies | Target | 7.4 | Each runtime dependency needs a recorded reason |
| Timeouts and Cancellation | Yes | 2.6 | Composed `AbortSignal`, typed `TimeoutError` |
| Environment Configuration | Yes | 1.4 | `APP_SDK__` prefix, options still win |

**Legend**: Yes = must ship | Target = aim for it, justify any exception | No = out of scope

---

## Appendix C: Review Checklists

### C.1 New or Changed SDK Code

- [ ] Configuration resolved once at construction, never read from the environment per request
- [ ] Every new option has a default recorded in the table in section 1.3
- [ ] No global state, no singleton, no module-level mutable client
- [ ] Resource classes contain no business logic
- [ ] Every failure path throws an `SdkError` subclass with `name` set explicitly
- [ ] `message` contains no token, password, or secret; `userMessage` is end-user safe
- [ ] `requestId` propagated from `X-Request-Id` where the response carries one
- [ ] `retryable` set at construction, not re-derived by the caller
- [ ] Non-idempotent requests are retried only with an idempotency key
- [ ] Every request is abortable and has a deadline; timers disposed in `finally`
- [ ] No `console.log` outside the guarded debug logger; debug output is sanitized
- [ ] No token written to `localStorage`, `sessionStorage`, a URL, or a log line
- [ ] New exports added to the entry point and to the TSDoc surface
- [ ] TSDoc on every exported symbol, with `@throws` and at least one `@example`

### C.2 Authentication and Cookies

- [ ] `apiKey` and `useCookies` cannot both be set; construction throws if they are
- [ ] Cookie mode sends `credentials: 'include'` on every request
- [ ] Session and refresh cookies are HttpOnly; only the CSRF cookie is script-readable
- [ ] CSRF header sent on POST/PUT/PATCH/DELETE, skipped on login and refresh
- [ ] Refresh is debounced and deduplicated so concurrent 401s cause one refresh
- [ ] Logout clears client state even when the API call fails
- [ ] Every historical `(name, domain, path)` cookie triple is cleared on logout
- [ ] No cookie `Path` or `Domain` was narrowed without a clearing migration

### C.3 Release

- [ ] Version bump matches the change class (MAJOR for defaults, cookies, or removals)
- [ ] Changelog entry written under Added / Changed / Fixed / Security
- [ ] Deprecated symbols carry `@deprecated`, warn once, and name their removal version
- [ ] Coverage thresholds from section 8.1 met
- [ ] Behavioural run from 8.4 executed and its real output recorded
- [ ] Bundle budgets from section 6.1 verified with `size-limit`
- [ ] `npm audit --omit=dev` clean; `npm pack --dry-run` file list reviewed
- [ ] Published artifact smoke-tested in a clean directory

---

## Related Skills

- [api-design](../api-design/SKILL.md) — the API contract the SDK consumes
- [contract-first](../contract-first/SKILL.md) — generating types from the API schema
- [typescript-coding-style](../typescript-coding-style/SKILL.md) — type-level conventions
- [react-patterns](../react-patterns/SKILL.md) — component and hook discipline

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | YYYY-MM-DD | Initial version |
