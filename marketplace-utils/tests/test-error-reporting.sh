#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../platform-compat.sh"
source "${SCRIPT_DIR}/../logging.sh"

export CLAUDE_SESSION_PID=$$
export ERROR_JOURNAL="/tmp/claude-test-errors-$$.jsonl"
export PLUGIN_NAME="test-plugin"
export HOOK_NAME="test-hook"

source "${SCRIPT_DIR}/../error-reporting.sh"

cleanup() {
  rm -f "$ERROR_JOURNAL"
}
trap cleanup EXIT

test_report_error() {
  report_error "TEST_ERROR" "Test error message" '{"file":"test.ts"}'

  if [[ ! -f "$ERROR_JOURNAL" ]]; then
    echo "FAIL: Error journal not created"
    return 1
  fi

  local line=$(tail -1 "$ERROR_JOURNAL")

  if ! echo "$line" | jq -e '.code == "TEST_ERROR"' >/dev/null 2>&1; then
    echo "FAIL: Error code not in journal: $line"
    return 1
  fi

  if ! echo "$line" | jq -e '.message == "Test error message"' >/dev/null 2>&1; then
    echo "FAIL: Error message not in journal: $line"
    return 1
  fi

  if ! echo "$line" | jq -e '.level == "ERROR"' >/dev/null 2>&1; then
    echo "FAIL: Error level not in journal: $line"
    return 1
  fi

  echo "PASS: report_error works correctly"
  return 0
}

test_report_warning() {
  rm -f "$ERROR_JOURNAL"

  report_warning "TEST_WARNING" "Test warning message"

  local line=$(tail -1 "$ERROR_JOURNAL")

  if ! echo "$line" | jq -e '.level == "WARN"' >/dev/null 2>&1; then
    echo "FAIL: Warning level not in journal: $line"
    return 1
  fi

  echo "PASS: report_warning works correctly"
  return 0
}

test_error_context() {
  rm -f "$ERROR_JOURNAL"

  report_error "TEST_CONTEXT" "Test with context" '{"file":"app.ts","line":42}'

  local line=$(tail -1 "$ERROR_JOURNAL")

  if ! echo "$line" | jq -e '.context.file == "app.ts"' >/dev/null 2>&1; then
    echo "FAIL: Context not preserved: $line"
    return 1
  fi

  if ! echo "$line" | jq -e '.context.line == 42' >/dev/null 2>&1; then
    echo "FAIL: Context line not preserved: $line"
    return 1
  fi

  echo "PASS: Error context preserved correctly"
  return 0
}

main() {
  local failed=0

  test_report_error || failed=$((failed + 1))
  test_report_warning || failed=$((failed + 1))
  test_error_context || failed=$((failed + 1))

  if [[ $failed -eq 0 ]]; then
    echo "All error-reporting tests passed"
    exit 0
  else
    echo "$failed test(s) failed"
    exit 1
  fi
}

main "$@"
