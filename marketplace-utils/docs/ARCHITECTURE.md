# Session Management v2 Architecture

This document explains the design and implementation of the Session Management v2 system for Claude Code plugins.

## Overview

Session Management v2 provides a centralized, cross-platform infrastructure for managing state, logging, and error handling across all hooks within a Claude Code session. The system is built on Unix philosophy principles: small, composable shell scripts that do one thing well.

## Design Goals

1. **Global Session Architecture**: One session file per Claude Code session, shared across all plugins
2. **Cross-Platform**: Works on macOS, Linux, and Windows (Git Bash/WSL)
3. **Concurrency Safe**: File locking prevents race conditions
4. **Zero Dependencies**: Uses only standard bash and jq
5. **Battle-Tested Patterns**: Based on real-world usage in typescript, react-19, and review plugins

## Component Hierarchy

```
marketplace-utils/
├── platform-compat.sh       # Foundation layer
├── logging.sh               # Built on platform-compat
├── error-reporting.sh       # Built on platform-compat + logging
├── session-management.sh    # Built on platform-compat
├── hook-lifecycle.sh        # Integration layer (uses all above)
├── json-utils.sh            # Independent utility
├── file-detection.sh        # Independent utility
├── skill-discovery.sh       # Built on frontmatter-parsing
└── frontmatter-parsing.sh   # Independent utility
```

### Layer 1: Platform Foundation

**platform-compat.sh** provides cross-platform compatibility.

**Responsibilities:**
- Platform detection (macOS, Linux, Windows)
- Execution environment detection (local vs remote)
- Cross-platform timestamp handling
- Dependency checking
- Temp directory detection
- File age calculation

**Why:** Different platforms have different command syntax (e.g., `date -j` on macOS vs `date -d` on Linux). This layer abstracts those differences.

### Layer 2: Core Services

#### logging.sh

**Responsibilities:**
- Structured logging with levels (DEBUG, INFO, WARN, ERROR, FATAL)
- Thread-safe file appending with flock
- Configurable log levels via CLAUDE_DEBUG_LEVEL
- Session-scoped log files

**Design Decision:** Logs use ISO 8601 timestamps and include plugin name, hook name, and component for easy debugging.

**Concurrency:** Uses flock when available, falls back to best-effort without it.

#### error-reporting.sh

**Responsibilities:**
- Structured error journaling in JSON Lines format
- Stack trace capture
- Error codes and context
- Fatal error handling with exit codes

**Design Decision:** JSON Lines format allows streaming analysis and aggregation across multiple hooks.

**Integration:** Calls `log_error()` when available to ensure errors appear in both logs and error journal.

#### session-management.sh

**Responsibilities:**
- Session initialization and cleanup
- Thread-safe state management
- Recommendation deduplication
- Validation tracking
- Custom data storage
- Stale session cleanup

**Design Decision:** Session state is stored in `/tmp/claude-session-${PID}.json` to ensure automatic cleanup on system restart.

### Layer 3: Integration Layer

**hook-lifecycle.sh** ties everything together.

**Responsibilities:**
- Initialize all subsystems (logging, errors, session)
- Input parsing and validation
- Security checks (path traversal, sensitive files)
- Hook response formatting
- Cleanup on exit

**Why:** Every hook needs the same initialization logic. This eliminates boilerplate and ensures consistency.

### Layer 4: Specialized Utilities

#### json-utils.sh

Pure JSON manipulation without external dependencies beyond jq.

**Functions:**
- `json_escape()` - String escaping
- `json_object()` - Object construction
- `json_array()` - Array construction
- `json_merge()` - Deep merging
- `json_get()` / `json_set()` - Path-based access

#### file-detection.sh

Context-aware file type detection for smart recommendations.

**Functions:**
- File type detection (TypeScript, test, component, hook)
- Framework detection (Next.js, React, Svelte)
- Content analysis (server actions, imports)

**Design Decision:** Pattern-based detection using path and content analysis. Fast enough for hook execution without slowing down tool use.

#### skill-discovery.sh + frontmatter-parsing.sh

Skill metadata extraction for dynamic skill recommendations.

**Functions:**
- Frontmatter extraction from Markdown
- Skill discovery across plugin directories
- Tag-based skill filtering
- Review skill discovery

**Design Decision:** Skills define their metadata in frontmatter, not in plugin.json. This makes skills self-describing and easier to maintain.

## Global Session Architecture

### Why Global Sessions?

**Problem:** Early implementations used per-plugin session files, leading to:
- Recommendation duplication across plugins
- No cross-plugin coordination
- Difficult debugging (logs scattered across files)

