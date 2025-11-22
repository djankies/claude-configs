# Claude Code Plugin Marketplace - Session Management & Logging System v2

**Design Document**
**Version:** 2.1 (Updated for Official API Compliance)
**Date:** 2025-11-22
**Status:** Design Phase - Updated with Official Hooks API

---

## Executive Summary

Complete rebuild of the plugin hook infrastructure with centralized logging, error reporting, and session management. This migration will transform 6 plugins from duplicated, fragile session handling to a unified, debuggable, production-ready system.

### Goals

1. **Eliminate Duplication**: Replace 6 copies of session management with one shared system
2. **Enable Debugging**: Add comprehensive logging and error reporting
3. **Fix Race Conditions**: Implement proper file locking
4. **Cross-Platform Support**: Work on macOS, Linux, and Windows (WSL)
5. **Improve Reliability**: Automatic cleanup, error recovery, platform compatibility

---

## 📊 Current State Analysis

### Problems Identified

**Plugin-Level Issues:**

- 6 plugins with **duplicated session logic** (each has its own init-session.sh)
- **Inconsistent session file naming**:
  - `typescript`: `/tmp/claude-typescript-session-$$.json` ✓ (has PID)
  - `nextjs-16`: `/tmp/claude-nextjs-16-session.json` ✗ (no PID - collision risk!)
  - `zod-4`: `/tmp/claude-zod-4-session.json` ✗ (no PID)
  - `prisma-6`: Similar issues
  - `react-19`: Similar issues
- **No logging infrastructure** - hooks echo to stderr, nothing persisted
- **No error reporting** - failures are silent or confusing
- **No debugging tools** - when hooks fail, zero visibility

**Infrastructure Issues (from session-management.sh analysis):**

- **Race conditions**: No file locking - concurrent hooks can corrupt data
- **Platform incompatibility**: macOS-only date commands fail on Linux
- **No cleanup**: Files accumulate in /tmp forever
- **No recovery**: Crashes leave orphaned session files
- **Silent failures**: Errors suppressed with `2>/dev/null || echo ""`
- **PID reuse**: Theoretical collision risk with session files
- **No session persistence**: Restart = lost data
- **No multi-session awareness**: Can't detect other Claude instances

### What Works

- ✅ Hook event system (SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop, SessionEnd, PermissionRequest, Notification, PreCompact)
- ✅ JSON protocol (stdin/stdout)
- ✅ Existing utilities (json-utils.sh, frontmatter-parsing.sh)
- ✅ Plugin isolation model
- ✅ Hook matcher system (Write|Edit, etc.)

---

## 🎯 System Architecture

### Design Principles

1. **Centralization**: One implementation, used by all plugins
2. **Observability**: Everything logged, errors structured and queryable
3. **Reliability**: File locking, platform compatibility, automatic cleanup
4. **Developer Experience**: Simple hook scripts, comprehensive debugging tools
5. **Backward Compatibility**: Gradual migration, no breaking changes

### Component Hierarchy

```
marketplace-utils/
├── Core Infrastructure (NEW)
│   ├── hook-lifecycle.sh          ⭐ Master wrapper for all hooks
│   ├── session-management.sh      🔄 v2 with locking + compatibility
│   ├── logging.sh                 ⭐ Centralized logging system
│   ├── error-reporting.sh         ⭐ Structured error capture
│   └── platform-compat.sh         ⭐ macOS/Linux/Windows compatibility
├── Existing Utilities (KEEP)
│   ├── json-utils.sh              ✅ Keep + enhance
│   ├── frontmatter-parsing.sh     ✅ Keep
│   ├── file-detection.sh          ✅ Keep
│   └── skill-discovery.sh         ✅ Keep
├── Testing (NEW)
│   └── tests/
│       ├── test-session-management.sh
│       ├── test-logging.sh
│       ├── test-error-reporting.sh
│       ├── test-platform-compat.sh
│       ├── test-locking.sh
│       ├── test-hook-lifecycle.sh
│       └── test-runner.sh
└── Documentation (NEW)
    └── docs/
        ├── SESSION-MANAGEMENT-V2-DESIGN.md (this file)
        ├── MIGRATION-GUIDE.md
        ├── HOOK-DEVELOPMENT.md
        ├── DEBUGGING.md
        └── ARCHITECTURE.md
```

---

## 🔧 Core Components Design

### 1. hook-lifecycle.sh - The Universal Hook Wrapper

**Purpose**: Every hook script sources this file first. It provides complete infrastructure.

**Example Hook Using New Lifecycle:**

```bash
#!/usr/bin/env bash
# Example: check-security-patterns.sh (PreToolUse hook)

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "nextjs-16" "check-security"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")

log_debug "Checking security patterns in: $FILE"

if [[ ! -f "$FILE" ]]; then
  log_warn "File not found: $FILE"
  pretooluse_respond "allow" "File does not exist yet"
  exit 0
fi

if grep -q "'use server'" "$FILE" && ! grep -q "verifySession" "$FILE"; then
  user_message "⚠️  Server action missing verifySession()"
  user_message "   See: SECURITY-data-access-layer skill"
  report_warning "MISSING_AUTH_CHECK" "Server action without verifySession in $FILE"
fi

pretooluse_respond "allow"
exit 0
```

**Functions Provided:**

| Function                                                 | Purpose                                               |
| -------------------------------------------------------- | ----------------------------------------------------- |
| `init_hook <plugin> <hook-name>`                         | Automatic setup (session, logging, error handling)    |
| `read_hook_input()`                                      | Reads stdin, stores in variable                       |
| `get_input_field <path>`                                 | Extract from JSON (e.g., "tool_input.file_path")      |
| `pretooluse_respond <decision> [reason] [updated_input]` | PreToolUse hook response (use "allow", "deny", "ask") |
| `posttooluse_respond [decision] [reason] [context]`      | PostToolUse hook response                             |
| `stop_respond [decision] [reason]`                       | Stop/SubagentStop hook response                       |
| `inject_context <context> [hook_event]`                  | SessionStart/UserPromptSubmit context injection       |
| `log_debug/info/warn/error/fatal`                        | Logging at all levels                                 |
| `user_message <text>`                                    | Send message to user (stderr)                         |
| `report_error/warning <code> <context>`                  | Structured error reporting                            |
| `validate_file_path <path>`                              | Security validation for file paths                    |
| `is_sensitive_file <file>`                               | Check if file should be excluded                      |

**Automatic Features:**

- Session initialization (if first hook)
- Logging setup
- Error handling and capture
- Cleanup via trap handlers
- Platform compatibility checks
- Dependency validation
- Security input validation
- Remote execution detection (CLAUDE_CODE_REMOTE)

### Additional Hook Events to Support

The design currently focuses on SessionStart, PreToolUse, and PostToolUse. The following hook events should be added for comprehensive coverage:

#### SessionEnd Hook

**Purpose**: Cleanup, logging, and archiving when session terminates

**Use Cases**:

- Archive session logs to permanent storage
- Save session metrics and statistics
- Clean up temporary files
- Final state persistence

**Implementation**:

```bash
on_session_end() {
  local reason=$(get_input_field "reason")

  log_info "Session ending: $reason"

  if [[ "${CLAUDE_SAVE_LOGS:-0}" == "1" ]]; then
    archive_session_logs
  fi

  save_session_metrics
  cleanup_temp_files

  exit 0
}
```

#### PermissionRequest Hook

