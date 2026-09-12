-- ============================================================================
-- rls-check.sql — verify row-level security on one table, and the GUC used to
-- scope it, without writing anything.
-- ============================================================================
-- Postgres row-level security is usually driven by a session/transaction
-- setting (a custom GUC) that the application sets per request. Three things
-- have to hold for that design to actually protect anything, and this script
-- reports all three:
--
--   1. RLS is enabled — and FORCEd, or a table owner bypasses it silently
--   2. policies exist, and their expressions reference the GUC
--   3. the connecting role does not hold BYPASSRLS or superuser
--
-- Usage:
--   psql -d mydb \
--     -v schema=public -v table=documents -v guc=app.current_scope \
--     -f rls-check.sql
--
-- Defaults are supplied for all three, so a missing -v is a clear failure
-- rather than a syntax error. Read-only: no INSERT, UPDATE, or DELETE.
-- ============================================================================

\if :{?schema}
\else
  \set schema 'public'
\endif
\if :{?table}
\else
  \set table '__unset__'
\endif
\if :{?guc}
\else
  \set guc 'app.current_scope'
\endif

\set qualified :schema '.' :table

\echo '=== ROLE ==='

SELECT
    current_user                                                      AS "role",
    (SELECT rolsuper      FROM pg_roles WHERE rolname = current_user) AS "is superuser",
    (SELECT rolbypassrls  FROM pg_roles WHERE rolname = current_user) AS "has BYPASSRLS";

\echo ''
\echo '=== TABLE ==='

SELECT
    n.nspname                AS "schema",
    c.relname                AS "table",
    c.relrowsecurity         AS "RLS enabled",
    c.relforcerowsecurity    AS "RLS forced (applies to owner)"
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = :'schema' AND c.relname = :'table';

\echo ''
\echo '=== POLICIES ==='

SELECT
    pol.polname                              AS "policy",
    CASE pol.polcmd
        WHEN 'r' THEN 'SELECT' WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE' WHEN 'd' THEN 'DELETE'
        ELSE 'ALL'
    END                                      AS "command",
    pg_get_expr(pol.polqual, pol.polrelid)      AS "USING",
    pg_get_expr(pol.polwithcheck, pol.polrelid) AS "WITH CHECK"
FROM pg_policy pol
JOIN pg_class c      ON c.oid = pol.polrelid
JOIN pg_namespace n  ON n.oid = c.relnamespace
WHERE n.nspname = :'schema' AND c.relname = :'table'
ORDER BY pol.polname;

\echo ''
\echo '=== GUC BEHAVIOUR ==='
-- set_config(..., true) is transaction-local: the correct way to scope a
-- request, because the value cannot leak to the next user of a pooled
-- connection. (SET LOCAL needs the name quoted when it contains a dot;
-- set_config() avoids that trap entirely.)

BEGIN;
SELECT set_config(:'guc', 'probe-value', true) AS "set within transaction";
SELECT current_setting(:'guc', true)           AS "readable inside";
COMMIT;

SELECT coalesce(nullif(current_setting(:'guc', true), ''), '(unset)') AS "after COMMIT — expect unset";

\echo ''
\echo '=== FINDINGS ==='

WITH t AS (
    SELECT c.oid, c.relrowsecurity, c.relforcerowsecurity
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = :'schema' AND c.relname = :'table'
)
SELECT finding, detail FROM (
    SELECT 1 AS ord, 'table not found' AS finding,
           :'qualified' || ' does not exist' AS detail
    WHERE NOT EXISTS (SELECT 1 FROM t)
    UNION ALL
    SELECT 2, 'RLS disabled', 'no row-level security on ' || :'qualified'
    FROM t WHERE NOT relrowsecurity
    UNION ALL
    SELECT 3, 'RLS not forced', 'the table owner bypasses these policies (ALTER TABLE ... FORCE ROW LEVEL SECURITY)'
    FROM t WHERE relrowsecurity AND NOT relforcerowsecurity
    UNION ALL
    SELECT 4, 'no policies', 'RLS is on but no policy exists — the table denies everything'
    FROM t WHERE relrowsecurity
      AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = t.oid)
    UNION ALL
    SELECT 5, 'policies ignore the GUC',
           'no policy expression references ' || :'guc'
    FROM t WHERE EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = t.oid)
      AND NOT EXISTS (
        SELECT 1 FROM pg_policy p
        WHERE p.polrelid = t.oid
          AND (coalesce(pg_get_expr(p.polqual, p.polrelid), '')
               || coalesce(pg_get_expr(p.polwithcheck, p.polrelid), '')) LIKE '%' || :'guc' || '%')
    UNION ALL
    SELECT 6, 'connected role bypasses RLS',
           current_user || ' is superuser or has BYPASSRLS — policies are not enforced for this connection'
    FROM pg_roles WHERE rolname = current_user AND (rolsuper OR rolbypassrls)
) f
ORDER BY ord;

\echo ''
\echo 'No rows under FINDINGS means: RLS enabled and forced, policies present and'
\echo 'referencing the GUC, and this connection is subject to them.'
