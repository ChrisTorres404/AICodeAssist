## Stack Rules — Ruby (Rails)

- RuboCop clean; service objects for logic; controllers thin; models own validations
- `includes`/`preload` on every list; strong parameters on every action; Pundit or CanCan policies per resource
- Migrations reversible and committed; `db/seeds.rb` for reference data, never console inserts in shared environments
- Background jobs idempotent with retries and a dead-letter path
- RSpec with `let` over instance variables, request specs for behaviour; behavioural suites for verification