**Purpose**: Auto-approve or deny permission requests before user sees dialog

**Use Cases**:

- Auto-approve safe plugin operations
- Auto-deny sensitive operations
- Modify tool inputs before execution

**Implementation**:

```bash
on_permission_request() {
  local tool_name=$(get_input_field "tool_name")
  local file_path=$(get_input_field "tool_input.file_path")

  if is_plugin_tool "$tool_name"; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow"
    }
  }
}
EOF
    exit 0
  fi

  exit 0
}
```

#### Stop / SubagentStop Hooks

**Purpose**: Validate completion before allowing Claude to stop

**Use Cases**:

- Ensure all TodoWrite todos are completed
- Verify tests passed before stopping
- Check for uncommitted changes

**Implementation**:

```bash
on_stop() {
  local incomplete_todos=$(count_incomplete_todos)

  if [[ $incomplete_todos -gt 0 ]]; then
    stop_respond "block" "You have $incomplete_todos incomplete todos. Please complete or remove them before stopping."
    exit 0
  fi

  exit 0
}
```

#### Notification Hook

**Purpose**: React to Claude Code notifications

**Use Cases**:

- Desktop notifications for permission requests
- Logging notification events
- Custom alerting

**Implementation**:

```bash
on_notification() {
  local notification_type=$(get_input_field "notification_type")
  local message=$(get_input_field "message")

  case "$notification_type" in
    permission_prompt)
      send_desktop_notification "Claude Code Permission" "$message"
      ;;
    idle_prompt)
      log_info "Claude is idle: $message"
      ;;
  esac

  exit 0
}
```

#### PreCompact Hook

**Purpose**: Prepare for context compaction

**Use Cases**:

- Save important state before compact
- Notify user of compact operation
- Add context to preserve across compact

**Implementation**:

```bash
on_pre_compact() {
  local trigger=$(get_input_field "trigger")

  log_info "PreCompact triggered: $trigger"

  save_session_state
  user_message "📦 Context compaction starting..."

  exit 0
}
```

### 2. logging.sh - Centralized Logging System

**Architecture:**

```bash
# Log file per session (shared across all plugins)
LOG_FILE=/tmp/claude-session-${CLAUDE_SESSION_PID}.log

# Log format (structured, parseable)
[2025-11-22T10:30:45Z] [nextjs-16] [ERROR] [check-security] Server action missing auth

# Log levels
DEBUG   - Trace execution (only when CLAUDE_DEBUG_LEVEL=DEBUG)
INFO    - Important milestones
WARN    - Non-blocking issues
ERROR   - Failures that may impact functionality
FATAL   - Critical failures (hook cannot continue)
```

**Features:**

- **Log rotation**: Max 10MB per file, keeps last 5 files
- **Filtering**: By level, plugin, timestamp
- **Real-time tailing**: `tail -f /tmp/claude-session-$$.log`
- **Structured format**: Easy to parse with grep/awk/jq
- **Thread-safe**: Atomic appends for concurrent hooks
- **Performance**: Minimal overhead (<1ms per log line)

**Environment Controls:**

```bash
CLAUDE_DEBUG_LEVEL=DEBUG    # Show all logs (default: WARN)
CLAUDE_SAVE_LOGS=1          # Preserve logs after session ends
CLAUDE_LOG_FILE=/custom/path # Override default log location
```

**API:**

```bash
log_debug "message"         # DEBUG level
log_info "message"          # INFO level
log_warn "message"          # WARN level
log_error "message"         # ERROR level
log_fatal "message"         # FATAL level (also sends to error journal)

log_with_context "level" "message" "component"  # Advanced usage
```

**Implementation Details:**

```bash
log_message() {
  local level="$1"
  local message="$2"
  local component="${3:-${HOOK_NAME:-unknown}}"

  local min_level="${CLAUDE_DEBUG_LEVEL:-WARN}"

  if ! should_log "$level" "$min_level"; then
    return 0
  fi

  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local log_line="[$timestamp] [$PLUGIN_NAME] [$level] [$component] $message"

  echo "$log_line" >> "$LOG_FILE"
}
```

### 3. error-reporting.sh - Structured Error Capture

**Error Journal Format** (JSON Lines):

```jsonl
{"timestamp":"2025-11-22T10:30:45Z","plugin":"nextjs-16","hook":"check-security","level":"ERROR","code":"FILE_NOT_FOUND","message":"Cannot check: file.ts not found","context":{"file":"/path/to/file.ts","tool":"Write","session_id":"12345-67890"},"stack":["check_security:45","main:12"]}
{"timestamp":"2025-11-22T10:31:12Z","plugin":"typescript","hook":"check-types","level":"WARN","code":"DEPRECATED_API","message":"Using old TypeScript API","context":{"api":"findReferences","file":"utils.ts","line":"42"}}
```

**API:**

```bash
report_error <code> <message> [context_json]
report_warning <code> <message> [context_json]
fatal_error <code> <message> [context_json]  # Exits with code 2 (blocking)

get_call_stack         # Returns bash function call stack
capture_context        # Auto-captures file, tool, session info
```

**Error Codes (standardized):**

```bash
# File Operations
FILE_NOT_FOUND
FILE_NOT_READABLE
FILE_CORRUPTED

# Dependencies
DEPENDENCY_MISSING
DEPENDENCY_VERSION_MISMATCH

# Session
SESSION_NOT_INITIALIZED
SESSION_CORRUPTED
SESSION_LOCKED

# Validation
VALIDATION_FAILED
DEPRECATED_API_USAGE
SECURITY_ISSUE_DETECTED

# System
PLATFORM_NOT_SUPPORTED
DISK_FULL
TIMEOUT
```

**Error Journal Location:**

```bash
/tmp/claude-errors-${CLAUDE_SESSION_PID}.jsonl
```

**Usage Examples:**

```bash
# Simple error
report_error "file_not_found" "Config file missing: tsconfig.json"

# With context
report_error "type_check_failed" "Invalid type usage detected" \
  "$(json_object "file" "$FILE" "line" "42" "type" "any")"

# Fatal error (blocks execution, exits hook)
fatal_error "dependency_missing" "jq not installed - required for session management"

# Warning (non-blocking)
report_warning "deprecated_api" "Using deprecated findReferences API" \
  "$(json_object "api" "findReferences" "replacement" "findAllReferences")"
```

**Integration with Logging:**

```bash
report_error() {
  local code="$1"
  local message="$2"
  local context="${3:-{}}"

  # Log to error journal
  echo "$error_json" >> "$ERROR_JOURNAL"

  # Also log to main log file
  log_error "[$code] $message"

  # If CLAUDE_ERROR_TRACE=1, print stack trace
  if [[ "${CLAUDE_ERROR_TRACE:-0}" == "1" ]]; then
    log_error "Stack trace: $(get_call_stack)"
  fi
}
```

### 4. session-management.sh v2 - Enhanced Session System

**Key Improvements Over v1:**

1. **Platform-compatible date handling**
2. **File locking for race conditions**
3. **Automatic cleanup of stale sessions**
4. **Session recovery across restarts**
5. **Input validation and sanitization**
6. **Graceful degradation**

**Global Session Architecture:**

