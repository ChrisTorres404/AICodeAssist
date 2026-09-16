---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/hooks/**/*.ts"
  - "**/hooks/**/*.js"
  - "**/use-*.ts"
  - "**/use*.ts"
---
# React Hooks

> This file extends [patterns.md](./patterns.md) and [coding-style.md](./coding-style.md) with the hook-specific ruleset.

Worked examples: skill `react-patterns`.

## Rules of Hooks

- Call hooks at the top level of a component or another hook — never inside a condition, loop, early return, or nested function
- Group every hook call above the first conditional in the component body, so the call order is visible at a glance
- Call hooks only from a React function component or a custom hook; never from a plain helper, a class method, or an event handler
- Keep `eslint-plugin-react-hooks` enabled with `rules-of-hooks` at error and `exhaustive-deps` at warn or error. Do not disable either inline without a comment saying why

## Custom Hook Naming and Return Shape

- The name starts with `use`, and a function that does not call a hook is not a hook — make it a plain function
- One responsibility per hook. A hook that fetches, caches, and formats is three hooks
- Return a tuple for a hook with two obvious positional values (`const [value, setValue] = useToggle()`), and a named object for anything wider (`const { data, error, isLoading } = useOrders()`)
- Keep the return shape stable across every branch. A hook that returns `undefined` while loading and an object afterwards forces every caller to narrow
- Extract a custom hook only when the same hook sequence appears in two or more components. A one-line wrapper around `useState` is noise
- Colocate the hook with its consumer until a second consumer exists, then move it to `hooks/`

## Dependency Arrays

- List every value from the component scope that the effect, memo, or callback reads. The linter is right more often than the author
- Never silence `exhaustive-deps` by trimming the array. Fix the cause instead: move the value inside, wrap it in `useCallback`, or hoist it out of the component
- A value that never changes — a module constant, a `useRef` current, a stable dispatch — belongs outside the component or in a ref, not omitted from the array
- Use the functional updater when the new state derives from the old (`setCount(prev => prev + 1)`); it removes the state from the dependency array
- An empty array means "run once on mount" and is a claim about the effect, not a way to stop it re-running

## Effect Cleanup

- Every subscription, interval, timeout, listener, observer, and abort controller is torn down in the returned cleanup function
- An async effect needs a cancellation flag or an `AbortController`. Without one, StrictMode's double-invoke in development and any fast navigation both produce out-of-order responses and updates against an unmounted tree

```typescript
useEffect(() => {
  let cancelled = false;

  load().then((data) => {
    if (!cancelled) setData(data);
  });

  return () => {
    cancelled = true;
  };
}, []);
```

- Cleanup runs before every re-run, not only on unmount. Write it so that running it twice is harmless
- Do not use an effect to derive state from props — compute it during render

## Data-Fetching Hooks

- Prefer a server-state library (TanStack Query, SWR) or a server component over a hand-rolled `useEffect` fetch. The hand-rolled version has no cache, no retry, no deduplication, and no Suspense integration
- When a hand-rolled fetch is unavoidable, it carries the cancellation flag above, and it reports all three of `data`, `error`, and `isLoading`
- One hook per query key. Defer a dependent query with the library's `enabled` flag rather than an early return
- Invalidate through the library's cache API after a mutation; never mutate the cache by hand
- Never call a data-fetching hook conditionally to "skip" a request — pass the skip through the hook's own parameter

## Memoization

The default position is not to memoize. Add `useMemo` or `useCallback` only when a profiler measurement or a dependency chain into a memoized child proves it matters, and say which in a comment. Premature memoization adds dependency arrays that then go stale.
