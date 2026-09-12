## Stack Rules — Vue 3

- `<script setup>` with TypeScript; Composition API only in new code
- State: `ref` and `computed` locally, Pinia for shared state, one store per domain; no prop drilling deeper than two levels
- Props typed and validated; emits declared; v-model on custom components follows the `modelValue` convention
- Composables for reusable logic, named `useX`, returning readonly state where the caller must not mutate
- Router: lazy-loaded views, guards resolve auth before rendering, no logic in route files
- Tests: Vitest with Vue Test Utils for components; behavioural suites against the running app for verification
- `vue-tsc --noEmit` and the production build clean