```bash
# Single session file for entire Claude Code instance
SESSION_FILE=/tmp/claude-session-${CLAUDE_SESSION_PID}.json

# Structure:
{
  "session_id": "12345-1732345678",
  "pid": 12345,
  "started_at": "2025-11-22T10:00:00Z",
  "plugins": {
    "nextjs-16": {
      "initialized": true,
      "recommendations_shown": {
        "security_skills": false,
        "caching_skills": true
      }
    },
    "typescript": {
      "initialized": true,
      "recommendations_shown": {
        "type_guards": true,
        "config_files": false
      }
    }
  },
  "metadata": {
    "log_file": "/tmp/claude-session-12345.log",
    "error_journal": "/tmp/claude-errors-12345.jsonl",
    "platform": "macos"
  }
}
```

**API:**

```bash
# Initialization
init_session <plugin_name>              # Initialize session for plugin
get_session_file                        # Get path to session file

# Data Operations
get_session_value <key>                 # Read value from session
set_session_value <key> <value>         # Write value to session
has_session_key <key>                   # Check if key exists

# Plugin-Specific State
get_plugin_value <plugin> <key>         # Read plugin-specific value
set_plugin_value <plugin> <key> <value> # Write plugin-specific value

# Recommendations
mark_recommendation_shown <file> <skill> # Mark recommendation as shown
has_shown_recommendation <file> <skill>  # Check if shown

# Session Info
get_session_age                         # Get session age in seconds
is_session_stale <max_age_seconds>      # Check if session is stale
get_session_pid                         # Get parent Claude Code PID

# Cleanup
clear_session                           # Clear current session
cleanup_stale_sessions                  # Clean up old session files
```

**Platform-Compatible Date Handling:**

```bash
get_timestamp_epoch() {
  local iso_timestamp="$1"

  case "$(detect_platform)" in
    macos)
      date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    linux)
      date -d "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    *)
      log_warn "Unknown platform, cannot parse timestamp"
      echo "0"
      ;;
  esac
}

get_session_age() {
  local started_at="$(get_session_value "started_at")"
  local started_epoch=$(get_timestamp_epoch "$started_at")
  local now_epoch=$(date "+%s")
  echo $((now_epoch - started_epoch))
}
```

**File Locking Implementation:**

```bash
acquire_lock() {
  local file="$1"
  local timeout="${2:-5}"

  local lock_file="${file}.lock"

  # Use file descriptor 200 for lock
  exec 200>"$lock_file"

  # Try to acquire exclusive lock with timeout
  if ! flock -x -w "$timeout" 200; then
    log_error "Failed to acquire lock on $file after ${timeout}s"
    return 1
  fi

  # Register cleanup on exit
  trap 'flock -u 200; rm -f "$lock_file"' EXIT INT TERM

  return 0
}

update_session_value() {
  local key="$1"
  local value="$2"

  local session_file="$(get_session_file)"

  # Acquire lock before modifying
  if ! acquire_lock "$session_file"; then
    log_error "Cannot update session: lock acquisition failed"
    return 1
  fi

  # Update JSON atomically
  if ! jq ".${key} = ${value}" "$session_file" > "${session_file}.tmp"; then
    log_error "Failed to update session key: $key"
    return 1
  fi

  mv "${session_file}.tmp" "$session_file"
  log_debug "Updated session key: $key"

  return 0
}
```

**Automatic Cleanup:**

```bash
register_cleanup_hook() {
  trap cleanup_session EXIT INT TERM
}

cleanup_session() {
  local session_file="$(get_session_file)"

  log_info "Cleaning up session: $session_file"

  # Archive logs if requested
  if [[ "${CLAUDE_SAVE_LOGS:-0}" == "1" ]]; then
    local archive_dir="$HOME/.claude/logs/$(date +%Y-%m-%d)"
    mkdir -p "$archive_dir"
    cp "$LOG_FILE" "$archive_dir/session-$$.log" 2>/dev/null || true
    cp "$ERROR_JOURNAL" "$archive_dir/errors-$$.jsonl" 2>/dev/null || true
    log_info "Logs archived to: $archive_dir"
  fi

  # Clean up session files
  rm -f "$session_file" "$session_file.lock"
  rm -f "$LOG_FILE"
  rm -f "$ERROR_JOURNAL"
}

cleanup_stale_sessions() {
  local max_age_seconds="${1:-86400}"  # Default: 24 hours

  log_debug "Cleaning up sessions older than ${max_age_seconds}s"

  find /tmp -name "claude-session-*.json" -type f 2>/dev/null | while read -r file; do
    # Check if file is older than max age
    if [[ -f "$file" ]]; then
      local file_age=$(($(date +%s) - $(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)))

      if [[ $file_age -gt $max_age_seconds ]]; then
        # Extract PID from filename
        local pid=$(echo "$file" | grep -o '[0-9]\+' | head -1)

        # Only clean up if process is not running
        if ! ps -p "$pid" >/dev/null 2>&1; then
          log_info "Removing stale session: $file (age: ${file_age}s, PID $pid not running)"
          rm -f "$file" "${file}.lock"
        fi
      fi
    fi
  done
}
```

**Input Validation:**

```bash
validate_plugin_name() {
  local name="$1"

  if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_error "Invalid plugin name: $name (must be alphanumeric with - or _)"
    return 1
  fi

  return 0
}

validate_session_key() {
  local key="$1"

  if [[ ! "$key" =~ ^[a-zA-Z0-9_\.]+$ ]]; then
    log_error "Invalid session key: $key"
    return 1
  fi

  return 0
}
```

### 5. platform-compat.sh - Cross-Platform Support

**Purpose**: Detect platform and provide compatible implementations of OS-specific commands.

**API:**

```bash
detect_platform()              # Returns: macos|linux|windows|unknown
is_remote_execution()          # Returns 0 if CLAUDE_CODE_REMOTE="true"
get_execution_environment()    # Returns: remote|local
get_timestamp_epoch <iso_ts>   # Platform-aware epoch conversion
get_current_epoch              # Current timestamp as epoch
format_timestamp <epoch>       # Format epoch as ISO-8601
check_dependencies             # Verify jq, flock, etc.
get_temp_dir                   # Platform-appropriate temp location
atomic_append <file> <content> # Platform-safe log appending
get_file_age <file>            # File age in seconds
```

**Implementation:**

```bash
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
    linux)
      date -d "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    windows)
      # WSL uses GNU date
      date -d "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    *)
      log_warn "Unknown platform, cannot convert timestamp"
      echo "0"
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

check_dependencies() {
  local missing=()

  command -v jq >/dev/null || missing+=("jq")
  command -v flock >/dev/null || missing+=("flock")

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing dependencies: ${missing[*]}"
    user_message "⚠️  WARNING: Missing required tools: ${missing[*]}"
    user_message "   Some features may not work correctly."
    user_message "   Install missing tools: brew install ${missing[*]} (macOS)"
    user_message "                      or: apt-get install ${missing[*]} (Linux)"
    return 1
  fi

  log_debug "All dependencies satisfied"
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
```

**Graceful Degradation:**

```bash
# Example: If jq is missing, fall back to basic operations
safe_json_get() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null; then
    echo "$json" | jq -r ".${key} // empty" 2>/dev/null || echo ""
  else
    log_warn "jq not available, using basic grep (limited functionality)"
    echo "$json" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | cut -d'"' -f4
  fi
}

# Example: If flock is missing, fall back to mkdir-based locking
safe_acquire_lock() {
  local file="$1"
  local timeout="${2:-5}"

  if command -v flock >/dev/null; then
    acquire_lock "$file" "$timeout"
  else
    log_warn "flock not available, using mkdir-based locking (less robust)"
    acquire_lock_mkdir "$file" "$timeout"
  fi
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
      log_error "Lock acquisition timeout: $file"
      return 1
    fi
  done

  trap "rmdir '$lock_dir' 2>/dev/null || true" EXIT INT TERM
  return 0
}
```

