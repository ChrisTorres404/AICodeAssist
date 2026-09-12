## Stack Rules — PHP (Laravel)

- PSR-12; strict types (`declare(strict_types=1)`); typed properties and return types everywhere
- Eloquent with eager loading on every list; `with()` and `withCount()`; N+1 is a review finding
- Form requests validate at the boundary; controllers stay thin; services or actions hold logic
- Policies or gates on every route; `authorize()` against the model, not the role
- Migrations are the only schema path; seeders for reference data, never manual inserts
- Queued jobs are idempotent; failures land in `failed_jobs` and are alerted
- Pest or PHPUnit with database transactions per test; behavioural suites for verification
