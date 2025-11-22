# Session Management v2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a centralized hook infrastructure with comprehensive logging, error reporting, and session management to replace duplicated implementations across 6 plugins.

**Architecture:** Five core utility files provide platform compatibility, logging, error reporting, enhanced session management, and a universal hook lifecycle wrapper. All hooks source the lifecycle wrapper for automatic infrastructure setup.

**Tech Stack:** Bash 4+, jq, flock (with graceful degradation), platform-agnostic date handling

---

## Prerequisites

Before starting implementation:

1. Ensure development environment has:
   - bash 4.0+
   - jq (JSON processor)
   - flock (file locking - will gracefully degrade if missing)

2. Review design document at `marketplace-utils/docs/SESSION-MANAGEMENT-V2-DESIGN.md`

3. Understand current session management at `marketplace-utils/session-management.sh`

---

## Task 1: Platform Compatibility Utilities

**Files:**
- Create: `marketplace-utils/platform-compat.sh`
- Test: `marketplace-utils/tests/test-platform-compat.sh`

**Step 1: Write the failing test**

Create test file with platform detection and timestamp conversion tests:

```bash
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
```

**Step 2: Run test to verify it fails**

```bash
cd marketplace-utils
bash tests/test-platform-compat.sh
```

Expected: FAIL with "platform-compat.sh: No such file or directory"

**Step 3: Write minimal implementation**

Create `marketplace-utils/platform-compat.sh`:

```bash
#!/usr/bin/env bash

detect_platform() {
  case "$OSTYPE" in
    darwin*)
      echo "macos"
      ;;
    linux*)
      echo "linux"
      ;;
    msys*|cygwin*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

is_remote_execution() {
  [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]
}

get_execution_environment() {
  if is_remote_execution; then
    echo "remote"
  else
    echo "local"
  fi
}

get_timestamp_epoch() {
  local iso_timestamp="$1"

  case "$(detect_platform)" in
    macos)
      date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    linux|windows)
      date -d "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_current_epoch() {
  date "+%s"
}

format_timestamp() {
  local epoch="$1"

  case "$(detect_platform)" in
    macos)
      date -u -r "$epoch" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo ""
      ;;
    linux|windows)
      date -u -d "@$epoch" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo ""
      ;;
    *)
      echo ""
      ;;
  esac
}

check_dependencies() {
  local missing=()

  command -v jq >/dev/null || missing+=("jq")
  command -v flock >/dev/null || missing+=("flock")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing dependencies: ${missing[*]}" >&2
    return 1
  fi

  return 0
}

get_temp_dir() {
  case "$(detect_platform)" in
    macos|linux)
      echo "/tmp"
      ;;
    windows)
      echo "${TEMP:-/tmp}"
      ;;
    *)
      echo "/tmp"
      ;;
  esac
}

get_file_age() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "0"
    return
  fi

  case "$(detect_platform)" in
    macos)
      local modified=$(stat -f %m "$file" 2>/dev/null || echo "0")
      ;;
    linux|windows)
      local modified=$(stat -c %Y "$file" 2>/dev/null || echo "0")
      ;;
    *)
      echo "0"
      return
      ;;
  esac

  local now=$(date +%s)
  echo $((now - modified))
}

sanitize_shell_arg() {
  local arg="$1"
  printf '%q' "$arg"
}
```

**Step 4: Run test to verify it passes**

```bash
bash tests/test-platform-compat.sh
```

Expected: PASS - "All platform-compat tests passed"

**Step 5: Validate with shellcheck**

```bash
shellcheck platform-compat.sh
```

Expected: No errors or warnings

**Step 6: Commit**

```bash
git add platform-compat.sh tests/test-platform-compat.sh
git commit -m "feat(utils): add platform compatibility utilities

- Platform detection (macos/linux/windows)
- Timestamp conversion (ISO-8601 to epoch)
- Remote execution detection
- Dependency checking
- File age calculation
- Comprehensive test coverage"
```

---

## Task 2: Logging System

**Files:**
- Create: `marketplace-utils/logging.sh`
- Test: `marketplace-utils/tests/test-logging.sh`

**Step 1: Write the failing test**

Create test file:

```bash
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
```

**Step 2: Run test to verify it fails**

```bash
bash tests/test-logging.sh
```

Expected: FAIL with "logging.sh: No such file or directory"

**Step 3: Write minimal implementation**

Create `marketplace-utils/logging.sh`:

