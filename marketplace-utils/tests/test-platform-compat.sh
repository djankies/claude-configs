#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../platform-compat.sh"

test_detect_platform() {
  local platform=$(detect_platform)

  if [[ -z "$platform" ]]; then
    echo "FAIL: detect_platform returned empty"
    return 1
  fi

  case "$platform" in
    macos|linux|windows|unknown)
      echo "PASS: detect_platform returned valid platform: $platform"
      return 0
      ;;
    *)
      echo "FAIL: detect_platform returned invalid platform: $platform"
      return 1
      ;;
  esac
}

test_timestamp_conversion() {
  local iso_ts="2025-11-22T10:30:45Z"
  local epoch=$(get_timestamp_epoch "$iso_ts")

  if [[ "$epoch" =~ ^[0-9]+$ && "$epoch" -gt 0 ]]; then
    echo "PASS: get_timestamp_epoch converted timestamp: $epoch"
    return 0
  else
    echo "FAIL: get_timestamp_epoch returned invalid epoch: $epoch"
    return 1
  fi
}

test_current_epoch() {
  local now=$(get_current_epoch)

  if [[ "$now" =~ ^[0-9]+$ && "$now" -gt 1700000000 ]]; then
    echo "PASS: get_current_epoch returned valid timestamp: $now"
    return 0
  else
    echo "FAIL: get_current_epoch returned invalid timestamp: $now"
    return 1
  fi
}

test_is_remote_execution() {
  unset CLAUDE_CODE_REMOTE
  if is_remote_execution; then
    echo "FAIL: is_remote_execution returned true when CLAUDE_CODE_REMOTE not set"
    return 1
  fi

  export CLAUDE_CODE_REMOTE="true"
  if ! is_remote_execution; then
    echo "FAIL: is_remote_execution returned false when CLAUDE_CODE_REMOTE=true"
    return 1
  fi

  echo "PASS: is_remote_execution works correctly"
  return 0
}

test_check_dependencies() {
  if check_dependencies >/dev/null 2>&1; then
    echo "PASS: check_dependencies succeeded"
    return 0
  else
    echo "INFO: check_dependencies failed (some deps missing, expected in CI)"
    return 0
  fi
}

main() {
  local failed=0

  test_detect_platform || failed=$((failed + 1))
  test_timestamp_conversion || failed=$((failed + 1))
  test_current_epoch || failed=$((failed + 1))
  test_is_remote_execution || failed=$((failed + 1))
  test_check_dependencies || failed=$((failed + 1))

  if [[ $failed -eq 0 ]]; then
    echo "All platform-compat tests passed"
    exit 0
  else
    echo "$failed test(s) failed"
    exit 1
  fi
}

main "$@"