**Solution:** One session file per Claude Code session, shared by all plugins.

### Session File Structure

```json
{
  "session_id": "12345-1732234567",
  "pid": 12345,
  "started_at": "2025-11-22T10:30:00Z",
  "plugins": {
    "typescript": {
      "plugin": "typescript",
      "started_at": "2025-11-22T10:30:01Z",
      "recommendations_shown": {
        "avoid-enum": true,
        "use-const-assertion": true
      },
      "validations_passed": {
        "tsconfig.json": {
          "strict-mode-enabled": true
        }
      },
      "custom_data": {
        "typescript_version": "5.6"
      }
    },
    "react-19": {
      "plugin": "react-19",
      "started_at": "2025-11-22T10:30:02Z",
      "recommendations_shown": {
        "use-hook-pattern": true
      },
      "validations_passed": {},
      "custom_data": {}
    }
  },
  "metadata": {
    "log_file": "/tmp/claude-session-12345.log",
    "error_journal": "/tmp/claude-errors-12345.jsonl",
    "platform": "darwin"
  }
}
```

### Session Lifecycle

```
┌─────────────────────────────────────────────────────┐
│ Claude Code Session Start                          │
│ PID: 12345                                          │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ SessionStart Hook (typescript plugin)              │
│ - init_session("typescript")                        │
│ - Creates /tmp/claude-session-12345.json            │
│ - Registers plugin in session.plugins.typescript    │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ SessionStart Hook (react-19 plugin)                │
│ - init_session("react-19")                          │
│ - Reads existing session file                       │
│ - Adds plugin to session.plugins.react-19           │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ Multiple Tool Uses                                  │
│ - PreToolUse hooks read/write session               │
│ - PostToolUse hooks update state                    │
│ - File locking prevents corruption                  │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ Session End / Process Exit                         │
│ - cleanup_session() removes temp files              │
│ - Logs preserved if CLAUDE_SAVE_LOGS=1              │
└─────────────────────────────────────────────────────┘
```

## Data Flow

### Hook Execution Flow

```
┌───────────────┐
│ Claude Code   │
│ Tool Use      │
└───────┬───────┘
        │
        │ JSON input via stdin
        ▼
┌─────────────────────────────────────────┐
│ Hook Script                             │
│ ┌─────────────────────────────────────┐ │
│ │ source hook-lifecycle.sh            │ │
│ └─────────────────────────────────────┘ │
│           │                              │
│           ▼                              │
│ ┌─────────────────────────────────────┐ │
│ │ init_hook("plugin", "hook-name")    │ │
│ │ - Loads all subsystems              │ │
│ │ - Initializes session               │ │
│ │ - Sets up logging                   │ │
│ └─────────────────────────────────────┘ │
│           │                              │
│           ▼                              │
│ ┌─────────────────────────────────────┐ │
│ │ read_hook_input()                   │ │
│ │ - Parses JSON from stdin            │ │
│ └─────────────────────────────────────┘ │
│           │                              │
│           ▼                              │
│ ┌─────────────────────────────────────┐ │
│ │ Hook Logic                          │ │
│ │ - File detection                    │ │
│ │ - Session queries                   │ │
│ │ - Skill recommendations             │ │
│ │ - Validation checks                 │ │
│ └─────────────────────────────────────┘ │
│           │                              │
│           ▼                              │
│ ┌─────────────────────────────────────┐ │
│ │ Hook Response                       │ │
│ │ - pretooluse_respond()              │ │
│ │ - posttooluse_respond()             │ │
│ │ - inject_context()                  │ │
│ └─────────────────────────────────────┘ │
└────────┬────────────────────────────────┘
         │
         │ JSON output to stdout
         ▼
┌─────────────────┐
│ Claude Code     │
│ Processes       │
│ Response        │
└─────────────────┘
```

### Session State Flow