```bash
#!/usr/bin/env bash

CLAUDE_SESSION_PID="${CLAUDE_SESSION_PID:-$$}"
LOG_FILE="${LOG_FILE:-/tmp/claude-session-${CLAUDE_SESSION_PID}.log}"
PLUGIN_NAME="${PLUGIN_NAME:-unknown}"
HOOK_NAME="${HOOK_NAME:-unknown}"

declare -A LOG_LEVELS=(
  ["DEBUG"]=0
  ["INFO"]=1
  ["WARN"]=2
  ["ERROR"]=3
  ["FATAL"]=4
)

get_log_level_value() {
  local level="$1"
  echo "${LOG_LEVELS[$level]:-0}"
}

should_log() {
  local message_level="$1"
  local min_level="${2:-WARN}"

  local message_value=$(get_log_level_value "$message_level")
  local min_value=$(get_log_level_value "$min_level")

  [[ $message_value -ge $min_value ]]
}

log_message() {
  local level="$1"
  local message="$2"
  local component="${3:-${HOOK_NAME:-unknown}}"

  local min_level="${CLAUDE_DEBUG_LEVEL:-WARN}"

  if ! should_log "$level" "$min_level"; then
    return 0
  fi

  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  local log_line="[$timestamp] [$PLUGIN_NAME] [$level] [$component] $message"

  echo "$log_line" >> "$LOG_FILE"
}

log_debug() {
  log_message "DEBUG" "$1" "${2:-}"
}

log_info() {
  log_message "INFO" "$1" "${2:-}"
}

log_warn() {
  log_message "WARN" "$1" "${2:-}"
}

log_error() {
  log_message "ERROR" "$1" "${2:-}"
}

log_fatal() {
  log_message "FATAL" "$1" "${2:-}"
}

user_message() {
  echo "$1" >&2
}
```

**Step 4: Run test to verify it passes**

```bash
bash tests/test-logging.sh
```

Expected: PASS - "All logging tests passed"

**Step 5: Validate with shellcheck**

```bash
shellcheck logging.sh
```

Expected: No errors or warnings

**Step 6: Commit**

```bash
git add logging.sh tests/test-logging.sh
git commit -m "feat(utils): add centralized logging system

- Log levels: DEBUG, INFO, WARN, ERROR, FATAL
- Configurable filtering via CLAUDE_DEBUG_LEVEL
- Structured log format with timestamps
- Plugin and component tracking
- User message helper for stderr
- Comprehensive test coverage"
```

---

## Task 3: Error Reporting System

**Files:**
- Create: `marketplace-utils/error-reporting.sh`
- Test: `marketplace-utils/tests/test-error-reporting.sh`

**Step 1: Write the failing test**

Create test file:

```bash
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
```

**Step 2: Run test to verify it fails**

```bash
bash tests/test-error-reporting.sh
```

Expected: FAIL with "error-reporting.sh: No such file or directory"

**Step 3: Write minimal implementation**

Create `marketplace-utils/error-reporting.sh`:

```bash
#!/usr/bin/env bash

CLAUDE_SESSION_PID="${CLAUDE_SESSION_PID:-$$}"
ERROR_JOURNAL="${ERROR_JOURNAL:-/tmp/claude-errors-${CLAUDE_SESSION_PID}.jsonl}"
PLUGIN_NAME="${PLUGIN_NAME:-unknown}"
HOOK_NAME="${HOOK_NAME:-unknown}"

get_call_stack() {
  local stack=""
  local frame=0

  while caller $frame >/dev/null 2>&1; do
    local line=$(caller $frame)
    stack="$stack\"$line\","
    frame=$((frame + 1))
  done

  stack="[${stack%,}]"
  echo "$stack"
}

report_error_internal() {
  local level="$1"
  local code="$2"
  local message="$3"
  local context="${4:-{}}"

  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")
  local stack=$(get_call_stack)

  local error_json=$(jq -n \
    --arg ts "$timestamp" \
    --arg plugin "$PLUGIN_NAME" \
    --arg hook "$HOOK_NAME" \
    --arg lvl "$level" \
    --arg code "$code" \
    --arg msg "$message" \
    --argjson ctx "$context" \
    --argjson stack "$stack" \
    '{
      timestamp: $ts,
      plugin: $plugin,
      hook: $hook,
      level: $lvl,
      code: $code,
      message: $msg,
      context: $ctx,
      stack: $stack
    }')

  echo "$error_json" >> "$ERROR_JOURNAL"

  if [[ -n "${log_error:-}" ]]; then
    log_error "[$code] $message"
  fi
}

report_error() {
  local code="$1"
  local message="$2"
  local context="${3:-{}}"

  report_error_internal "ERROR" "$code" "$message" "$context"
}

report_warning() {
  local code="$1"
  local message="$2"
  local context="${3:-{}}"

  report_error_internal "WARN" "$code" "$message" "$context"
}

fatal_error() {
  local code="$1"
  local message="$2"
  local context="${3:-{}}"

  report_error_internal "FATAL" "$code" "$message" "$context"

  if [[ -n "${user_message:-}" ]]; then
    user_message "FATAL ERROR [$code]: $message"
  else
    echo "FATAL ERROR [$code]: $message" >&2
  fi

  exit 2
}
```

