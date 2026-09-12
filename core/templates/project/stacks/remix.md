## Stack Rules — Remix

- Loaders read, actions write; every action validates with a schema and authorizes inside the action
- Route modules stay thin; domain logic in `app/models` or feature modules; no data access in components
- Errors through `ErrorBoundary` per route; `throw json(...)` for expected failures, never swallow
- Progressive enhancement: forms work without JavaScript, then `useFetcher` improves them
- Sessions through the server-side session storage only; cookies `httpOnly`, `secure` in production
- Tests: Vitest for loaders and actions with `createRemixStub`, Playwright for flows; behavioural suites against the running app for verification
- `remix build` and type-check clean
