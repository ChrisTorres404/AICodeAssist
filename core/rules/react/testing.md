---
paths:
  - "**/*.test.tsx"
  - "**/*.test.jsx"
  - "**/*.spec.tsx"
  - "**/*.spec.jsx"
  - "**/__tests__/**/*.ts"
  - "**/__tests__/**/*.tsx"
---
# React Testing

> This file extends [typescript/testing.md](../typescript/testing.md) and [common/testing.md](../common/testing.md) with React specific content.

Worked examples: skill `react-testing`.

## Library Choice

- **React Testing Library (RTL)** — the standard for component testing. Tests behavior through the rendered DOM.
- **Vitest** — preferred runner for new Vite-based projects. Faster than Jest, native ESM, same API.
- **Jest** — still the default for Next.js / CRA projects. RTL works identically.
- **Playwright Component Testing** — when component tests need a real browser engine (animation, layout, complex events)
- **Cypress Component Testing** — alternative real-browser component runner
- Pick one component test runner per project — do not mix RTL + Playwright CT in the same repo

## Core Principle

- Test what the user sees and does, not implementation details
- Query by accessible role first, then label, then text — fall back to `data-testid` only when nothing else fits
- Never assert on internal state, props passed to children, or which hooks were called
- Refactor without breaking tests = the test was testing behavior; that is the goal

## Query Priority

RTL exposes queries in three families. Use this priority order top-down:

1. **Accessible to everyone**
   - `getByRole(role, { name })` — primary choice
   - `getByLabelText` — for form inputs
   - `getByPlaceholderText` — when no label is available (and add a label)
   - `getByText` — for non-interactive text
   - `getByDisplayValue` — for form fields with a current value
2. **Semantic queries**
   - `getByAltText` — for images
   - `getByTitle` — last resort, low accessibility value
3. **Test IDs**
   - `getByTestId("some-id")` — escape hatch only, when none of the above work

`getBy*` throws when no match. `queryBy*` returns null (use for asserting absence). `findBy*` returns a promise (use for async).

## User Interaction

Prefer `userEvent` over `fireEvent`. `userEvent` simulates real browser sequences (focus, keydown, beforeinput, input, keyup) — `fireEvent` dispatches a single synthetic event.

- Always `await` `userEvent` calls — they are async
- Call `userEvent.setup()` once at the top of each test, then reuse the returned `user`

## Async Assertions

- `findBy*` for async element appearance
- `waitFor` for async expectations on side effects or other matchers
- Never `setTimeout` + assertion — flaky

## Network Mocking with MSW

Use Mock Service Worker for any test that hits a network boundary. MSW runs at the network layer, so the component, hooks, and fetch library all behave as in production. Start the server in `beforeAll`, reset handlers in `afterEach`, close in `afterAll`, and override per test with `server.use(...)`.

## Avoid Snapshot Tests for Components

Snapshots of rendered output are brittle, hard to review, and rubber-stamped by reviewers. Use them only for:

- Pure data serialization (e.g., a transformer that produces a stable string)
- Catching unintended regressions in non-visual output
- For component visual regression, use Playwright / Cypress / Percy screenshots — actual visual diffs, not DOM diffs

## Test Setup Helpers

Wrap providers once. Export from `test-utils.tsx` and use everywhere.

## Custom Hook Testing

Use `renderHook` from RTL.

- Always wrap state-changing calls in `act`
- Always test through the public hook API, not internal implementation

## Accessibility Assertions

Run axe assertions (`vitest-axe` or `jest-axe`) in component tests — catches missing labels, ARIA misuse, color contrast (limited).

## When to Reach for Playwright / Cypress

Component test with RTL + JSDOM cannot:

- Test real layout (flexbox, grid, viewport-dependent rendering)
- Test scrolling, drag-and-drop, paste from clipboard
- Test browser-native animation, CSS transitions
- Test cross-frame interactions (iframes, popups)
- For those, use Playwright Component Testing or end-to-end Playwright/Cypress runs. See [e2e-testing skill](../../skills/e2e-testing/SKILL.md)

## Coverage Targets

| Layer | Target |
|---|---|
| Pure utility functions | ≥90% |
| Custom hooks | ≥85% |
| Components (presentational) | Behavior covered, not line counts |
| Container components | ≥70% — golden paths + error states |
| Pages (E2E covered separately) | Smoke test per route minimum |

## Anti-Patterns

- Asserting on `container.querySelector` — bypasses accessibility queries
- Asserting on number of renders — implementation detail
- Mocking React hooks (`jest.mock("react", ...)`) — refactor the component instead
- Mocking child components by default — tests the integration, not the parent in isolation
- Manual `act()` warnings ignored — they indicate real bugs

## Skill Reference

See `skills/react-testing/SKILL.md` for end-to-end test examples, MSW patterns, and accessibility test scaffolding.