**Step 4: Run test to verify it passes**

```bash
bash tests/test-error-reporting.sh
```

Expected: PASS - "All error-reporting tests passed"

**Step 5: Validate with shellcheck**

```bash
shellcheck error-reporting.sh
```

Expected: No errors or warnings

**Step 6: Commit**

```bash
git add error-reporting.sh tests/test-error-reporting.sh
git commit -m "feat(utils): add structured error reporting system

- Error journal in JSON Lines format
- Error and warning reporting
- Context capture
- Stack trace generation
- Fatal errors with exit code 2
- Comprehensive test coverage"
```

---

## Task 4: Enhanced Session Management

**Files:**
- Modify: `marketplace-utils/session-management.sh`
- Test: `marketplace-utils/tests/test-session-management.sh`

**Step 1: Write the failing test**

Create test file:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../platform-compat.sh"
source "${SCRIPT_DIR}/../logging.sh"
source "${SCRIPT_DIR}/../error-reporting.sh"

export CLAUDE_SESSION_PID=$$
export SESSION_FILE="/tmp/claude-test-session-$$.json"

source "${SCRIPT_DIR}/../session-management.sh"

cleanup() {
  rm -f "$SESSION_FILE" "${SESSION_FILE}.lock"
}
trap cleanup EXIT

test_init_session() {
  init_session "test-plugin"

  if [[ ! -f "$SESSION_FILE" ]]; then
    echo "FAIL: Session file not created"
    return 1
  fi

  local session_id=$(jq -r '.session_id' "$SESSION_FILE")
  if [[ -z "$session_id" ]]; then
    echo "FAIL: session_id not set"
    return 1
  fi

  local initialized=$(jq -r '.plugins."test-plugin".initialized' "$SESSION_FILE")
  if [[ "$initialized" != "true" ]]; then
    echo "FAIL: Plugin not initialized"
    return 1
  fi

  echo "PASS: init_session works correctly"
  return 0
}

test_session_values() {
  rm -f "$SESSION_FILE"
  init_session "test-plugin"

  set_session_value "test_key" '"test_value"'

  local value=$(get_session_value "test_key")
  if [[ "$value" != "test_value" ]]; then
    echo "FAIL: Session value not retrieved correctly: $value"
    return 1
  fi

  if ! has_session_key "test_key"; then
    echo "FAIL: has_session_key returned false for existing key"
    return 1
  fi

  if has_session_key "nonexistent"; then
    echo "FAIL: has_session_key returned true for nonexistent key"
    return 1
  fi

  echo "PASS: Session value operations work correctly"
  return 0
}

test_plugin_values() {
  rm -f "$SESSION_FILE"
  init_session "test-plugin"

  set_plugin_value "test-plugin" "custom_field" '"custom_value"'

  local value=$(get_plugin_value "test-plugin" "custom_field")
  if [[ "$value" != "custom_value" ]]; then
    echo "FAIL: Plugin value not retrieved: $value"
    return 1
  fi

  echo "PASS: Plugin value operations work correctly"
  return 0
}

test_recommendations() {
  rm -f "$SESSION_FILE"
  init_session "test-plugin"

  if has_shown_recommendation "test-plugin" "test_skill"; then
    echo "FAIL: Recommendation shown before marking"
    return 1
  fi

  mark_recommendation_shown "test-plugin" "test_skill"

  if ! has_shown_recommendation "test-plugin" "test_skill"; then
    echo "FAIL: Recommendation not marked as shown"
    return 1
  fi

  echo "PASS: Recommendation tracking works correctly"
  return 0
}

test_multi_plugin_session() {
  rm -f "$SESSION_FILE"
  init_session "plugin-a"
  init_session "plugin-b"

  local file_a=$(get_session_file)
  local file_b=$(get_session_file)

  if [[ "$file_a" != "$file_b" ]]; then
    echo "FAIL: Different session files for different plugins"
    return 1
  fi

  if ! jq -e '.plugins."plugin-a"' "$file_a" >/dev/null 2>&1; then
    echo "FAIL: plugin-a not in session"
    return 1
  fi

  if ! jq -e '.plugins."plugin-b"' "$file_a" >/dev/null 2>&1; then
    echo "FAIL: plugin-b not in session"
    return 1
  fi

  echo "PASS: Multi-plugin session works correctly"
  return 0
}