```
┌────────────────────────────────────────────────────┐
│ Hook 1 (concurrent)                                │
│ ┌────────────────────────────────────────────────┐ │
│ │ acquire_lock(session_file, timeout=5)          │ │
│ │ - Uses flock (if available)                    │ │
│ │ - Falls back to mkdir locking                  │ │
│ └──────────────────┬─────────────────────────────┘ │
│                    │ Lock acquired                 │
│                    ▼                               │
│ ┌────────────────────────────────────────────────┐ │
│ │ Read session file                              │ │
│ │ - Parse JSON with jq                           │ │
│ └──────────────────┬─────────────────────────────┘ │
│                    ▼                               │
│ ┌────────────────────────────────────────────────┐ │
│ │ Modify state                                   │ │
│ │ - mark_recommendation_shown()                  │ │
│ │ - set_plugin_value()                           │ │
│ └──────────────────┬─────────────────────────────┘ │
│                    ▼                               │
│ ┌────────────────────────────────────────────────┐ │
│ │ Write to temp file                             │ │
│ │ - jq writes to session_file.tmp                │ │
│ └──────────────────┬─────────────────────────────┘ │
│                    ▼                               │
│ ┌────────────────────────────────────────────────┐ │
│ │ Atomic rename                                  │ │
│ │ - mv session_file.tmp session_file             │ │
│ └──────────────────┬─────────────────────────────┘ │
│                    ▼                               │
│ ┌────────────────────────────────────────────────┐ │
│ │ release_lock()                                 │ │
│ │ - flock -u or rmdir lock directory             │ │
│ └────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ Hook 2 (concurrent)                                │
│ ┌────────────────────────────────────────────────┐ │
│ │ acquire_lock(session_file, timeout=5)          │ │
│ │ - Waits for Hook 1's lock                      │ │
│ │ - Timeout after 5 seconds                      │ │
│ └──────────────────┬─────────────────────────────┘ │
│                    │ Lock acquired after wait      │
│                    ▼                               │
│                 (same flow as Hook 1)              │
└────────────────────────────────────────────────────┘
```

## Concurrency and Locking Strategy

### Why File Locking?

**Problem:** Multiple hooks can execute concurrently for different tool uses. Without locking, session file writes would corrupt each other.

**Solution:** Advisory file locking with atomic operations.

### Two-Tier Locking Strategy

#### Primary: flock-based locking

```bash
acquire_lock() {
    local file="$1"
    local timeout="${2:-5}"
    local lock_file="${file}.lock"

    LOCK_FD=200
    eval "exec $LOCK_FD>\"$lock_file\""

    if ! flock -x -w "$timeout" "$LOCK_FD" 2>/dev/null; then
        return 1
    fi

    trap "release_lock" EXIT INT TERM
    return 0
}
```

**Advantages:**
- True advisory locking
- OS-level synchronization
- Works across processes

**Limitations:**
- Not available on all platforms
- macOS uses flock from util-linux (via Homebrew)

#### Fallback: mkdir-based locking

```bash
acquire_lock_mkdir() {
    local file="$1"
    local timeout="${2:-5}"
    LOCK_DIR="${file}.lock.d"
    local waited=0

    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        sleep 0.1
        waited=$((waited + 1))

        if [[ $waited -gt $((timeout * 10)) ]]; then
            return 1
        fi
    done

    trap 'release_lock_mkdir' EXIT INT TERM
    return 0
}
```

**Advantages:**
- Works everywhere (mkdir is atomic on all POSIX systems)
- No external dependencies

**Limitations:**
- Stale locks if process dies without cleanup
- Slightly slower than flock

### Atomic Updates

Session updates use a write-then-rename pattern:

```bash
set_session_value() {
    local key="$1"
    local value="$2"
    local session_file="$(get_session_file)"

    local temp_file="${session_file}.tmp"
    jq ".${key} = ${value}" "$session_file" > "$temp_file"
    mv "$temp_file" "$session_file"
}
```

**Why:** The `mv` operation is atomic on POSIX systems. This prevents partial writes from corrupting the session file.

## Platform Compatibility

### Platform Detection

```bash
detect_platform() {
  case "$OSTYPE" in
    darwin*)  echo "macos" ;;
    linux*)   echo "linux" ;;
    msys*|cygwin*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}
```

### Cross-Platform Timestamp Handling

**Challenge:** macOS uses BSD `date`, Linux uses GNU `date`.

```bash
get_timestamp_epoch() {
  local iso_timestamp="$1"

  case "$(detect_platform)" in
    macos)
      date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_timestamp" "+%s" 2>/dev/null
      ;;
    linux|windows)
      date -d "$iso_timestamp" "+%s" 2>/dev/null
      ;;
  esac
}
```

### Remote Execution Detection

```bash
is_remote_execution() {
  [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]
}
```

**Use Case:** Claude Code can run locally or in a web/remote environment. Some features (like notifications) may behave differently.

## Security Considerations

### Path Traversal Prevention

```bash
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
```

**Protection:** Prevents hooks from accessing files outside the project directory.

### Sensitive File Detection

```bash
is_sensitive_file() {
  local file="$1"

  case "$file" in
    */.env|*/.env.*|*/.*_history) return 0 ;;
    */.git/*|*/.ssh/*|*/id_rsa|*/id_ed25519) return 0 ;;
    */credentials.json|*/serviceAccount.json|*/*.pem|*/*.key) return 0 ;;
    */node_modules/*|*/vendor/*|*/.venv/*) return 0 ;;
    *) return 1 ;;
  esac
}
```

