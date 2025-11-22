#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CLAUDE_SESSION_PID=$$
export CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cleanup() {
  rm -f "/tmp/claude-test-failure-$$.json"
  rm -f "/tmp/claude-test-failure-$$.log"
  rm -f "/tmp/claude-errors-$$.jsonl"
}
trap cleanup EXIT

test_fatal_error_cleanup() {
  source "${SCRIPT_DIR}/../hook-lifecycle.sh"

  init_hook "test-plugin" "test-hook"

  local error_file="/tmp/claude-errors-$$.jsonl"

  (fatal_error "TEST_FATAL" "Test fatal error" '{"test":"data"}' 2>/dev/null) || true

  if [[ ! -f "$error_file" ]]; then
    echo "FAIL: Error journal not created on fatal error"
    return 1
  fi

  if ! grep -q "FATAL" "$error_file"; then
    echo "FAIL: Fatal error not logged"
    return 1
  fi

  echo "PASS: Fatal error handling works correctly"
  return 0
}

main() {
  test_fatal_error_cleanup || exit 1
  echo "All hook failure tests passed"
  exit 0
}

main "$@"