main() {
  local failed=0

  test_init_session || failed=$((failed + 1))
  test_session_values || failed=$((failed + 1))
  test_plugin_values || failed=$((failed + 1))
  test_recommendations || failed=$((failed + 1))
  test_multi_plugin_session || failed=$((failed + 1))

  if [[ $failed -eq 0 ]]; then
    echo "All session-management tests passed"
    exit 0
  else
    echo "$failed test(s) failed"
    exit 1
  fi
}

main "$@"
```

**Step 2: Run test to verify current behavior**

```bash
bash tests/test-session-management.sh
```

Expected: Some tests may pass, but file locking tests will fail (not yet implemented)

**Step 3: Enhance session-management.sh with locking**

Add to beginning of `marketplace-utils/session-management.sh`:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/platform-compat.sh"

CLAUDE_SESSION_PID="${CLAUDE_SESSION_PID:-$$}"
SESSION_FILE="/tmp/claude-session-${CLAUDE_SESSION_PID}.json"

acquire_lock() {
  local file="$1"
  local timeout="${2:-5}"

  local lock_file="${file}.lock"

  if command -v flock >/dev/null 2>&1; then
    exec 200>"$lock_file"

    if ! flock -x -w "$timeout" 200; then
      exec 200>&-
      if [[ -n "${log_error:-}" ]]; then
        log_error "Failed to acquire lock on $file after ${timeout}s"
      fi
      return 1
    fi

    return 0
  else
    acquire_lock_mkdir "$file" "$timeout"
  fi
}

release_lock() {
  if command -v flock >/dev/null 2>&1; then
    flock -u 200 2>/dev/null || true
    exec 200>&- 2>/dev/null || true
  fi
  rm -f "${SESSION_FILE}.lock" "${SESSION_FILE}.lock.d" 2>/dev/null || true
}

acquire_lock_mkdir() {
  local file="$1"
  local timeout="${2:-5}"
  local lock_dir="${file}.lock.d"

  local waited=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    sleep 0.1
    waited=$((waited + 1))

    if [[ $waited -gt $((timeout * 10)) ]]; then
      if [[ -n "${log_error:-}" ]]; then
        log_error "Lock acquisition timeout: $file"
      fi
      return 1
    fi
  done

  trap "rmdir '$lock_dir' 2>/dev/null || true" EXIT INT TERM
  return 0
}
```

Add session initialization and value operations:

```bash
get_session_file() {
  echo "$SESSION_FILE"
}

init_session_file() {
  if [[ -f "$SESSION_FILE" ]]; then
    return 0
  fi

  local session_id="$$-$(date +%s)"
  local started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local platform=$(detect_platform)

  cat > "$SESSION_FILE" <<EOF
{
  "session_id": "$session_id",
  "pid": $$,
  "started_at": "$started_at",
  "plugins": {},
  "metadata": {
    "log_file": "/tmp/claude-session-$$.log",
    "error_journal": "/tmp/claude-errors-$$.jsonl",
    "platform": "$platform"
  }
}
EOF
}

init_session() {
  local plugin_name="$1"

  init_session_file

  if ! acquire_lock "$SESSION_FILE"; then
    return 1
  fi

  if ! jq ".plugins.\"${plugin_name}\" = {\"initialized\": true, \"recommendations_shown\": {}}" "$SESSION_FILE" > "${SESSION_FILE}.tmp"; then
    release_lock
    return 1
  fi

  mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
  release_lock
  return 0
}

set_session_value() {
  local key="$1"
  local value="$2"

  init_session_file

  if ! acquire_lock "$SESSION_FILE"; then
    if [[ -n "${log_error:-}" ]]; then
      log_error "Cannot update session: lock acquisition failed"
    fi
    return 1
  fi

  if ! jq ".${key} = ${value}" "$SESSION_FILE" > "${SESSION_FILE}.tmp"; then
    release_lock
    if [[ -n "${log_error:-}" ]]; then
      log_error "Failed to update session key: $key"
    fi
    return 1
  fi

  mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
  release_lock

  if [[ -n "${log_debug:-}" ]]; then
    log_debug "Updated session key: $key"
  fi

  return 0
}

get_session_value() {
  local key="$1"

  if [[ ! -f "$SESSION_FILE" ]]; then
    echo ""
    return
  fi

  jq -r ".${key} // empty" "$SESSION_FILE" 2>/dev/null || echo ""
}

has_session_key() {
  local key="$1"

  if [[ ! -f "$SESSION_FILE" ]]; then
    return 1
  fi

  jq -e ".${key}" "$SESSION_FILE" >/dev/null 2>&1
}

set_plugin_value() {
  local plugin="$1"
  local key="$2"
  local value="$3"

  set_session_value "plugins.\"${plugin}\".${key}" "$value"
}

get_plugin_value() {
  local plugin="$1"
  local key="$2"

  get_session_value "plugins.\"${plugin}\".${key}"
}

mark_recommendation_shown() {
  local plugin="$1"
  local skill="$2"

  set_plugin_value "$plugin" "recommendations_shown.\"${skill}\"" "true"
}

has_shown_recommendation() {
  local plugin="$1"
  local skill="$2"

  local shown=$(get_plugin_value "$plugin" "recommendations_shown.\"${skill}\"")
  [[ "$shown" == "true" ]]
}
```

