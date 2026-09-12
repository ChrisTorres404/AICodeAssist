---
paths:
  - "**/*.component.ts"
  - "**/*.component.html"
  - "**/*.service.ts"
  - "**/*.store.ts"
  - "**/*.routes.ts"
---
# Angular Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Angular specific content.

Worked examples: skill `angular-patterns`.

## Smart / Dumb Component Split

Smart (container) components own data fetching and state. Dumb (presentational) components receive inputs and emit outputs only — no service injection.

## Service Layer

Services own all data access and business logic. Components delegate — no `HttpClient` in components.

## Async Data with `resource`

Use `resource()` for reactive async fetching. Prefer over manual RxJS pipelines for simple data loading.

Access state: `userResource.value()`, `userResource.isLoading()`, `userResource.error()`, `userResource.reload()`.

## Signal State Patterns

- `signal()` — local mutable state
- `computed()` — derived state, never duplicated
- `linkedSignal()` — writable derived state that resets with its source
- `toSignal()` — bridge an Observable into a signal

Never store derived values in separate signals — use `computed`. Never use `effect` to sync signals — use `computed` or `linkedSignal`.

## Subscription Cleanup

Use `takeUntilDestroyed()` for all manual subscriptions. Never use manual `ngOnDestroy` + `Subject` + `takeUntil` on new code.

## Routing

### Route Definition

- Use `canMatch` over `canActivate` when the route module should not load for unauthorized users
- Lazy-load all feature modules with `loadChildren`
- Pre-fetch data with `resolve` to avoid loading states in components

### Functional Guards

Write guards as functional `CanActivateFn`s that `inject()` their dependencies and return `true` or a `UrlTree`.

### Data Resolvers

Write resolvers as functional `ResolveFn`s that `inject()` the service and read the route params.

### View Transitions

Enable smooth route transitions with the View Transitions API: `provideRouter(routes, withViewTransitions())` in `app.config.ts`.

## Dependency Injection Patterns

### Scoped Providers

Provide services at component or route level when they should not be singletons.

### `InjectionToken`

Declare an `InjectionToken<T>` for non-class dependencies, provide it with `useValue` or `useFactory`, and read it with `inject()`.

### `viewProviders` vs `providers`

- `providers`: Available to the component and all its content children
- `viewProviders`: Available only to the component's own view (not projected content)

## HTTP Interceptors

Use functional interceptors (v15+) for auth, error handling, and retries. Register them in `app.config.ts` with `provideHttpClient(withInterceptors([...]))`.

## RxJS Operators

- `switchMap` — search, navigation (cancels previous)
- `mergeMap` — independent parallel requests
- `exhaustMap` — form submissions (ignores until complete)
- Always handle errors with `catchError` — never let streams die silently

## Forms

Match the project's existing form strategy. For new v21+ apps, prefer signal forms. Reactive Forms built with `FormBuilder` remain the standard for complex forms.

## Rendering Strategies

- **CSR** (default): Standard SPA
- **SSR + Hydration**: `ng add @angular/ssr` — improves FCP and SEO
- **SSG (Prerendering)**: Static pages at build time for content-heavy routes

When using SSR, avoid `window`, `document`, `localStorage` directly — use `isPlatformBrowser` or `DOCUMENT` token.

## Accessibility

Use Angular CDK for headless, accessible components (Accordion, Listbox, Combobox, Menu, Tabs, Toolbar, Tree, Grid). Style ARIA attributes rather than managing them manually:

```css
[aria-selected="true"] { background: var(--color-selected); }
```

## Skill Reference

See skill: `angular-patterns` for deep guidance on signals, forms, routing, DI, SSR, and accessibility patterns.