**Protection:** Prevents hooks from processing sensitive files that shouldn't be analyzed.

### Plugin Name Validation

```bash
init_hook() {
  local plugin_name="$1"
  local hook_name="$2"

  if [[ ! "$plugin_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    fatal_error "INVALID_PLUGIN_NAME" "Invalid plugin name: $plugin_name"
  fi

  # ... rest of initialization
}
```

**Protection:** Prevents shell injection through plugin names.

### Argument Sanitization

```bash
sanitize_shell_arg() {
  local arg="$1"
  printf '%q' "$arg"
}
```

**Use Case:** When passing user input to shell commands, sanitize first to prevent command injection.

## Error Handling Philosophy

### Fail Fast

```bash
set -euo pipefail
```

All scripts use strict error handling:
- `set -e` - Exit on command failure
- `set -u` - Error on undefined variables
- `set -o pipefail` - Catch failures in pipelines

### Structured Errors

```json
{
  "timestamp": "2025-11-22T10:30:00Z",
  "plugin": "typescript",
  "hook": "pretooluse-validate",
  "level": "ERROR",
  "code": "MISSING_TSCONFIG",
  "message": "No tsconfig.json found in project root",
  "context": {
    "cwd": "/path/to/project",
    "searched_paths": [".", "src"]
  },
  "stack": ["validate_typescript:42", "main:10"]
}
```

**Benefits:**
- Machine-readable for debugging tools
- Includes context for diagnosis
- Stack traces for complex errors

### Exit Codes

- `0` - Success
- `1` - General error
- `2` - Fatal error (blocks operation in PreToolUse hooks)

## Performance Considerations

### Lazy Loading

Scripts only source dependencies when needed:

```bash
if [[ -f "$SCRIPT_DIR/frontmatter-parsing.sh" ]]; then
    source "$SCRIPT_DIR/frontmatter-parsing.sh"
fi
```

### Minimal JSON Parsing

Session reads use jq's `-r` flag to avoid unnecessary escaping:

```bash
jq -r ".${key} // empty" "$session_file"
```

### Cleanup of Stale Sessions

```bash
cleanup_stale_sessions() {
    local max_age_seconds="${1:-86400}"

    find "$temp_dir" -name "claude-session-*.json" -type f | while read -r file; do
        local file_age=$(get_file_age "$file")

        if [[ $file_age -gt $max_age_seconds ]]; then
            local pid=$(echo "$file" | grep -o '[0-9]\+' | tail -1)

            if [[ -n "$pid" ]] && ! ps -p "$pid" >/dev/null 2>&1; then
                rm -f "$file" "${file}.lock" "${file}.lock.d" 2>/dev/null
            fi
        fi
    done
}
```

**Trigger:** Run periodically or on session start to prevent /tmp bloat.

## Testing Strategy

### Unit Tests

Each component has tests in `marketplace-utils/tests/`:

```bash
tests/
├── test-session-management.sh
├── test-platform-compat.sh
├── test-file-locking.sh
├── test-logging.sh
└── test-error-reporting.sh
```

### Integration Tests

```bash
tests/integration/
├── test-concurrent-hooks.sh      # Multiple hooks writing to session
├── test-cross-plugin-session.sh  # Multiple plugins sharing session
└── test-cleanup.sh               # Session lifecycle
```

### Manual Testing

```bash
cd marketplace-utils
CLAUDE_DEBUG_LEVEL=DEBUG ./tests/test-runner.sh
```

## Future Enhancements

### Potential Improvements

1. **Session Persistence**: Optional session persistence across Claude Code restarts
2. **Session Sharing**: Share session state with Claude Code UI for richer feedback
3. **Performance Monitoring**: Track hook execution time
4. **Distributed Locking**: Support for network file systems
5. **Binary Protocol**: Faster than JSON for large sessions

### Non-Goals

1. **Database Backend**: Keep it simple with file-based storage
2. **Network Sync**: No cloud synchronization
3. **GUI**: Command-line tools only
4. **Plugin Dependencies**: Each plugin remains self-contained

## Migration Path

See [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) for step-by-step instructions on migrating existing plugins to Session Management v2.

## Related Documentation

- [Hook Development Guide](./HOOK-DEVELOPMENT.md) - Writing new hooks
- [Debugging Guide](./DEBUGGING.md) - Troubleshooting hooks
- [Session Management v2 Design](./SESSION-MANAGEMENT-V2-DESIGN.md) - Complete specification
- [Migration Guide](./MIGRATION-GUIDE.md) - Upgrading existing plugins
