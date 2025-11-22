#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .sh)

  echo ""
  echo "========================================="
  echo "Running: $test_name"
  echo "========================================="

  if bash "$test_file"; then
    echo "✅ PASS: $test_name"
    return 0
  else
    echo "❌ FAIL: $test_name"
    return 1
  fi
}

main() {
  local failed=0
  local passed=0
  local total=0

  echo "Starting Session Management v2 Test Suite"
  echo "========================================="

  for test in "${SCRIPT_DIR}"/test-*.sh; do
    if [[ -f "$test" && "$test" != *"test-runner.sh" ]]; then
      total=$((total + 1))

      if run_test "$test"; then
        passed=$((passed + 1))
      else
        failed=$((failed + 1))
      fi
    fi
  done

  echo ""
  echo "========================================="
  echo "Test Results"
  echo "========================================="
  echo "Total:  $total"
  echo "Passed: $passed"
  echo "Failed: $failed"
  echo ""

  if [[ $failed -eq 0 ]]; then
    echo "✅ All tests passed"
    exit 0
  else
    echo "❌ $failed test(s) failed"
    exit 1
  fi
}

main "$@"
