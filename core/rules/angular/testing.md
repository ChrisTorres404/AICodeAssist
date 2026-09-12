---
paths:
  - "**/*.spec.ts"
  - "**/*.test.ts"
---
# Angular Testing

> This file extends [common/testing.md](../common/testing.md) with Angular specific content.

Worked examples: skill `angular-testing`.

## Test Runner

Use the test runner configured by the project. Check `angular.json` and `package.json`; Angular projects commonly use Vitest, Jest, or Jasmine + Karma.

```bash
ng test               # watch mode
ng test --no-watch    # CI mode
```

## TestBed Setup

For standalone components, import the component directly. Call `compileComponents()` for components with external templates.

## Signal Inputs

Set signal-based inputs via `fixture.componentRef.setInput()`, then call `fixture.detectChanges()`.

## Component Harnesses

Prefer Angular CDK component harnesses over direct DOM queries for UI interaction. Harnesses are more resilient to markup changes.

## Router Testing

Use `RouterTestingHarness` for components that depend on the router.

## Async Testing

Use `fakeAsync` + `tick` for controlled async. Use `waitForAsync` for real async with `fixture.whenStable()`.

## HTTP Testing

Configure `provideHttpClient()` + `provideHttpClientTesting()`, inject `HttpTestingController`, and call `httpMock.verify()` in `afterEach`.

## Service Testing

Inject services directly without a component fixture.

## What to Test

- **Services**: All public methods, error paths, HTTP interactions
- **Components**: Input/output bindings, rendered output for key states, user interactions via harnesses
- **Pipes**: Pure transformation — plain unit tests, no TestBed needed
- **Guards/Resolvers**: Return values for allowed and denied states using `RouterTestingHarness`

## E2E Testing

Use the project's configured E2E framework, such as Cypress or Playwright, for critical user flows.

- Add `data-cy` attributes to interactive elements for stable selectors
- Do not rely on CSS classes or text content for selectors in E2E tests

## Coverage

- Verification evidence is behavioral: the running system was exercised and state was checked. See common/testing.md.

## Skill Reference

See skill: `angular-testing` for comprehensive testing patterns, harness usage, and async best practices.