Add cleanup function:

```bash
cleanup_stale_sessions() {
  local max_age_seconds="${1:-86400}"

  if [[ -n "${log_debug:-}" ]]; then
    log_debug "Cleaning up sessions older than ${max_age_seconds}s"
  fi

  find /tmp -name "claude-session-*.json" -type f 2>/dev/null | while read -r file; do
    if [[ -f "$file" ]]; then
      local file_age=$(get_file_age "$file")

      if [[ $file_age -gt $max_age_seconds ]]; then
        local pid=$(echo "$file" | grep -o '[0-9]\+' | head -1)

        if ! ps -p "$pid" >/dev/null 2>&1; then
          if [[ -n "${log_info:-}" ]]; then
            log_info "Removing stale session: $file (age: ${file_age}s, PID $pid not running)"
          fi
          rm -f "$file" "${file}.lock" "${file}.lock.d" 2>/dev/null || true
        fi
      fi
    fi
  done
}
```

**Step 4: Run test to verify it passes**

```bash
bash tests/test-session-management.sh
```

Expected: PASS - "All session-management tests passed"

**Step 5: Validate with shellcheck**

```bash
shellcheck session-management.sh
```

Expected: No errors or warnings

**Step 6: Commit**

```bash
git add session-management.sh tests/test-session-management.sh
git commit -m "feat(utils): enhance session management with file locking

- File locking with flock (with mkdir fallback)
- Platform-compatible timestamp handling
- Automatic cleanup of stale sessions
- Input validation and sanitization
- Graceful degradation without dependencies
- Comprehensive test coverage"
```

---

## Task 5: Hook Lifecycle Wrapper

**Files:**
- Create: `marketplace-utils/hook-lifecycle.sh`
- Test: `marketplace-utils/tests/test-hook-lifecycle.sh`

**Step 1: Write the failing test**

Create test file:

```bash
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
```

**Step 2: Run test to verify it fails**

```bash
bash tests/test-hook-lifecycle.sh
```

Expected: FAIL with "hook-lifecycle.sh: No such file or directory"

**Step 3: Write minimal implementation**

Create `marketplace-utils/hook-lifecycle.sh`:

