-- Test Script: RLS Bypass Mechanism for analytics.api_usage_logs
-- Purpose: Verify set_config() approach for service role bypass
-- Database: {{DB_NAME}} (local) or {{DB_NAME}} (docker)
-- Date: 2026-01-09

-- =============================================================================
-- PART 1: Environment Check
-- =============================================================================

\echo '=== ENVIRONMENT CHECK ==='

-- Check current user and privileges
SELECT
    current_user as "Current User",
    (SELECT rolsuper FROM pg_roles WHERE rolname = current_user) as "Is Superuser",
    (SELECT rolbypassrls FROM pg_roles WHERE rolname = current_user) as "Has BYPASSRLS";

-- Check table RLS status
SELECT
    schemaname,
    tablename,
    rowsecurity as "RLS Enabled"
FROM pg_tables
WHERE schemaname = 'analytics' AND tablename = 'api_usage_logs';

-- Check RLS policies
SELECT
    polname as "Policy Name",
    polcmd as "Command",
    pg_get_expr(polqual, polrelid) as "Using Expression"
FROM pg_policy
WHERE polrelid = 'analytics.api_usage_logs'::regclass;

\echo ''

-- =============================================================================
-- PART 2: Test Syntax Options for Custom GUC Variables
-- =============================================================================

\echo '=== TESTING SYNTAX OPTIONS ==='

-- Test 1: SET LOCAL without quotes (SHOULD FAIL)
\echo 'Test 1: SET LOCAL without quotes'
BEGIN;
\set ON_ERROR_STOP off
SET LOCAL app.current_role = 'service';
\set ON_ERROR_STOP on
ROLLBACK;

-- Test 2: SET LOCAL with quotes (SHOULD WORK)
\echo 'Test 2: SET LOCAL with double quotes'
BEGIN;
SET LOCAL "app.current_role" = 'service';
SELECT current_setting('app.current_role', true) as "Result: SET LOCAL with quotes";
ROLLBACK;

-- Test 3: set_config() function (RECOMMENDED)
\echo 'Test 3: set_config() function'
BEGIN;
SELECT set_config('app.current_role', 'service', true) as "Result: set_config()";
SELECT current_setting('app.current_role', true) as "Verify Setting";
ROLLBACK;

\echo ''

-- =============================================================================
-- PART 3: Test Transaction-Local Scope
-- =============================================================================

\echo '=== TESTING TRANSACTION SCOPE ==='

-- Test transaction-local behavior
BEGIN;
SELECT set_config('app.current_role', 'service', true) as "Within Transaction";
SELECT current_setting('app.current_role', true) as "Check 1";
COMMIT;

SELECT current_setting('app.current_role', true) as "After COMMIT (should be empty)";

\echo ''

-- =============================================================================
-- PART 4: Test RLS Bypass (Only if user lacks BYPASSRLS)
-- =============================================================================

\echo '=== TESTING RLS BYPASS ==='

-- Show current RLS bypass status
DO $$
DECLARE
    has_bypass boolean;
BEGIN
    SELECT rolbypassrls INTO has_bypass FROM pg_roles WHERE rolname = current_user;

    IF has_bypass THEN
        RAISE NOTICE 'Current user has BYPASSRLS privilege - RLS is NOT enforced';
        RAISE NOTICE 'RLS bypass mechanism cannot be tested with this user';
        RAISE NOTICE 'Connect as a restricted user (e.g., "{{PROJECT_SLUG}}" in Docker) to test';
    ELSE
        RAISE NOTICE 'Current user lacks BYPASSRLS - RLS IS enforced';
        RAISE NOTICE 'Proceeding with RLS bypass tests...';
    END IF;
END $$;

-- Only run these tests if user lacks BYPASSRLS
DO $$
DECLARE
    has_bypass boolean;
BEGIN
    SELECT rolbypassrls INTO has_bypass FROM pg_roles WHERE rolname = current_user;

    IF NOT has_bypass THEN
        -- Test WITHOUT service role (should fail)
        BEGIN
            RAISE NOTICE 'Test A: INSERT without service role (should fail)';
            BEGIN
                INSERT INTO analytics.api_usage_logs (
                    tenant_id, method, route, status_code, duration_ms, created_at
                ) VALUES (1, 'GET', '/test-no-bypass', 200, 10, NOW());
                RAISE NOTICE 'UNEXPECTED: Insert succeeded without service role';
            EXCEPTION WHEN insufficient_privilege THEN
                RAISE NOTICE 'EXPECTED: RLS policy violation - %', SQLERRM;
            END;
        END;

        -- Test WITH service role (should succeed)
        BEGIN
            RAISE NOTICE 'Test B: INSERT with service role (should succeed)';
            PERFORM set_config('app.current_role', 'service', true);
            INSERT INTO analytics.api_usage_logs (
                tenant_id, method, route, status_code, duration_ms, created_at
            ) VALUES (1, 'GET', '/test-with-bypass', 200, 10, NOW());
            RAISE NOTICE 'SUCCESS: Insert bypassed RLS via service role';
        END;

        -- Test batch insert with service role
        BEGIN
            RAISE NOTICE 'Test C: Batch INSERT with service role (should succeed)';
            PERFORM set_config('app.current_role', 'service', true);
            INSERT INTO analytics.api_usage_logs (
                tenant_id, method, route, status_code, duration_ms, created_at
            ) VALUES
                (1, 'GET', '/test-batch-1', 200, 10, NOW()),
                (2, 'POST', '/test-batch-2', 201, 25, NOW()),
                (999, 'PUT', '/test-batch-3', 200, 15, NOW());
            RAISE NOTICE 'SUCCESS: Batch insert bypassed RLS (3 rows, different tenants)';
        END;
    END IF;
END $$;

\echo ''

-- =============================================================================
-- PART 5: Cleanup Test Data (if any inserted)
-- =============================================================================

\echo '=== CLEANUP ==='

DELETE FROM analytics.api_usage_logs
WHERE route LIKE '/test-%'
RETURNING id, tenant_id, route, 'Cleaned up test record' as status;

\echo ''
\echo '=== TEST COMPLETE ==='
\echo ''
\echo 'Summary:'
\echo '  - Use: SELECT set_config(''app.current_role'', ''service'', true)'
\echo '  - This is transaction-local and works with RLS bypass policy'
\echo '  - DO NOT use: SET LOCAL app.current_role (syntax error)'
\echo '  - Alternative: SET LOCAL "app.current_role" = ''service'' (works but verbose)'