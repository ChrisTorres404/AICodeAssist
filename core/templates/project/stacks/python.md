## Stack Rules — Python (Django / FastAPI / services)

- Type hints on every signature; `mypy --strict` or `pyright` clean; `ruff check` and `ruff format` clean
- `logging.getLogger(__name__)`, never `print`; structured `extra` with ids
- Settings from a validated settings object; nothing reads `os.environ` directly
- ORM queries use `select_related`/`prefetch_related` (Django) or explicit joins (SQLAlchemy) on every list endpoint; raw SQL only parameterised
- Migrations committed and applied in every environment; never `--fake` outside a documented recovery
- Permission classes or auth dependencies on every view or route; object-level checks against the resource
- Serializers or Pydantic models validate at the boundary; views and handlers stay thin
- Async code never blocks: no `requests`, `time.sleep`, or sync drivers inside `async def`
- `pytest` with function-scoped fixtures; behavioural suites against the running service for verification
