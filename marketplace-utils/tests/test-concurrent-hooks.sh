#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CLAUDE_SESSION_PID=$$
export CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SESSION_FILE="/tmp/claude-test-concurrent-$$.json"

cleanup() {
  rm -f "$SESSION_FILE" "${SESSION_FILE}.lock"
  rm -f "/tmp/claude-test-concurrent-$$-"*.log
}
trap cleanup EXIT

test_concurrent_updates() {
  source "${SCRIPT_DIR}/../hook-lifecycle.sh"

  init_session "test-plugin"

  local pids=()

  for i in {1..10}; do
    (
      export HOOK_NAME="hook-$i"
      set_plugin_value "test-plugin" "counter_$i" "$i"
    ) &
    pids+=($!)
  done

  for pid in "${pids[@]}"; do
    wait "$pid"
  done

  for i in {1..10}; do
    local value=$(get_plugin_value "test-plugin" "counter_$i")
    if [[ "$value" != "$i" ]]; then
      echo "FAIL: Concurrent update lost data: counter_$i = $value (expected $i)"
      return 1
    fi
  done

  echo "PASS: Concurrent updates work correctly"
  return 0
}

main() {
  test_concurrent_updates || exit 1
  echo "All concurrent hook tests passed"
  exit 0
}

main "$@"
