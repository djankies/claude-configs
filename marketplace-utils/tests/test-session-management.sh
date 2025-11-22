#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$UTILS_DIR/session-management.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  ✓ $message"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  ✗ $message"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ -f "$file" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  ✓ $message"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  ✗ $message"
  fi
}

assert_true() {
  local condition="$1"
  local message="${2:-Condition should be true}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$condition"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  ✓ $message"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  ✗ $message"
  fi
}

cleanup_test_files() {
  rm -f /tmp/claude-test-*.json /tmp/claude-test-*.lock
  rm -f /tmp/claude-session-*.json /tmp/claude-session-*.lock
}

trap cleanup_test_files EXIT

echo "Running session-management.sh tests..."
echo

echo "Test: Session initialization"
init_session "test-plugin"
assert_file_exists "$SESSION_FILE" "Session file created"
assert_equals "test-plugin" "$PLUGIN_NAME" "Plugin name set"
echo

echo "Test: Get/set session values"
init_session "test-plugin-2"
set_session_value "test_key" '"test_value"'
result=$(get_session_value "test_key")
assert_equals "test_value" "$result" "Session value retrieved"
echo

echo "Test: Recommendation tracking"
init_session "test-plugin-3"
if has_shown_recommendation "test-plugin-3" "skill-name"; then
  assert_equals "false" "true" "Recommendation should not be shown initially"
else
  assert_equals "true" "true" "Recommendation not shown initially"
fi

mark_recommendation_shown "test-plugin-3" "skill-name"

if has_shown_recommendation "test-plugin-3" "skill-name"; then
  assert_equals "true" "true" "Recommendation marked as shown"
else
  assert_equals "true" "false" "Recommendation should be marked as shown"
fi
echo

echo "Test: Validation tracking"
init_session "test-plugin-4"
if has_passed_validation "type-check" "/path/to/file"; then
  assert_equals "false" "true" "Validation should not be passed initially"
else
  assert_equals "true" "true" "Validation not passed initially"
fi

mark_validation_passed "type-check" "/path/to/file"

if has_passed_validation "type-check" "/path/to/file"; then
  assert_equals "true" "true" "Validation marked as passed"
else
  assert_equals "true" "false" "Validation should be marked as passed"
fi
echo

echo "Test: Custom data"
init_session "test-plugin-5"
set_custom_data "custom_key" '"custom_value"'
result=$(get_custom_data "custom_key")
assert_equals "custom_value" "$result" "Custom data retrieved"
echo

echo "Test: Session age"
init_session "test-plugin-6"
age1=$(get_session_age)
sleep 2
age2=$(get_session_age)
assert_true '[[ $age2 -gt $age1 ]]' "Session age increases over time"
echo

echo "Test: File locking (acquire and release)"
if command -v flock >/dev/null 2>&1; then
  TEST_FILE="/tmp/test-lock-file.txt"
  echo "test" > "$TEST_FILE"

  if acquire_lock "$TEST_FILE" 5; then
    assert_equals "true" "true" "Lock acquired successfully"
    release_lock
    assert_equals "true" "true" "Lock released successfully"
  else
    assert_equals "true" "false" "Failed to acquire lock"
  fi

  rm -f "$TEST_FILE" "${TEST_FILE}.lock"
else
  echo "  ⊘ Skipping lock tests (flock not available)"
fi
echo

echo "Test: Cleanup session"
init_session "test-plugin-7"
SESSION_FILE_TO_CLEAN="$SESSION_FILE"
clear_session
assert_true '[[ ! -f "$SESSION_FILE_TO_CLEAN" ]]' "Session file removed"
echo

echo "Test: Multi-plugin session"
rm -f "$SESSION_FILE"
init_session "plugin-a"
init_session "plugin-b"

assert_file_exists "$SESSION_FILE" "Session file created"

if jq -e '.plugins."plugin-a"' "$SESSION_FILE" >/dev/null 2>&1; then
  assert_equals "true" "true" "plugin-a in session"
else
  assert_equals "true" "false" "plugin-a should be in session"
fi

if jq -e '.plugins."plugin-b"' "$SESSION_FILE" >/dev/null 2>&1; then
  assert_equals "true" "true" "plugin-b in session"
else
  assert_equals "true" "false" "plugin-b should be in session"
fi
echo

echo "================================"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi
