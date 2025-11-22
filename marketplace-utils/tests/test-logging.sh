#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../platform-compat.sh"

export CLAUDE_SESSION_PID=$$
export LOG_FILE="/tmp/claude-test-logging-$$.log"
export PLUGIN_NAME="test-plugin"
export HOOK_NAME="test-hook"

source "${SCRIPT_DIR}/../logging.sh"

cleanup() {
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

test_log_levels() {
  export CLAUDE_DEBUG_LEVEL="DEBUG"

  log_debug "Debug message"
  log_info "Info message"
  log_warn "Warning message"
  log_error "Error message"

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "FAIL: Log file not created"
    return 1
  fi

  if ! grep -q "DEBUG" "$LOG_FILE"; then
    echo "FAIL: DEBUG message not logged"
    return 1
  fi

  if ! grep -q "INFO" "$LOG_FILE"; then
    echo "FAIL: INFO message not logged"
    return 1
  fi

  if ! grep -q "WARN" "$LOG_FILE"; then
    echo "FAIL: WARN message not logged"
    return 1
  fi

  if ! grep -q "ERROR" "$LOG_FILE"; then
    echo "FAIL: ERROR message not logged"
    return 1
  fi

  echo "PASS: All log levels work correctly"
  return 0
}

test_log_filtering() {
  rm -f "$LOG_FILE"
  export CLAUDE_DEBUG_LEVEL="WARN"

  log_debug "Should not appear"
  log_info "Should not appear"
  log_warn "Should appear"
  log_error "Should appear"

  if grep -q "DEBUG" "$LOG_FILE" 2>/dev/null; then
    echo "FAIL: DEBUG logged when level=WARN"
    return 1
  fi

  if grep -q "INFO" "$LOG_FILE" 2>/dev/null; then
    echo "FAIL: INFO logged when level=WARN"
    return 1
  fi

  if ! grep -q "WARN" "$LOG_FILE"; then
    echo "FAIL: WARN not logged when level=WARN"
    return 1
  fi

  echo "PASS: Log filtering works correctly"
  return 0
}

test_log_format() {
  rm -f "$LOG_FILE"
  export CLAUDE_DEBUG_LEVEL="DEBUG"

  log_info "Test message"

  local line=$(tail -1 "$LOG_FILE")

  if [[ ! "$line" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] ]]; then
    echo "FAIL: Missing timestamp in format: $line"
    return 1
  fi

  if [[ ! "$line" =~ \[test-plugin\] ]]; then
    echo "FAIL: Missing plugin name in format: $line"
    return 1
  fi

  if [[ ! "$line" =~ \[INFO\] ]]; then
    echo "FAIL: Missing level in format: $line"
    return 1
  fi

  echo "PASS: Log format is correct"
  return 0
}

main() {
  local failed=0

  test_log_levels || failed=$((failed + 1))
  test_log_filtering || failed=$((failed + 1))
  test_log_format || failed=$((failed + 1))

  if [[ $failed -eq 0 ]]; then
    echo "All logging tests passed"
    exit 0
  else
    echo "$failed test(s) failed"
    exit 1
  fi
}

main "$@"
