#!/bin/bash
# Shared Test Helper Functions
# Source this in your test suites: source ../../scripts/test-helpers.sh

# ====================================================================
# HTTP Test Helpers
# ====================================================================

# Assert HTTP status code
assert_http_status() {
  local test_name="$1"
  local url="$2"
  local expected_status="$3"
  local method="${4:-GET}"
  local data="${5:-}"

  echo "Test: $test_name"

  if [ -n "$data" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -d "$data")
  else
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$url")
  fi

  HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

  if [ "$HTTP_CODE" = "$expected_status" ]; then
    echo "  ✅ PASS (status: $HTTP_CODE)"
    return 0
  else
    echo "  ❌ FAIL (expected: $expected_status, got: $HTTP_CODE)"
    return 1
  fi
}

# Extract JSON field from response
extract_json_field() {
  local response="$1"
  local field="$2"

  echo "$response" | jq -r ".$field"
}

# ====================================================================
# SQL Test Helpers
# ====================================================================

# Execute SQL and check result contains pattern
assert_sql_contains() {
  local test_name="$1"
  local query="$2"
  local expected_pattern="$3"

  echo "SQL Test: $test_name"

  RESULT=$(PGPASSWORD="${DB_PASS:-password}" psql \
    -U "${DB_USER:-{{PROJECT_SLUG}}}" \
    -h localhost \
    -d "${DB_NAME:-{{DB_NAME}}}" \
    -t -c "$query" 2>&1)

  if echo "$RESULT" | grep -q "$expected_pattern"; then
    echo "  ✅ PASS"
    return 0
  else
    echo "  ❌ FAIL (expected: $expected_pattern)"
    echo "  Got: $RESULT"
    return 1
  fi
}

# Execute SQL and return result
run_sql() {
  local query="$1"

  PGPASSWORD="${DB_PASS:-password}" psql \
    -U "${DB_USER:-{{PROJECT_SLUG}}}" \
    -h localhost \
    -d "${DB_NAME:-{{DB_NAME}}}" \
    -t -c "$query"
}

# ====================================================================
# Wait/Timing Helpers
# ====================================================================

# Wait for server to be ready
wait_for_server() {
  local url="${1:-http://localhost:3001/api/v1/metrics}"
  local max_wait="${2:-30}"

  echo "Waiting for server at $url..."

  for i in $(seq 1 $max_wait); do
    if curl -s "$url" > /dev/null 2>&1; then
      echo "  ✅ Server ready!"
      return 0
    fi
    echo "  Waiting... ($i/$max_wait)"
    sleep 1
  done

  echo "  ❌ Server not ready after ${max_wait}s"
  return 1
}

# ====================================================================
# Test Data Helpers
# ====================================================================

# Create test user
create_test_user() {
  local email="$1"
  local password="${2:-TestPassword123!}"

  RESPONSE=$(curl -s -X POST "${API_BASE:-http://localhost:3001/api/v1}/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$password\",\"first_name\":\"Test\",\"last_name\":\"User\"}")

  echo "$RESPONSE"
}

# Delete test user
delete_test_user() {
  local email="$1"

  run_sql "DELETE FROM auth.users WHERE email = '$email';"
}

# ====================================================================
# Metric Helpers
# ====================================================================

# Get Prometheus metric value
get_metric_value() {
  local metric_name="$1"

  curl -s "${API_BASE:-http://localhost:3001/api/v1}/metrics" \
    | grep "^$metric_name " \
    | awk '{print $2}'
}

# Get metric delta (before/after)
measure_metric_delta() {
  local metric_name="$1"
  local action_command="$2"

  BEFORE=$(get_metric_value "$metric_name")
  eval "$action_command"
  AFTER=$(get_metric_value "$metric_name")

  echo $((AFTER - BEFORE))
}