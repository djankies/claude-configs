#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CLAUDE_SESSION_PID=$$
export CLAUDE_MARKETPLACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/../hook-lifecycle.sh"

cleanup() {
  rm -f "/tmp/claude-session-$$.json"
  rm -f "/tmp/claude-session-$$.log"
  rm -f "/tmp/claude-errors-$$.jsonl"
}
trap cleanup EXIT

test_init_hook() {
  init_hook "test-plugin" "test-hook"

  if [[ "$PLUGIN_NAME" != "test-plugin" ]]; then
    echo "FAIL: PLUGIN_NAME not set correctly: $PLUGIN_NAME"
    return 1
  fi

  if [[ "$HOOK_NAME" != "test-hook" ]]; then
    echo "FAIL: HOOK_NAME not set correctly: $HOOK_NAME"
    return 1
  fi

  if [[ ! -f "$SESSION_FILE" ]]; then
    echo "FAIL: Session file not created"
    return 1
  fi

  echo "PASS: init_hook works correctly"
  return 0
}

test_read_hook_input() {
  local input='{"tool_name":"Write","tool_input":{"file_path":"test.ts"}}'

  local result=$(echo "$input" | read_hook_input)

  if [[ "$result" != "$input" ]]; then
    echo "FAIL: read_hook_input didn't return input correctly"
    return 1
  fi

  echo "PASS: read_hook_input works correctly"
  return 0
}

test_get_input_field() {
  export HOOK_INPUT='{"tool_name":"Write","tool_input":{"file_path":"test.ts"}}'

  local tool_name=$(get_input_field "tool_name")
  if [[ "$tool_name" != "Write" ]]; then
    echo "FAIL: get_input_field didn't extract tool_name: $tool_name"
    return 1
  fi

  local file_path=$(get_input_field "tool_input.file_path")
  if [[ "$file_path" != "test.ts" ]]; then
    echo "FAIL: get_input_field didn't extract nested field: $file_path"
    return 1
  fi

  echo "PASS: get_input_field works correctly"
  return 0
}

test_pretooluse_respond() {
  local response=$(pretooluse_respond "allow" "Test reason")

  if ! echo "$response" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null 2>&1; then
    echo "FAIL: pretooluse_respond didn't generate correct decision: $response"
    return 1
  fi

  if ! echo "$response" | jq -e '.hookSpecificOutput.permissionDecisionReason == "Test reason"' >/dev/null 2>&1; then
    echo "FAIL: pretooluse_respond didn't include reason: $response"
    return 1
  fi

  echo "PASS: pretooluse_respond works correctly"
  return 0
}

main() {
  local failed=0

  test_init_hook || failed=$((failed + 1))
  test_read_hook_input || failed=$((failed + 1))
  test_get_input_field || failed=$((failed + 1))
  test_pretooluse_respond || failed=$((failed + 1))

  if [[ $failed -eq 0 ]]; then
    echo "All hook-lifecycle tests passed"
    exit 0
  else
    echo "$failed test(s) failed"
    exit 1
  fi
}

main "$@"
