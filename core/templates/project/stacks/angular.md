## Stack Rules — Angular

- Standalone components, signals for local state, `inject()` over constructor injection in new code
- `OnPush` change detection everywhere; async pipe or signals in templates; no manual subscriptions without `takeUntilDestroyed`
- Feature areas are lazy-loaded routes with their own folder; shared UI in a shared library, never cross-imported between features
- Typed reactive forms; validation messages come from one place
- HTTP through typed services and interceptors; no direct `HttpClient` calls in components
- Tests: component tests with the Angular testing library or harnesses, `ng test` clean; behavioural suites against the running app for verification
- `ng build --configuration production` clean, with the budgets in `angular.json` respected
