## Stack Rules — NestJS

- Controllers declare only their own path segment; the global prefix is set once in `main.ts`
- Every controller using an auth guard imports the auth module, and every handler on a guarded controller declares its scope and privilege decorators; missing metadata is open access
- DTOs validate with `whitelist: true, forbidNonWhitelisted: true`; the client SDK's payloads are generated from the OpenAPI document so they never drift
- Business logic in services; controllers stay thin; repositories own data access with the tenant filter applied through one helper
- `@Public()` endpoints resolve tenant context from the origin through a shared service, never from `req`
- Exception filters never add cookie mutations to 4xx responses that may be proxied
- Registered gateways, queues, and cron jobs are logged at startup and listed by a health endpoint
- Migrations are the only way schema or seed data changes; provisioning updates for new tenants ship in the same work order