---

## 🔄 Hook I/O Protocol

### Channel Separation

**Critical Design Decision**: Separate logging from hook I/O protocol to prevent interference.

| Channel           | Purpose                              | Example                                    | Handler                |
| ----------------- | ------------------------------------ | ------------------------------------------ | ---------------------- |
| **stdin**         | Hook input (JSON from Claude Code)   | `{"tool_name":"Write","tool_input":{...}}` | `read_hook_input()`    |
| **stdout**        | Hook response (JSON only)            | `{"decision":"approve","continue":true}`   | `hook_respond()`       |
| **stderr**        | User messages (shown to user)        | `WARNING: Security issue detected`         | `user_message()`       |
| **Log file**      | Debug/trace/internal logs            | `[DEBUG] Checking file: app.ts`            | `log_*()` functions    |
| **Error journal** | Structured errors (machine-readable) | `{"code":"FILE_NOT_FOUND",...}`            | `report_*()` functions |

### Why This Matters

**Problem (old system):**

```bash
# Hook prints debug info to stdout
echo "Debug: checking file $FILE"  # BREAKS JSON PROTOCOL!

# Hook response
echo '{"decision":"approve"}'
```

Claude Code expects only JSON on stdout. Any other output breaks parsing.

**Solution (new system):**

```bash
# Debug info goes to log file
log_debug "Checking file: $FILE"  # ✅ Isolated

# User message goes to stderr
user_message "WARNING: Issue detected"  # ✅ User sees it

# Hook response goes to stdout
hook_respond "approve"  # ✅ Clean JSON
```

### Hook Response Format

**IMPORTANT**: Claude Code hooks API has evolved. Response format varies by hook event type.

#### Common Fields (All Hook Types)

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Optional warning/error shown to user"
}
```

#### PreToolUse Hook Response (Current API)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Explanation for decision",
    "updatedInput": {
      "field_to_modify": "new value"
    }
  },
  "suppressOutput": false
}
```

#### PostToolUse Hook Response

```json
{
  "decision": "block",
  "reason": "Explanation (required if decision is block)",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Additional information for Claude"
  }
}
```

#### Stop/SubagentStop Hook Response

```json
{
  "decision": "block",
  "reason": "Must be provided when Claude is blocked from stopping"
}
```

#### SessionStart/UserPromptSubmit Hook Response

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Context to inject into conversation"
  }
}
```

**Helper Functions:**

```bash
pretooluse_respond() {
  local decision="${1:-allow}"
  local reason="${2:-}"
  local updated_input="${3:-}"

  local output="{
    \"hookSpecificOutput\": {
      \"hookEventName\": \"PreToolUse\",
      \"permissionDecision\": \"$decision\""

  if [[ -n "$reason" ]]; then
    output+=",\"permissionDecisionReason\": \"$reason\""
  fi

  if [[ -n "$updated_input" ]]; then
    output+=",\"updatedInput\": $updated_input"
  fi

  output+="
    }
  }"

  echo "$output"
}

posttooluse_respond() {
  local decision="${1:-}"
  local reason="${2:-}"
  local context="${3:-}"

  local output="{"

  if [[ -n "$decision" ]]; then
    output+="\"decision\": \"$decision\",\"reason\": \"$reason\""
  fi

  if [[ -n "$context" ]]; then
    if [[ -n "$decision" ]]; then
      output+=","
    fi
    output+="\"hookSpecificOutput\": {
      \"hookEventName\": \"PostToolUse\",
      \"additionalContext\": \"$context\"
    }"
  fi

  output="${output%,}}"
  echo "$output"
}

stop_respond() {
  local decision="${1:-}"
  local reason="${2:-}"

  if [[ "$decision" == "block" && -z "$reason" ]]; then
    log_fatal "Stop decision 'block' requires a reason"
    exit 2
  fi

  if [[ -n "$decision" ]]; then
    cat <<EOF
{
  "decision": "$decision",
  "reason": "$reason"
}
EOF
  else
    echo "{}"
  fi
}

inject_context() {
  local context="$1"
  local hook_event="${2:-${HOOK_EVENT:-SessionStart}}"

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "$hook_event",
    "additionalContext": "$context"
  }
}
EOF
}
```

---

## 📦 Migration Strategy

### Overview

**Approach**: Incremental, backward-compatible migration with extensive testing at each stage.

**Phases**:

1. **Infrastructure** - Build new utilities (week 1)
2. **Template** - Migrate plugin-template as reference (week 1-2)
3. **Production** - Migrate 6 production plugins (week 2-3)
4. **Cleanup** - Remove old code, finalize docs (week 3)

### Phase 1: Infrastructure (Week 1)

**Objective**: Build all core utilities and prove they work.

**Tasks**:

1. Create `platform-compat.sh` (2-3 hours)

   - Platform detection
   - Date/timestamp handling
   - Dependency checking
   - File age calculation
   - Unit tests

2. Create `logging.sh` (4-5 hours)

   - Log levels and filtering
   - Structured format
   - Log rotation
   - Atomic appends
   - Unit tests

3. Create `error-reporting.sh` (4-5 hours)

   - Error journal format
   - Error codes
   - Stack trace capture
   - Context capture
   - Unit tests

4. Enhance `session-management.sh` (6-8 hours)

   - File locking
   - Platform compatibility integration
   - Input validation
   - Cleanup mechanisms
   - Unit tests

5. Create `hook-lifecycle.sh` (4-5 hours)

   - Init/cleanup hooks
   - Helper functions
   - Error handling
   - Integration tests

6. Create test suite (6-8 hours)
   - Unit tests for each component
   - Integration tests
   - Concurrency tests
   - Platform compatibility tests

**Deliverables**:

- ✅ 5 new utility files
- ✅ Comprehensive test suite
- ✅ All tests passing on macOS and Linux
- ✅ Documentation for each API

**Success Criteria**:

- All unit tests pass
- Integration tests pass
- No race conditions under concurrent load
- Works on both macOS and Linux

### Phase 2: Plugin Template Migration (Week 1-2)

**Objective**: Migrate plugin-template as the reference implementation.

**Current Template Hooks**:

- `init-session.sh` - Session initialization
- `recommend-skills.sh` - Skill recommendations
- `validate-patterns.sh` - Pattern validation

**Migration Steps**:

1. **Backup current implementation**

   ```bash
   git checkout -b migrate-template
   cp -r plugin-template/hooks/scripts plugin-template/hooks/scripts.old
   ```

2. **Migrate init-session.sh**

   - Replace with `init_hook` call
   - Test session creation
   - Verify state structure

3. **Migrate recommend-skills.sh**

   - Use `read_hook_input()` and `get_input_field()`
   - Replace manual state management with `has_shown_recommendation()`
   - Add logging
   - Test recommendation logic

4. **Migrate validate-patterns.sh**

   - Add error reporting
   - Add logging
   - Test validation logic

5. **Integration testing**

   - Test all hooks together
   - Test concurrent hook execution
   - Compare behavior before/after

6. **Documentation**
   - Document the pattern
   - Create migration guide
   - Add examples

**Deliverables**:

- ✅ Migrated plugin-template
- ✅ Integration tests passing
- ✅ Migration pattern documented
- ✅ Before/after comparison showing identical behavior

### Phase 3: Production Plugin Migration (Week 2-3)

**Migration Order** (simple to complex):

1. **Zod 4** (simplest - 3 hooks)
2. **Prisma 6** (moderate - ~4 hooks)
3. **React 19** (moderate - ~3 hooks)
4. **TypeScript** (complex - 4 hooks, heavy usage)
5. **Next.js 16** (most complex - 5 hooks, multiple checks)

**Per-Plugin Process**:

```bash
# 1. Create feature branch
git checkout -b migrate-<plugin-name>