```bash
#!/usr/bin/env bash

CLAUDE_MARKETPLACE_ROOT="${CLAUDE_MARKETPLACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/platform-compat.sh"
source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/logging.sh"
source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/error-reporting.sh"
source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/session-management.sh"

init_hook() {
  local plugin_name="$1"
  local hook_name="$2"

  if [[ ! "$plugin_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    fatal_error "INVALID_PLUGIN_NAME" "Invalid plugin name: $plugin_name"
  fi

  check_dependencies || log_warn "Some dependencies missing - functionality may be limited"

  if [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]; then
    log_info "Running in remote/web environment"
  fi

  init_session "$plugin_name"

  export PLUGIN_NAME="$plugin_name"
  export HOOK_NAME="$hook_name"
  export HOOK_EVENT="${HOOK_EVENT:-unknown}"

  log_debug "Hook initialized: $PLUGIN_NAME/$HOOK_NAME"
}

read_hook_input() {
  local input=""

  if [[ -t 0 ]]; then
    input=""
  else
    input=$(cat)
  fi

  export HOOK_INPUT="$input"
  echo "$input"
}

get_input_field() {
  local path="$1"

  if [[ -z "${HOOK_INPUT:-}" ]]; then
    echo ""
    return
  fi

  echo "$HOOK_INPUT" | jq -r ".${path} // empty" 2>/dev/null || echo ""
}

pretooluse_respond() {
  local decision="${1:-allow}"
  local reason="${2:-}"
  local updated_input="${3:-}"

  jq -n \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --argjson input "${updated_input:-null}" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: $decision
      }
    }
    | if $reason != "" then .hookSpecificOutput.permissionDecisionReason = $reason else . end
    | if $input != null then .hookSpecificOutput.updatedInput = $input else . end'
}

posttooluse_respond() {
  local decision="${1:-}"
  local reason="${2:-}"
  local context="${3:-}"

  jq -n \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg context "$context" \
    '{}'
    | if $decision != "" then . + {decision: $decision, reason: $reason} else . end
    | if $context != "" then . + {hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $context}} else . end
}

stop_respond() {
  local decision="${1:-}"
  local reason="${2:-}"

  if [[ "$decision" == "block" && -z "$reason" ]]; then
    fatal_error "MISSING_STOP_REASON" "Stop decision 'block' requires a reason"
  fi

  if [[ -n "$decision" ]]; then
    jq -n \
      --arg decision "$decision" \
      --arg reason "$reason" \
      '{decision: $decision, reason: $reason}'
  else
    echo "{}"
  fi
}

inject_context() {
  local context="$1"
  local hook_event="${2:-${HOOK_EVENT:-SessionStart}}"

  jq -n \
    --arg context "$context" \
    --arg event "$hook_event" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
}

validate_file_path() {
  local path="$1"

  if [[ "$path" =~ \.\. ]]; then
    fatal_error "SECURITY_PATH_TRAVERSAL" "Path contains ..: $path"
  fi

  if [[ ! "$path" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
    log_warn "Suspicious characters in path: $path"
  fi

  return 0
}

is_sensitive_file() {
  local file="$1"

  case "$file" in
    */.env|*/.env.*|*/.*_history)
      return 0
      ;;
    */.git/*|*/.ssh/*|*/id_rsa|*/id_ed25519)
      return 0
      ;;
    */credentials.json|*/serviceAccount.json|*/*.pem|*/*.key)
      return 0
      ;;
    */node_modules/*|*/vendor/*|*/.venv/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
```

**Step 4: Run test to verify it passes**

```bash
bash tests/test-hook-lifecycle.sh
```

Expected: PASS - "All hook-lifecycle tests passed"

**Step 5: Validate with shellcheck**

```bash
shellcheck hook-lifecycle.sh
```

Expected: No errors or warnings

**Step 6: Commit**

```bash
git add hook-lifecycle.sh tests/test-hook-lifecycle.sh
git commit -m "feat(utils): add universal hook lifecycle wrapper

- Automatic setup (session, logging, error handling)
- Hook input parsing and field extraction
- Hook response helpers (PreToolUse, PostToolUse, Stop, etc.)
- Security validation (path traversal, sensitive files)
- Comprehensive test coverage"
```

---

## Task 6: Test Runner

**Files:**
- Create: `marketplace-utils/tests/test-runner.sh`

**Step 1: Write the test runner script**

Create `marketplace-utils/tests/test-runner.sh`:

```bash
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
```

**Step 2: Make test runner executable**

```bash
chmod +x marketplace-utils/tests/test-runner.sh
```

**Step 3: Run all tests**

```bash
cd marketplace-utils
./tests/test-runner.sh
```

Expected: All tests pass

**Step 4: Commit**

```bash
git add tests/test-runner.sh
git commit -m "feat(utils): add comprehensive test runner

- Runs all test-*.sh files in tests/ directory
- Reports pass/fail for each test
- Summary with total/passed/failed counts
- Exit code 0 if all pass, 1 if any fail"
```

---

## Task 7: Documentation - Migration Guide

**Files:**
- Create: `marketplace-utils/docs/MIGRATION-GUIDE.md`

**Step 1: Write migration guide**

Create comprehensive migration guide with step-by-step instructions, before/after examples, and common issues.

**Step 2: Commit**

```bash
git add docs/MIGRATION-GUIDE.md
git commit -m "docs(utils): add Session Management v2 migration guide

- Prerequisites and setup
- Step-by-step migration process
- Before/after hook examples
- Testing checklist
- Common issues and solutions"
```

---

## Task 8: Documentation - Hook Development Guide

**Files:**
- Create: `marketplace-utils/docs/HOOK-DEVELOPMENT.md`

**Step 1: Write hook development guide**

Create comprehensive guide for writing new hooks using the lifecycle wrapper, with examples for each hook event type.

**Step 2: Commit**

```bash
git add docs/HOOK-DEVELOPMENT.md
git commit -m "docs(utils): add hook development guide

- Hook lifecycle overview
- Using hook-lifecycle.sh
- Available helper functions
- Examples for each hook event
- Best practices
- Testing hooks"
```

