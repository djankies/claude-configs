#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FORMAT="json"

usage() {
  cat <<EOF
USAGE: validate-hook-exit-codes.sh [OPTIONS] <hook-script> <test-cases.json>

Validates hook script exit codes against expected values.

Options:
  --summary    Output one-line summary
  --json       Output full JSON (default)

Test cases JSON format:
{
  "cases": [
    {
      "name": "test name",
      "input": { ... },
      "expected_exit": 0
    }
  ]
}

Exit codes:
  0 - All test cases passed
  1 - One or more test cases failed
  2 - Usage error or invalid input
EOF
  exit 2
}

while [[ $# -gt 0 && "$1" == --* ]]; do
  case "$1" in
    --summary) OUTPUT_FORMAT="summary"; shift ;;
    --json) OUTPUT_FORMAT="json"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

[[ $# -lt 2 ]] && usage

HOOK_SCRIPT="$1"
TEST_CASES="$2"

if [[ ! -x "$HOOK_SCRIPT" ]]; then
  echo "ERROR: Hook script not found or not executable: $HOOK_SCRIPT" >&2
  exit 2
fi

if [[ ! -f "$TEST_CASES" ]]; then
  echo "ERROR: Test cases file not found: $TEST_CASES" >&2
  exit 2
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed" >&2
  exit 2
fi

if ! jq empty "$TEST_CASES" 2>/dev/null; then
  echo "ERROR: Invalid JSON in test cases file" >&2
  exit 2
fi

TOTAL=0
PASSED=0
FAILED=0
RESULTS="[]"

NUM_CASES=$(jq '.cases | length' "$TEST_CASES")

for ((i = 0; i < NUM_CASES; i++)); do
  CASE_NAME=$(jq -r ".cases[$i].name // \"case_$i\"" "$TEST_CASES")
  CASE_INPUT=$(jq -c ".cases[$i].input" "$TEST_CASES")
  EXPECTED_EXIT=$(jq -r ".cases[$i].expected_exit" "$TEST_CASES")

  TOTAL=$((TOTAL + 1))

  set +e
  ACTUAL_OUTPUT=$(echo "$CASE_INPUT" | "$HOOK_SCRIPT" 2>&1)
  ACTUAL_EXIT=$?
  set -e

  if [[ "$ACTUAL_EXIT" -eq "$EXPECTED_EXIT" ]]; then
    STATUS="pass"
    PASSED=$((PASSED + 1))
  else
    STATUS="fail"
    FAILED=$((FAILED + 1))
  fi

  RESULT=$(jq -n \
    --arg name "$CASE_NAME" \
    --arg status "$STATUS" \
    --argjson expected "$EXPECTED_EXIT" \
    --argjson actual "$ACTUAL_EXIT" \
    '{name: $name, status: $status, expected_exit: $expected, actual_exit: $actual}')

  RESULTS=$(echo "$RESULTS" | jq --argjson r "$RESULT" '. + [$r]')
done

COMPLIANT="true"
[[ $FAILED -gt 0 ]] && COMPLIANT="false"

HOOK_NAME=$(basename "$HOOK_SCRIPT")

if [[ "$OUTPUT_FORMAT" == "summary" ]]; then
  if [[ "$COMPLIANT" == "true" ]]; then
    printf "✅ %-40s passed=%d/%d\n" "$HOOK_NAME" "$PASSED" "$TOTAL"
  else
    printf "❌ %-40s passed=%d/%d failed=%d\n" "$HOOK_NAME" "$PASSED" "$TOTAL" "$FAILED"
  fi
else
  jq -n \
    --arg review_type "hook_exit_codes" \
    --arg hook "$HOOK_NAME" \
    --argjson total "$TOTAL" \
    --argjson passed "$PASSED" \
    --argjson failed "$FAILED" \
    --argjson results "$RESULTS" \
    --argjson compliant "$COMPLIANT" \
    '{
      review_type: $review_type,
      hook: $hook,
      summary: {total: $total, passed: $passed, failed: $failed},
      results: $results,
      compliant: $compliant
    }'
fi

[[ $FAILED -eq 0 ]]