# 2. Backup current implementation
cp -r <plugin>/hooks/scripts <plugin>/hooks/scripts.old

# 3. Migrate hooks one by one
# - Start with init-session.sh
# - Then recommendation hooks
# - Then validation hooks
# - Test each individually

# 4. Integration testing
npm run validate
./marketplace-utils/tests/test-runner.sh --plugin=<plugin-name>

# 5. Behavioral comparison
./scripts/compare-behavior.sh <plugin-name> scripts.old scripts

# 6. Commit and merge
git commit -m "migrate: <plugin-name> to session management v2"
git checkout main
git merge migrate-<plugin-name>
```

**Testing Checklist Per Plugin**:

- [ ] All hooks execute successfully
- [ ] Session state matches old format
- [ ] Recommendations show at same times
- [ ] Validations detect same issues
- [ ] No regressions in behavior
- [ ] Logs captured correctly
- [ ] Errors reported correctly
- [ ] Works on macOS and Linux

### Phase 4: Cleanup & Polish (Week 3)

**Tasks**:

1. **Remove old code**

   - Delete `*.old` backup directories
   - Remove any deprecated functions
   - Clean up test files

2. **Final documentation**

   - Complete MIGRATION-GUIDE.md
   - Complete HOOK-DEVELOPMENT.md
   - Complete DEBUGGING.md
   - Update main README

3. **Performance tuning**

   - Optimize log rotation
   - Reduce lock contention
   - Profile hook execution time

4. **User guide**
   - Write user-facing debugging guide
   - Create troubleshooting FAQ
   - Video walkthrough (optional)

**Deliverables**:

- ✅ All old code removed
- ✅ Complete documentation
- ✅ Performance optimized
- ✅ User guide published

---

## 🧪 Testing Strategy

### Test Pyramid

```
                  /\
                 /  \
                / E2E \
               /--------\
              /          \
             / Integration \
            /--------------\
           /                \
          /   Unit Tests     \
         /____________________\
```

### Unit Tests (marketplace-utils/tests/)

**test-session-management.sh**:

- Session initialization
- Get/set session values
- Plugin state management
- Recommendation tracking
- Session age calculation
- Stale session detection
- Cleanup mechanisms

**test-logging.sh**:

- Log level filtering
- Log format validation
- Log rotation
- Concurrent log writes
- Platform-specific formatting

**test-error-reporting.sh**:

- Error journal format
- Error code validation
- Context capture
- Stack trace generation
- Error level handling

**test-platform-compat.sh**:

- Platform detection
- Date/timestamp conversion (macOS vs Linux)
- File age calculation
- Dependency checking
- Graceful degradation

**test-locking.sh**:

- Lock acquisition/release
- Timeout handling
- Concurrent access
- Deadlock prevention
- Lock cleanup on crash

**test-hook-lifecycle.sh**:

- Hook initialization
- Input parsing
- Response formatting
- Cleanup on exit
- Error handling

**Test Runner**:

```bash
#!/bin/bash
# marketplace-utils/tests/test-runner.sh

run_test() {
  local test_file="$1"
  echo "Running: $test_file"

  if bash "$test_file"; then
    echo "✅ PASS: $test_file"
    return 0
  else
    echo "❌ FAIL: $test_file"
    return 1
  fi
}

main() {
  local failed=0

  for test in marketplace-utils/tests/test-*.sh; do
    if ! run_test "$test"; then
      failed=$((failed + 1))
    fi
  done

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

### Integration Tests

**test-concurrent-hooks.sh**:

- Launch multiple hooks simultaneously
- Verify no race conditions
- Check session state integrity
- Validate logs are correctly interleaved

**test-hook-failure.sh**:

- Simulate hook crashes (kill -9)
- Verify cleanup happens
- Check error reporting
- Test recovery mechanisms

**test-session-recovery.sh**:

- Kill Claude Code mid-session
- Restart with stale session files
- Verify cleanup of stale sessions
- Test session migration

**test-cross-plugin.sh**:

- Multiple plugins in one session
- Verify state isolation
- Check recommendation deduplication
- Validate shared logging

### End-to-End Tests

**test-typescript-e2e.sh**:

```bash
#!/bin/bash
# Simulate full TypeScript plugin workflow

# 1. Start session
trigger_session_start

# 2. Write TypeScript file
simulate_write_tool "src/utils.ts"

# 3. Verify hooks ran
assert_hook_executed "init-session"
assert_hook_executed "recommend-skills"
assert_hook_executed "check-type-safety"

# 4. Verify recommendations
assert_recommendation_shown "typescript_files"

# 5. Verify state
assert_session_value "plugins.typescript.initialized" "true"

# 6. End session
trigger_session_end

# 7. Verify cleanup
assert_session_files_removed
```

### Chaos Tests

**test-kill-hook.sh**:

- Kill hook mid-execution
- Verify locks released
- Verify temp files cleaned up
- Verify session recoverable

**test-corrupt-session.sh**:

- Corrupt session JSON
- Verify graceful handling
- Verify recovery or re-init
- Verify error reported

**test-disk-full.sh**:

- Simulate full /tmp filesystem
- Verify graceful degradation
- Verify error messages
- Verify recovery when space available

**test-missing-deps.sh**:

- Remove jq from PATH
- Verify fallback mechanisms
- Verify error messages
- Verify core functionality still works

### Continuous Integration

**GitHub Actions Workflow**:

```yaml
name: Test Session Management v2

on: [push, pull_request]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: brew install jq
      - name: Run tests
        run: ./marketplace-utils/tests/test-runner.sh --all

  test-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: sudo apt-get install -y jq
      - name: Run tests
        run: ./marketplace-utils/tests/test-runner.sh --all
```

---

## 🐛 Debugging Experience

### Environment Variables

```bash
# Logging
CLAUDE_DEBUG_LEVEL=DEBUG     # Show all logs (default: WARN)
CLAUDE_DEBUG_LEVEL=INFO      # Show info and above
CLAUDE_DEBUG_LEVEL=WARN      # Show warnings and errors only
CLAUDE_DEBUG_LEVEL=ERROR     # Show errors only

# Hook execution
CLAUDE_DEBUG_HOOKS=1         # Verbose hook execution trace

# Log persistence
CLAUDE_SAVE_LOGS=1           # Preserve logs after session ends
CLAUDE_LOG_DIR=/custom/path  # Custom log directory

# Error reporting
CLAUDE_ERROR_TRACE=1         # Full stack traces in errors

# Session
CLAUDE_SESSION_FILE=/path    # Override session file location
```

### Real-Time Monitoring

**View logs during development:**

```bash
# Tail all logs
tail -f /tmp/claude-session-$$.log

# Filter by level
tail -f /tmp/claude-session-$$.log | grep ERROR
tail -f /tmp/claude-session-$$.log | grep -E "ERROR|WARN"

# Filter by plugin
tail -f /tmp/claude-session-$$.log | grep "\[nextjs-16\]"

# Filter by component
tail -f /tmp/claude-session-$$.log | grep "\[check-security\]"

# Watch errors in real-time
tail -f /tmp/claude-errors-$$.jsonl | jq .

# Pretty-print error journal
tail -f /tmp/claude-errors-$$.jsonl | jq -C . | less -R
```

### Error Investigation

**View all errors from session:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "ERROR")'
```

**Errors from specific plugin:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.plugin == "typescript")'
```