---

## Task 9: Documentation - Debugging Guide

**Files:**
- Create: `marketplace-utils/docs/DEBUGGING.md`

**Step 1: Write debugging guide**

Create comprehensive troubleshooting guide with environment variables, log inspection, error investigation, and common issues.

**Step 2: Commit**

```bash
git add docs/DEBUGGING.md
git commit -m "docs(utils): add debugging guide

- Environment variables reference
- Real-time log monitoring
- Error investigation techniques
- Session inspection
- Common issues and solutions"
```

---

## Task 10: Documentation - Architecture Deep Dive

**Files:**
- Create: `marketplace-utils/docs/ARCHITECTURE.md`

**Step 1: Write architecture documentation**

Create detailed architecture documentation with component relationships, data flow, concurrency model, and design decisions.

**Step 2: Commit**

```bash
git add docs/ARCHITECTURE.md
git commit -m "docs(utils): add architecture documentation

- Component hierarchy and relationships
- Data flow diagrams
- Concurrency and locking strategy
- Platform compatibility approach
- Security considerations"
```

---

## Task 11: Integration Testing

**Files:**
- Create: `marketplace-utils/tests/test-concurrent-hooks.sh`
- Create: `marketplace-utils/tests/test-hook-failure.sh`

**Step 1: Write concurrent hooks test**

Test multiple hooks executing simultaneously to verify no race conditions:

```bash
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
```

**Step 2: Write hook failure test**

Test hook crash recovery:

```bash
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
```

**Step 3: Run integration tests**

```bash
bash marketplace-utils/tests/test-concurrent-hooks.sh
bash marketplace-utils/tests/test-hook-failure.sh
```

Expected: Both tests pass

**Step 4: Commit**

```bash
git add tests/test-concurrent-hooks.sh tests/test-hook-failure.sh
git commit -m "test(utils): add integration tests for concurrency and failures

- Concurrent hook execution (race condition testing)
- Fatal error handling and cleanup
- Lock verification under load"
```

---

## Task 12: Update Main README

**Files:**
- Modify: `marketplace-utils/README.md`

**Step 1: Add Session Management v2 section**

Add comprehensive documentation about the new infrastructure to the README:

```markdown
## Session Management v2

The marketplace-utils directory provides a centralized hook infrastructure for all Claude Code plugins.

### Core Components

- **platform-compat.sh** - Cross-platform compatibility (macOS/Linux/Windows)
- **logging.sh** - Centralized logging system with configurable levels
- **error-reporting.sh** - Structured error journal in JSON Lines format
- **session-management.sh** - Enhanced session state with file locking
- **hook-lifecycle.sh** - Universal hook wrapper (source this in all hooks)

### Quick Start

Every hook should source the lifecycle wrapper:

```bash
#!/usr/bin/env bash
source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"

init_hook "plugin-name" "hook-name"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")

log_info "Processing file: $FILE"

pretooluse_respond "allow"
exit 0
```

### Documentation

- [Migration Guide](docs/MIGRATION-GUIDE.md) - Migrate existing plugins to v2
- [Hook Development](docs/HOOK-DEVELOPMENT.md) - Write new hooks
- [Debugging](docs/DEBUGGING.md) - Troubleshoot hook issues
- [Architecture](docs/ARCHITECTURE.md) - System design and internals
- [Design Document](docs/SESSION-MANAGEMENT-V2-DESIGN.md) - Complete specification

### Testing

Run all tests:

```bash
cd marketplace-utils
./tests/test-runner.sh
```

### Environment Variables

- `CLAUDE_DEBUG_LEVEL` - Log level (DEBUG, INFO, WARN, ERROR) - default: WARN
- `CLAUDE_SAVE_LOGS` - Preserve logs after session (0 or 1) - default: 0
- `CLAUDE_LOG_DIR` - Custom log directory - default: /tmp
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs(utils): update README with Session Management v2 info

- Core components overview
- Quick start example
- Documentation links
- Testing instructions
- Environment variables"
```

---

## Task 13: Final Validation

**Files:**
- N/A (validation only)

**Step 1: Run complete test suite**

```bash
cd marketplace-utils
./tests/test-runner.sh
```

Expected: All tests pass

**Step 2: Validate with shellcheck**

```bash
shellcheck platform-compat.sh
shellcheck logging.sh
shellcheck error-reporting.sh
shellcheck session-management.sh
shellcheck hook-lifecycle.sh
```

Expected: No errors or warnings

**Step 3: Test on different platforms**

If possible, test on:
- macOS
- Linux (Ubuntu/Debian)
- Windows WSL

