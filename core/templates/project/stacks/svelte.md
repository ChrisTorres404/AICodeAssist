## Stack Rules — Svelte / SvelteKit

- Runes (`$state`, `$derived`, `$effect`) in new components; stores only for cross-page state
- Data loads in `+page.server.ts` or `+layout.server.ts`; mutations through form actions with server-side validation; secrets never reach the client
- `+page.ts` load functions stay pure; fetch through the provided `fetch`
- Components under 200 lines; one component per file; props typed
- Tests: Vitest for logic, Playwright for flows; behavioural suites against the running app for verification
- `svelte-check` and the production build clean