**Errors with specific code:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.code == "FILE_NOT_FOUND")'
```

**Error summary:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -r '[.code] | unique[]'
```

**Errors with context:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "ERROR") | {code, message, context}'
```

### Session Inspection

**View session state:**

```bash
cat /tmp/claude-session-$$.json | jq .
```

**Check specific plugin state:**

```bash
cat /tmp/claude-session-$$.json | jq '.plugins."nextjs-16"'
```

**List all active sessions:**

```bash
ls -lh /tmp/claude-session-*.json
```

**Find stale sessions:**

```bash
find /tmp -name "claude-session-*.json" -mtime +1
```

### Debug Commands (Future Enhancement)

```bash
# View logs for current session
claude-logs [--tail] [--level=ERROR] [--plugin=nextjs-16]

# View error journal
claude-errors [--plugin=nextjs-16] [--code=FILE_NOT_FOUND]

# View session state
claude-session-info

# List all active sessions
claude-sessions

# Clean up stale sessions
claude-cleanup-sessions [--older-than=24h]
```

---

## 📅 Implementation Timeline

| Week         | Focus               | Deliverables                    | Effort |
| ------------ | ------------------- | ------------------------------- | ------ |
| **Week 1**   | Core Infrastructure | 5 utility files, unit tests     | 26-34h |
| **Week 1-2** | Plugin Template     | Reference implementation, docs  | 8-10h  |
| **Week 2**   | TypeScript Plugin   | First production migration      | 6-8h   |
| **Week 2-3** | Remaining Plugins   | All 6 plugins migrated          | 20-24h |
| **Week 3**   | Polish & Docs       | Complete documentation, cleanup | 6-8h   |

**Total Effort:** ~60-84 hours

**Timeline:** 3 weeks (part-time) or 1.5 weeks (full-time)

---

## ✅ Success Criteria

### Infrastructure Quality

- ✅ All 5 new utility files created and tested
- ✅ Unit test suite with >90% coverage
- ✅ Integration tests passing
- ✅ Cross-platform compatibility verified (macOS, Linux)
- ✅ Zero race conditions under concurrent load
- ✅ Performance acceptable (<10ms overhead per hook)

### Migration Completeness

- ✅ All 6 plugins migrated successfully:
  - plugin-template
  - typescript
  - nextjs-16
  - zod-4
  - prisma-6
  - react-19
- ✅ Zero regressions (behavior unchanged)
- ✅ All existing tests still pass
- ✅ No hardcoded session paths remain
- ✅ Old code removed

### Debugging Capability

- ✅ Logs viewable and useful for troubleshooting
- ✅ Error reports clear and actionable
- ✅ Can debug hook failures in <5 minutes
- ✅ Documentation answers 95% of questions
- ✅ Real-time monitoring works
- ✅ Error journal queryable

### Production Readiness

- ✅ Zero hook infrastructure failures in 1 month
- ✅ Developer feedback positive
- ✅ Maintenance burden reduced by >50%
- ✅ New hooks easy to create (<30 min)
- ✅ Performance meets requirements
- ✅ Graceful degradation works

### Documentation Quality

- ✅ MIGRATION-GUIDE.md complete with examples
- ✅ HOOK-DEVELOPMENT.md covers all patterns
- ✅ DEBUGGING.md solves common issues
- ✅ ARCHITECTURE.md explains system design
- ✅ API documentation for all functions
- ✅ Examples for every use case

---

## 🎯 Risk Mitigation

### Technical Risks

| Risk                              | Impact | Probability | Mitigation                                            |
| --------------------------------- | ------ | ----------- | ----------------------------------------------------- |
| Race conditions despite locking   | HIGH   | LOW         | Extensive concurrency testing, chaos testing          |
| Platform incompatibility          | HIGH   | MEDIUM      | Test on all platforms, graceful degradation           |
| Performance regression            | MEDIUM | LOW         | Benchmark before/after, optimize hot paths            |
| Breaking changes during migration | HIGH   | MEDIUM      | Incremental rollout, extensive testing, easy rollback |
| File system issues (/tmp full)    | MEDIUM | LOW         | Graceful error handling, cleanup mechanisms           |

### Process Risks

| Risk                     | Impact | Probability | Mitigation                                     |
| ------------------------ | ------ | ----------- | ---------------------------------------------- |
| Timeline overrun         | LOW    | MEDIUM      | Conservative estimates, clear phases           |
| Scope creep              | MEDIUM | MEDIUM      | Strict adherence to design, defer enhancements |
| Testing gaps             | HIGH   | LOW         | Comprehensive test plan, CI/CD integration     |
| Documentation incomplete | MEDIUM | MEDIUM      | Documentation as deliverable, not afterthought |

### Mitigation Strategies

1. **Incremental Rollout**:

   - One plugin at a time
   - Full testing between migrations
   - Easy rollback if issues found

2. **Extensive Testing**:

   - Unit, integration, E2E, chaos tests
   - Cross-platform validation
   - Before/after behavioral comparison

3. **Backward Compatibility**:

   - Keep old code during transition
   - Gradual deprecation
   - Clear migration path

4. **Monitoring & Rollback**:
   - Monitor for errors post-migration
   - Git branches for easy rollback
   - Feature flags if needed

---

## 🚀 Why This Design Works

### Centralization Benefits

**Before**: 6 copies of session management logic
**After**: 1 shared implementation

- **Reduced duplication**: ~300 lines × 6 = 1,800 lines → ~800 lines total
- **Easier maintenance**: Fix once, benefits all plugins
- **Consistency**: Same behavior across all plugins
- **Quality**: More testing on single implementation

### Observability Benefits

**Before**: No logs, silent failures, debugging impossible
**After**: Comprehensive logging and error reporting

- **Logs show exactly what's happening**: Debug hook failures in minutes
- **Errors captured with context**: Understand failures without reproduction
- **Real-time monitoring**: See issues as they happen
- **Queryable error journal**: Find patterns, track trends

### Reliability Benefits

**Before**: Race conditions, platform issues, no cleanup
**After**: File locking, platform compatibility, automatic cleanup

- **File locking prevents data corruption**: Safe concurrent execution
- **Platform compatibility eliminates Linux failures**: Works everywhere
- **Graceful degradation**: Functions even with missing dependencies
- **Automatic cleanup prevents /tmp accumulation**: No manual intervention

### Developer Experience Benefits

**Before**: Hook scripts are complex, duplicated, fragile
**After**: Hook scripts are simple, declarative, reliable

- **Boilerplate handled by lifecycle wrapper**: Focus on logic, not infrastructure
- **Clear error messages guide debugging**: Fast problem resolution
- **Comprehensive documentation**: Easy to understand and extend
- **Examples for every pattern**: Copy-paste starting points

---

## 🔒 Security Considerations

### Official Security Disclaimer

**USE AT YOUR OWN RISK**: Claude Code hooks execute arbitrary shell commands on your system automatically. By using hooks, you acknowledge that:

- You are solely responsible for the commands you configure
- Hooks can modify, delete, or access any files your user account can access
- Malicious or poorly written hooks can cause data loss or system damage
- Anthropic provides no warranty and assumes no liability for any damages resulting from hook usage
- You should thoroughly test hooks in a safe environment before production use

**Reference**: [Official Claude Code Hooks Documentation - Security Considerations](https://docs.anthropic.com/en/docs/build-with-claude/hooks-reference#security-considerations)

### Security Best Practices

The official documentation mandates these security practices:

#### 1. Validate and Sanitize Inputs

```bash
validate_file_path() {
  local path="$1"

  if [[ "$path" =~ \.\. ]]; then
    fatal_error "SECURITY_PATH_TRAVERSAL" "Path contains ..: $path"
    exit 2
  fi

  if [[ ! "$path" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
    log_warn "Suspicious characters in path: $path"
  fi

  return 0
}

validate_tool_input() {
  local input="$1"

  if [[ ! -n "$input" ]]; then
    log_error "Empty input received"
    return 1
  fi

  validate_file_path "$input"
}
```

#### 2. Always Quote Shell Variables

```bash
FILE=$(get_input_field "tool_input.file_path")

log_debug "Checking file: \"$FILE\""

if [[ -f "$FILE" ]]; then
  grep -q "pattern" "$FILE"
fi
```

**Wrong (security vulnerability):**

```bash
if [[ -f $FILE ]]; then
  grep -q "pattern" $FILE
fi
```

#### 3. Block Path Traversal

```bash
validate_file_path() {
  local path="$1"

  if [[ "$path" =~ \.\. ]]; then
    report_error "SECURITY_PATH_TRAVERSAL" "Path contains ..: $path"
    return 1
  fi

  if [[ "$path" =~ ^/ ]]; then
    if [[ ! "$path" =~ ^${CLAUDE_PROJECT_DIR} ]]; then
      report_warning "SECURITY_PATH_OUTSIDE_PROJECT" "Path outside project: $path"
    fi
  fi

  return 0
}
```

#### 4. Skip Sensitive Files

```bash
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

check_file_safety() {
  local file="$1"

  if is_sensitive_file "$file"; then
    log_warn "Skipping sensitive file: $file"
    pretooluse_respond "deny" "Skipping sensitive file for security"
    exit 0
  fi
}
```

#### 5. Use Absolute Paths

```bash
HOOK_ROOT="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_MARKETPLACE_ROOT}}"
SCRIPT_PATH="${HOOK_ROOT}/scripts/validate.sh"

if [[ -x "$SCRIPT_PATH" ]]; then
  "$SCRIPT_PATH" "$FILE"
fi
```

#### 6. Sanitize Shell Arguments

```bash
sanitize_shell_arg() {
  local arg="$1"
  printf '%q' "$arg"
}

FILE=$(get_input_field "tool_input.file_path")
SAFE_FILE=$(sanitize_shell_arg "$FILE")

log_info "Processing file: $SAFE_FILE"
```

### Implementation in Hook Lifecycle

The `hook-lifecycle.sh` file must implement these security practices automatically:

```bash
init_hook() {
  local plugin_name="$1"
  local hook_name="$2"

  validate_plugin_name "$plugin_name" || fatal_error "INVALID_PLUGIN_NAME" "Invalid plugin: $plugin_name"

  check_dependencies || log_warn "Some dependencies missing - functionality may be limited"

  if [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]; then
    log_info "Running in remote/web environment"
  fi

  init_session "$plugin_name"
  register_cleanup_hook

  export PLUGIN_NAME="$plugin_name"
  export HOOK_NAME="$hook_name"
  export HOOK_EVENT="${HOOK_EVENT:-unknown}"

  log_debug "Hook initialized: $PLUGIN_NAME/$HOOK_NAME"
}
```

### Security Checklist for Hook Development

- [ ] All file paths validated against path traversal
- [ ] All shell variables quoted with double quotes
- [ ] Sensitive files explicitly excluded
- [ ] Absolute paths used for all script references
- [ ] Shell arguments sanitized before use
- [ ] Input validation for all external data
- [ ] Error messages do not expose sensitive information
- [ ] No credentials or secrets in logs or error output
- [ ] File permissions checked before read/write operations
- [ ] Timeout limits enforced (60 seconds default)

### Configuration Safety

Per official documentation, direct edits to hooks in settings files don't take effect immediately:

1. Claude Code captures a snapshot of hooks at startup
2. Uses this snapshot throughout the session
3. Warns if hooks are modified externally
4. Requires review in `/hooks` menu for changes to apply

This prevents malicious hook modifications from affecting the current session.

---

## 📚 Documentation Deliverables

### 1. SESSION-MANAGEMENT-V2-DESIGN.md (this document)

Complete system design with architecture, components, migration plan.

### 2. MIGRATION-GUIDE.md

Step-by-step guide for migrating plugins to v2:

- Prerequisites
- Migration checklist
- Before/after examples
- Common issues and solutions
- Testing requirements

### 3. HOOK-DEVELOPMENT.md

Guide for writing new hooks:

- Hook lifecycle overview
- Using hook-lifecycle.sh
- Available helper functions
- Logging best practices
- Error reporting patterns
- Testing hooks
- Examples

### 4. DEBUGGING.md

Troubleshooting guide:

- Common issues and solutions
- How to enable debug logging
- Reading log files
- Querying error journal
- Session inspection
- Performance profiling

### 5. ARCHITECTURE.md

System architecture deep dive:

- Component relationships
- Data flow diagrams
- Concurrency model
- File locking strategy
- Platform compatibility approach
- Security considerations

---

## 🔄 Next Steps

### Immediate Actions

1. **Review and approve this design**

   - Get stakeholder feedback
   - Address any concerns
   - Finalize approach

2. **Set up development environment**

   - Create feature branch
   - Set up test infrastructure
   - Configure CI/CD

3. **Begin Phase 1: Infrastructure**

   - Start with platform-compat.sh (foundation)
   - Build logging.sh
   - Build error-reporting.sh
   - Enhance session-management.sh
   - Create hook-lifecycle.sh
   - Write unit tests

4. **Continuous validation**
   - Test each component as built
   - Integration testing
   - Cross-platform validation

### Key Decision Points

Before starting implementation, decide:

1. **Log retention policy?**

   - 24 hours? 7 days? User-configurable?
   - Archive location if CLAUDE_SAVE_LOGS=1?

2. **Error journal retention?**

   - Same as logs? Separate policy?
   - Maximum file size?

3. **Session cleanup timing?**

   - At SessionStart? Periodic background task?
   - Stale threshold (currently 24h)?

4. **Metrics/telemetry?**

   - Track hook execution times?
   - Count errors by type?
   - Optional or always-on?

5. **Debug commands?**
   - Implement `claude-logs` etc. now or later?
   - Shell scripts or integrated into Claude Code CLI?

---

## 📝 Appendix

### A. File Naming Conventions

```
/tmp/
├── claude-session-{PID}.json           # Session state
├── claude-session-{PID}.json.lock      # Session lock file
├── claude-session-{PID}.log            # Session log
├── claude-errors-{PID}.jsonl           # Error journal
└── claude-sessions-registry.json       # Multi-session registry (future)
```

### B. Environment Variables Reference

#### Official Claude Code Variables

These are provided by Claude Code and documented in official hooks documentation:

| Variable              | Default   | Description                                             | Availability          |
| --------------------- | --------- | ------------------------------------------------------- | --------------------- |
| `CLAUDE_PROJECT_DIR`  | (auto)    | Absolute path to project root directory                 | All hooks             |
| `CLAUDE_ENV_FILE`     | (auto)    | File path for persisting environment variables          | **SessionStart only** |
| `CLAUDE_CODE_REMOTE`  | (not set) | `"true"` if remote/web execution, empty if local CLI    | All hooks             |
| `CLAUDE_DEBUG_LEVEL`  | `WARN`    | Minimum log level to display (DEBUG, INFO, WARN, ERROR) | All hooks             |
| `CLAUDE_DEBUG_HOOKS`  | `0`       | Enable verbose hook execution trace                     | All hooks             |
| `CLAUDE_SAVE_LOGS`    | `0`       | Preserve logs after session ends                        | All hooks             |
| `CLAUDE_LOG_DIR`      | `/tmp`    | Directory for log files                                 | All hooks             |
| `CLAUDE_ERROR_TRACE`  | `0`       | Include stack traces in errors                          | All hooks             |
| `CLAUDE_SESSION_FILE` | (auto)    | Override session file location                          | All hooks             |

#### Plugin-Specific Variables

These are provided by Claude Code plugin system:

| Variable             | Default | Description                       | Availability |
| -------------------- | ------- | --------------------------------- | ------------ |
| `CLAUDE_PLUGIN_ROOT` | (auto)  | Absolute path to plugin directory | Plugin hooks |

#### Marketplace-Specific Variables

These are custom additions by the plugin marketplace infrastructure:

| Variable                  | Default | Description                                           | Availability          |
| ------------------------- | ------- | ----------------------------------------------------- | --------------------- |
| `CLAUDE_SESSION_PID`      | `$$`    | Parent Claude Code process PID (marketplace tracking) | All marketplace hooks |
| `CLAUDE_MARKETPLACE_ROOT` | (auto)  | Path to marketplace-utils directory                   | Marketplace hooks     |

**Important Notes:**

- `CLAUDE_ENV_FILE` is **only available for SessionStart hooks**. Do not attempt to use it in other hook types.
- `CLAUDE_CODE_REMOTE` can be used to detect execution environment and run different logic for remote vs local contexts
- Marketplace-specific variables are not part of the official Claude Code API and should be clearly documented as custom extensions

### C. Exit Code Conventions

#### General Exit Code Behavior

| Code  | Meaning            | Default Behavior                                         |
| ----- | ------------------ | -------------------------------------------------------- |
| `0`   | Success            | Continue execution, parse stdout as JSON (if valid JSON) |
| `1`   | Non-blocking error | Continue execution, show stderr in verbose mode (ctrl+o) |
| `2`   | Blocking error     | **Behavior varies by hook event** (see table below)      |
| Other | Unexpected error   | Treat as non-blocking, show stderr in verbose mode       |

#### Exit Code 2 Behavior by Hook Event

**CRITICAL**: Exit code 2 behavior differs significantly between hook events. With exit code 2, only `stderr` is used - any JSON in `stdout` is **ignored**.

| Hook Event          | Exit Code 2 Behavior           | stderr Recipient             |
| ------------------- | ------------------------------ | ---------------------------- |
| `PreToolUse`        | Blocks tool call               | Claude (as context)          |
| `PermissionRequest` | Denies permission              | Claude (as context)          |
| `PostToolUse`       | Shows error (tool already ran) | Claude (as context)          |
| `UserPromptSubmit`  | Blocks prompt, erases it       | **User only** (not Claude)   |
| `Stop`              | Blocks stoppage                | Claude (as context)          |
| `SubagentStop`      | Blocks stoppage                | Claude subagent (as context) |
| `Notification`      | N/A                            | User only (debug log)        |
| `PreCompact`        | N/A                            | User only (debug log)        |
| `SessionStart`      | N/A                            | User only (debug log)        |
| `SessionEnd`        | N/A                            | User only (debug log)        |

**Key Insights:**

- **UserPromptSubmit with exit code 2**: stderr goes to **user**, not Claude. Use JSON output with `"decision": "block"` and exit code 0 if you want to provide a custom reason to the user.
- **PreToolUse/PermissionRequest**: Exit code 2 effectively denies the action and provides feedback to Claude
- **SessionStart/SessionEnd/Notification**: Cannot be "blocked" - exit code 2 just logs to debug

#### Exit Code 0 with JSON Output

When exit code is 0, stdout is parsed as JSON. Use hook-specific JSON schemas:

- **PreToolUse**: Use `hookSpecificOutput.permissionDecision` (not deprecated `decision` field)
- **PostToolUse**: Can use `decision: "block"` to provide feedback to Claude
- **UserPromptSubmit**: Can use `decision: "block"` to block prompt, or just output plain text for context injection
- **Stop/SubagentStop**: Use `decision: "block"` to prevent stoppage
- **SessionStart**: Use `hookSpecificOutput.additionalContext` to inject context

**Best Practice**: For complex decision logic, use exit code 0 with JSON output rather than exit code 2, as JSON provides more control and structured feedback.

### D. JSON Schema for Session File

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["session_id", "pid", "started_at", "plugins", "metadata"],
  "properties": {
    "session_id": {
      "type": "string",
      "pattern": "^[0-9]+-[0-9]+$"
    },
    "pid": {
      "type": "integer"
    },
    "started_at": {
      "type": "string",
      "format": "date-time"
    },
    "plugins": {
      "type": "object",
      "patternProperties": {
        "^[a-z0-9-]+$": {
          "type": "object",
          "properties": {
            "initialized": { "type": "boolean" },
            "recommendations_shown": { "type": "object" }
          }
        }
      }
    },
    "metadata": {
      "type": "object",
      "properties": {
        "log_file": { "type": "string" },
        "error_journal": { "type": "string" },
        "platform": { "type": "string", "enum": ["macos", "linux", "windows", "unknown"] }
      }
    }
  }
}
```

### E. JSON Schema for Error Journal Entry

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["timestamp", "plugin", "hook", "level", "code", "message"],
  "properties": {
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "plugin": {
      "type": "string"
    },
    "hook": {
      "type": "string"
    },
    "level": {
      "type": "string",
      "enum": ["WARN", "ERROR", "FATAL"]
    },
    "code": {
      "type": "string",
      "pattern": "^[A-Z_]+$"
    },
    "message": {
      "type": "string"
    },
    "context": {
      "type": "object"
    },
    "stack": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
```

---

**End of Design Document**

**Version History:**

- v2.1 (2025-11-22): Updated to align with official Claude Code hooks API
  - Replaced deprecated `decision: "approve"/"block"` with `hookSpecificOutput.permissionDecision: "allow"/"deny"/"ask"`
  - Added hook-specific response helpers (pretooluse_respond, posttooluse_respond, stop_respond, inject_context)
  - Distinguished official Claude Code variables from marketplace-specific variables
  - Added comprehensive exit code behavior table per hook event type
  - Added security considerations section with official best practices
  - Added support for additional hook events (SessionEnd, PermissionRequest, Stop, SubagentStop, Notification, PreCompact)
  - Added remote execution detection (CLAUDE_CODE_REMOTE)
  - Clarified CLAUDE_ENV_FILE is SessionStart-only
  - Updated all examples to use current API
- v2.0 (2025-11-22): Initial comprehensive design