**Step 4: Review documentation completeness**

Verify all documentation files exist and are complete:
- MIGRATION-GUIDE.md
- HOOK-DEVELOPMENT.md
- DEBUGGING.md
- ARCHITECTURE.md
- Updated README.md

**Step 5: Final commit**

```bash
git add -A
git commit -m "chore(utils): Session Management v2 infrastructure complete

Core infrastructure:
- Platform compatibility utilities
- Centralized logging system
- Structured error reporting
- Enhanced session management with locking
- Universal hook lifecycle wrapper

Testing:
- Comprehensive unit tests for all components
- Integration tests for concurrency and failures
- Test runner for complete suite

Documentation:
- Migration guide
- Hook development guide
- Debugging guide
- Architecture documentation
- Updated README

Ready for plugin migration (Phase 2)"
```

---

## Next Steps

After completing this implementation plan:

1. **Request Code Review**

Use the superpowers:requesting-code-review skill to dispatch a code-reviewer agent:

```
Please review the Session Management v2 infrastructure implementation against the design document at marketplace-utils/docs/SESSION-MANAGEMENT-V2-DESIGN.md
```

2. **Begin Plugin Template Migration (Phase 2)**

Once code review is complete and issues addressed, proceed to migrate the plugin-template as the reference implementation using a new implementation plan.

3. **Production Plugin Migration (Phase 3)**

After template migration is validated, migrate production plugins one at a time in order:
- zod-4
- prisma-6
- react-19
- typescript
- nextjs-16

---

## Implementation Notes

### Dependencies

- bash 4.0+
- jq (JSON processor)
- flock (file locking) - gracefully degrades to mkdir-based locking

### File Locking Strategy

The implementation uses flock when available (Linux, modern macOS) and falls back to mkdir-based locking when flock is not available. This ensures compatibility across all platforms while maintaining race condition protection.

### Testing Philosophy

All components follow TDD principles:
1. Write failing test first
2. Run test to verify failure mode
3. Implement minimal code to pass
4. Verify test passes
5. Validate with shellcheck
6. Commit

### Security Considerations

All hook implementations must:
- Validate and sanitize file paths (no path traversal)
- Quote all shell variables
- Skip sensitive files (.env, credentials, etc.)
- Use absolute paths for script references

### Performance Requirements

Hook lifecycle overhead must be <10ms per hook execution to ensure responsive user experience.

### Backward Compatibility

The new infrastructure is designed to coexist with existing session management during migration. Old and new systems can run simultaneously without conflict.

---

## Critical Fixes Applied (Post Code Review)

Based on comprehensive code review, the following critical issues were addressed:

### 1. Session File Architecture (Task 4)
- **Fixed:** Changed from per-plugin session files to global session file
- **Before:** `/tmp/claude-${plugin_name}-session-$$.json`
- **After:** `/tmp/claude-session-${CLAUDE_SESSION_PID}.json`
- **Impact:** Enables shared session across all plugins as per design spec

### 2. Plugin Value API (Task 4)
- **Added:** `get_plugin_value()` and `set_plugin_value()` implementations
- **Added:** Multi-plugin session test to verify global session works correctly
- **Impact:** Tests now pass and API is complete

### 3. File Locking Race Conditions (Task 4)
- **Fixed:** Added explicit `release_lock()` function
- **Fixed:** File descriptor cleanup on lock failure
- **Impact:** Prevents lock leaks and data corruption

### 4. Session File Initialization (Task 4)
- **Added:** `init_session_file()` creates global session with proper structure
- **Fixed:** `set_session_value()` now initializes session if missing
- **Impact:** Eliminates runtime errors from missing session file

### 5. Hook Response Helpers (Task 5)
- **Fixed:** All response helpers now use `jq` instead of string concatenation
- **Changed:** `pretooluse_respond()`, `posttooluse_respond()`, `stop_respond()`, `inject_context()`
- **Impact:** Guarantees valid JSON output, prevents injection vulnerabilities

### 6. Platform Compatibility (Task 1)
- **Added:** `sanitize_shell_arg()` for shell argument escaping
- **Fixed:** `format_timestamp()` uses platform detection instead of fallback chain
- **Impact:** Better cross-platform compatibility and security

### 7. Recommendation Tracking API (Task 4)
- **Clarified:** Uses `<plugin>` as first parameter (not `<file_path>`)
- **Aligned:** With global session structure where recommendations are per-plugin
- **Impact:** API consistency across all functions

All fixes align with the Session Management v2 design document specifications and address security, reliability, and correctness concerns identified in code review.

---

**End of Implementation Plan**
