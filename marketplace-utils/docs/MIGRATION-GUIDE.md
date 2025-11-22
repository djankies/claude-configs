# Session Management v2 Migration Guide

**Version:** 1.0
**Date:** 2025-11-22
**Status:** Production Ready

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Migration Process](#migration-process)
- [Before/After Examples](#beforeafter-examples)
- [Testing Checklist](#testing-checklist)
- [Common Issues](#common-issues)
- [Troubleshooting](#troubleshooting)

---

## Overview

Session Management v2 replaces plugin-specific session handling with a centralized, production-ready infrastructure that provides:

- **Unified session management** across all plugins
- **Comprehensive logging** with structured output
- **Error reporting** with queryable error journal
- **Platform compatibility** (macOS, Linux, Windows WSL)
- **File locking** to prevent race conditions
- **Automatic cleanup** of stale sessions

### What Changed

**Old System:**
- Each plugin has `init-session.sh` with duplicated logic
- Per-plugin session files: `/tmp/claude-{plugin}-session-$$.json`
- No logging infrastructure
- No error reporting
- Platform-specific date handling issues
- No file locking (race conditions possible)

**New System:**
- Global session file: `/tmp/claude-session-$$.json`
- Plugin state namespaced under `plugins.{plugin-name}`
- Centralized logging: `/tmp/claude-session-$$.log`
- Error journal: `/tmp/claude-errors-$$.jsonl`
- Platform-compatible utilities
- File locking for concurrent hooks
- Comprehensive debugging tools

---

## Prerequisites

### 1. Environment Requirements

```bash
bash --version
# Required: bash 4.0+

jq --version
# Required: jq 1.5+

flock --version
# Optional: flock (will gracefully degrade if missing)
```

**Install missing dependencies:**

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

### 2. Backup Current Implementation

Before starting migration:

```bash
cd /path/to/your-plugin

# Create feature branch
git checkout -b migrate-session-v2

# Backup existing hooks
cp -r hooks/scripts hooks/scripts.old
```

### 3. Review Design Document

Read the [Session Management v2 Design Document](./SESSION-MANAGEMENT-V2-DESIGN.md) to understand:
- Global session architecture
- Hook lifecycle wrapper
- Logging and error reporting
- Platform compatibility layer

---

## Migration Process

### Step 1: Update Session Initialization

**Old Pattern (init-session.sh):**

```bash
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="typescript"
SESSION_FILE="/tmp/claude-typescript-session-$$.json"

if [[ ! -f "$SESSION_FILE" ]]; then
  cat > "$SESSION_FILE" <<EOF
{
  "initialized": true,
  "recommendations_shown": {}
}
EOF
fi

cat <<EOF
{
  "continue": true
}
EOF
```

**New Pattern (init-session.sh):**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "typescript" "init-session"

init_session "typescript"

inject_context ""
```

**Key Changes:**
1. Source `hook-lifecycle.sh` instead of duplicating logic
2. Call `init_hook()` to set up infrastructure
3. Use `init_session()` for global session initialization
4. Use `inject_context()` for hook response

### Step 2: Update Recommendation Hooks

**Old Pattern (recommend-skills.sh):**

```bash
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="typescript"
SESSION_FILE="/tmp/claude-typescript-session-$$.json"

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/json-utils.sh"

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE" ]]; then
  echo '{"continue": true}' >&1
  exit 0
fi

if [[ ! "$FILE" =~ \.ts$ ]]; then
  echo '{"continue": true}' >&1
  exit 0
fi

KEY="recommendations_shown.typescript_files"
SHOWN=$(jq -r ".$KEY // false" "$SESSION_FILE" 2>/dev/null || echo "false")

if [[ "$SHOWN" == "true" ]]; then
  echo '{"continue": true}' >&1
  exit 0
fi

echo "💡 TypeScript files detected. Consider using:" >&2
echo "   - /typescript/skills/type-safety" >&2

TMP_FILE=$(mktemp)
jq ".$KEY = true" "$SESSION_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$SESSION_FILE"

echo '{"continue": true}' >&1
```

**New Pattern (recommend-skills.sh):**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "typescript" "recommend-skills"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")

if [[ -z "$FILE" ]]; then
  inject_context ""
  exit 0
fi

if [[ ! "$FILE" =~ \.ts$ ]]; then
  inject_context ""
  exit 0
fi

if has_shown_recommendation "typescript_files"; then
  inject_context ""
  exit 0
fi

user_message "💡 TypeScript files detected. Consider using:"
user_message "   - /typescript/skills/type-safety"

mark_recommendation_shown "typescript_files"

inject_context ""
```

**Key Changes:**
1. Use `read_hook_input()` instead of `cat`
2. Use `get_input_field()` instead of manual `jq` parsing
3. Use `has_shown_recommendation()` instead of manual session queries
4. Use `mark_recommendation_shown()` instead of manual session updates
5. Use `user_message()` for stderr output
6. Use `inject_context()` for hook response

### Step 3: Update Validation Hooks

**Old Pattern (check-types.sh - PreToolUse):**

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
  exit 0
fi

if [[ ! "$FILE" =~ \.ts$ ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
  exit 0
fi

if ! command -v tsc >/dev/null; then
  echo "⚠️  TypeScript compiler not found" >&2
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
```

**New Pattern (check-types.sh - PreToolUse):**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "typescript" "check-types"

INPUT=$(read_hook_input)
TOOL=$(get_input_field "tool_name")
FILE=$(get_input_field "tool_input.file_path")

log_debug "Tool: $TOOL, File: $FILE"

if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  pretooluse_respond "allow"
  exit 0
fi

if [[ ! "$FILE" =~ \.ts$ ]]; then
  log_debug "Not a TypeScript file, skipping"
  pretooluse_respond "allow"
  exit 0
fi

if ! command -v tsc >/dev/null; then
  log_warn "TypeScript compiler not found"
  user_message "⚠️  TypeScript compiler not found"
  report_warning "DEPENDENCY_MISSING" "tsc not installed"
  pretooluse_respond "allow"
  exit 0
fi

log_info "TypeScript file validated: $FILE"
pretooluse_respond "allow"
```

**Key Changes:**
1. Use `log_debug()`, `log_info()`, `log_warn()` for logging
2. Use `report_warning()` for structured error tracking
3. Use `pretooluse_respond()` helper instead of manual JSON
4. Add comprehensive logging for debugging

### Step 4: Update PostToolUse Hooks

**Old Pattern (post-write-check.sh):**

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ ! -f "$FILE" ]]; then
  echo '{"continue": true}' >&1
  exit 0
fi

if grep -q "console.log" "$FILE" 2>/dev/null; then
  echo "⚠️  File contains console.log statements" >&2
fi

echo '{"continue": true}' >&1
```

**New Pattern (post-write-check.sh):**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "typescript" "post-write-check"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")

log_debug "Checking file: $FILE"

if [[ ! -f "$FILE" ]]; then
  log_warn "File not found: $FILE"
  posttooluse_respond
  exit 0
fi

if grep -q "console.log" "$FILE" 2>/dev/null; then
  user_message "⚠️  File contains console.log statements"
  log_info "console.log detected in $FILE"
  report_warning "CODE_QUALITY" "console.log found in $FILE"
fi

posttooluse_respond
```

**Key Changes:**
1. Use `posttooluse_respond()` for hook response
2. Add logging for debugging
3. Use `report_warning()` for code quality issues

### Step 5: Update Stop Hooks

**Old Pattern (check-todos.sh - Stop):**

```bash
#!/usr/bin/env bash
set -euo pipefail

TODO_COUNT=$(todo-count 2>/dev/null || echo "0")

if [[ "$TODO_COUNT" -gt 0 ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "You have $TODO_COUNT incomplete todos"
}
EOF
  exit 0
fi

echo '{}' >&1
```

**New Pattern (check-todos.sh - Stop):**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "typescript" "check-todos"

TODO_COUNT=$(todo-count 2>/dev/null || echo "0")

log_debug "Checking todos: $TODO_COUNT incomplete"

if [[ "$TODO_COUNT" -gt 0 ]]; then
  log_info "Blocking stop: $TODO_COUNT todos incomplete"
  stop_respond "block" "You have $TODO_COUNT incomplete todos. Please complete or remove them before stopping."
  exit 0
fi

stop_respond
```

**Key Changes:**
1. Use `stop_respond()` helper
2. Add logging for debugging
3. Provide clear reason when blocking

---

## Before/After Examples

### Example 1: SessionStart Hook

**Before:**

```bash
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="nextjs-16"
SESSION_FILE="/tmp/claude-nextjs-16-session.json"

if [[ ! -f "$SESSION_FILE" ]]; then
  cat > "$SESSION_FILE" <<EOF
{
  "initialized": true,
  "recommendations_shown": {}
}
EOF
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ""
  }
}
EOF
```

**After:**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "nextjs-16" "init-session"

init_session "nextjs-16"

log_info "Session initialized for nextjs-16"
inject_context ""
```

### Example 2: PreToolUse Security Check

**Before:**

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE" ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
  exit 0
fi

if grep -q "'use server'" "$FILE" 2>/dev/null && ! grep -q "verifySession" "$FILE"; then
  echo "⚠️  Server action missing verifySession()" >&2
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
EOF
```

**After:**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "nextjs-16" "check-security"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")

log_debug "Security check: $FILE"

if [[ -z "$FILE" ]]; then
  pretooluse_respond "allow"
  exit 0
fi

if [[ ! -f "$FILE" ]]; then
  log_debug "File does not exist yet: $FILE"
  pretooluse_respond "allow" "File does not exist yet"
  exit 0
fi

if grep -q "'use server'" "$FILE" 2>/dev/null && ! grep -q "verifySession" "$FILE"; then
  user_message "⚠️  Server action missing verifySession()"
  user_message "   See: /nextjs-16/skills/SECURITY-data-access-layer"
  log_warn "Missing auth check in $FILE"
  report_warning "MISSING_AUTH_CHECK" "Server action without verifySession in $FILE"
fi

pretooluse_respond "allow"
```

### Example 3: PostToolUse Pattern Check

**Before:**

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

if [[ "$CONTENT" =~ useEffect ]]; then
  echo "💡 Consider React 19 alternatives to useEffect" >&2
fi

echo '{"continue": true}' >&1
```

**After:**

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${CLAUDE_MARKETPLACE_ROOT}/marketplace-utils/hook-lifecycle.sh"
init_hook "react-19" "check-patterns"

INPUT=$(read_hook_input)
FILE=$(get_input_field "tool_input.file_path")
CONTENT=$(get_input_field "tool_input.content")

log_debug "Checking patterns in: $FILE"

if [[ "$CONTENT" =~ useEffect ]]; then
  user_message "💡 Consider React 19 alternatives to useEffect"
  log_info "useEffect pattern detected in $FILE"
  mark_recommendation_shown "useEffect_alternatives"
fi

posttooluse_respond
```

---

## Testing Checklist

Use this checklist to verify migration success:

### Pre-Migration

- [ ] Current hooks working correctly
- [ ] All tests passing
- [ ] Session state documented
- [ ] Backup created (`hooks/scripts.old`)
- [ ] Feature branch created

### During Migration

- [ ] All hooks updated to use `hook-lifecycle.sh`
- [ ] No hardcoded session file paths
- [ ] All `jq` calls replaced with helper functions
- [ ] Logging added to all hooks
- [ ] Error reporting added where appropriate
- [ ] User messages use `user_message()`
- [ ] Hook responses use helper functions (`pretooluse_respond`, etc.)

### Post-Migration Testing

#### Functional Testing

- [ ] SessionStart hook initializes session correctly
- [ ] Session file created at `/tmp/claude-session-$$.json`
- [ ] Plugin state namespaced under `plugins.{plugin-name}`
- [ ] Recommendations show at same times as before
- [ ] Recommendations only show once per session
- [ ] Validation hooks detect same issues
- [ ] PreToolUse hooks allow/deny correctly
- [ ] PostToolUse hooks provide feedback
- [ ] Stop hooks block when appropriate

#### Session State Testing

```bash
# View session state
cat /tmp/claude-session-$$.json | jq .

# Expected structure:
{
  "session_id": "12345-1732345678",
  "pid": 12345,
  "started_at": "2025-11-22T10:00:00Z",
  "plugins": {
    "your-plugin": {
      "initialized": true,
      "recommendations_shown": {}
    }
  },
  "metadata": {
    "log_file": "/tmp/claude-session-12345.log",
    "error_journal": "/tmp/claude-errors-12345.jsonl",
    "platform": "macos"
  }
}
```

#### Logging Testing

```bash
# Tail logs during session
tail -f /tmp/claude-session-$$.log

# Verify log format
grep "\[your-plugin\]" /tmp/claude-session-$$.log

# Expected format:
# [2025-11-22T10:30:45Z] [your-plugin] [INFO] [hook-name] Message
```

#### Error Reporting Testing

```bash
# View error journal
cat /tmp/claude-errors-$$.jsonl | jq .

# Expected format:
{
  "timestamp": "2025-11-22T10:30:45Z",
  "plugin": "your-plugin",
  "hook": "hook-name",
  "level": "WARN",
  "code": "CODE_QUALITY",
  "message": "Issue detected",
  "context": {}
}
```

#### Platform Testing

- [ ] Works on macOS
- [ ] Works on Linux
- [ ] Date handling works correctly
- [ ] File locking works (or gracefully degrades)
- [ ] No platform-specific failures

#### Concurrency Testing

```bash
# Test concurrent hook execution
# (Simulate multiple file operations simultaneously)

# Verify no race conditions
# Session file should remain valid JSON
cat /tmp/claude-session-$$.json | jq . >/dev/null && echo "Valid JSON"

# Verify no file corruption
# Log file should have all entries
grep -c "\[your-plugin\]" /tmp/claude-session-$$.log
```

#### Cleanup Testing

- [ ] Session files cleaned up on exit
- [ ] Lock files removed
- [ ] Logs preserved if `CLAUDE_SAVE_LOGS=1`
- [ ] Stale sessions cleaned up (>24h old)

### Regression Testing

- [ ] No behavioral changes from old implementation
- [ ] All existing test cases still pass
- [ ] Same recommendations shown
- [ ] Same validations triggered
- [ ] Same user messages displayed

### Performance Testing

- [ ] Hook execution time acceptable (<100ms)
- [ ] No noticeable slowdown
- [ ] Log rotation works (at 10MB)
- [ ] Session file size reasonable (<100KB)

---

## Common Issues

### Issue 1: Session File Not Found

**Symptom:**
```
ERROR: Session file not found: /tmp/claude-session-12345.json
```

**Cause:** Session not initialized before first use

**Solution:**
```bash
# In your SessionStart hook (init-session.sh):
init_session "your-plugin"

# This creates the global session file
```

### Issue 2: jq Not Found

**Symptom:**
```
WARN: jq not available, using basic grep (limited functionality)
```

**Cause:** jq dependency not installed

**Solution:**
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq

# Or use graceful degradation (limited functionality)
```

### Issue 3: File Locking Timeout

**Symptom:**
```
ERROR: Failed to acquire lock on session file after 5s
```

**Cause:** Another hook is holding the lock

**Solution:**
```bash
# Check for stale lock files
ls -la /tmp/claude-session-*.lock

# Remove stale locks (if process not running)
rm /tmp/claude-session-*.lock

# Or wait for lock timeout (5 seconds default)
```

### Issue 4: Platform Date Errors

**Symptom:**
```
WARN: Cannot parse timestamp on this platform
```

**Cause:** Platform-specific date command differences

**Solution:**
Platform compatibility is handled automatically by `platform-compat.sh`. If you see this warning, it means your platform is not recognized. Report the issue with your `$OSTYPE` value.

### Issue 5: Recommendations Showing Every Time

**Symptom:** Recommendations appear on every file operation instead of once per session

**Cause:** Not using `has_shown_recommendation()` / `mark_recommendation_shown()`

**Solution:**
```bash
# Before showing recommendation:
if has_shown_recommendation "your_recommendation_key"; then
  inject_context ""
  exit 0
fi

# After showing recommendation:
mark_recommendation_shown "your_recommendation_key"
```

### Issue 6: Log File Growing Too Large

**Symptom:** `/tmp/claude-session-$$.log` exceeds 10MB

**Cause:** Log rotation not working

**Solution:**
Log rotation is automatic at 10MB. If you see files larger than this, check:

```bash
# Verify log file size
ls -lh /tmp/claude-session-$$.log

# Log rotation should keep last 5 files:
# claude-session-12345.log
# claude-session-12345.log.1
# claude-session-12345.log.2
# etc.
```

If rotation isn't working, check permissions on `/tmp`.

### Issue 7: Session State Lost on Restart

**Symptom:** Session state resets when Claude Code restarts

**Cause:** This is expected behavior - sessions are ephemeral

**Solution:**
Session files are intentionally temporary and stored in `/tmp`. They are cleaned up after:
- Claude Code exits normally
- 24 hours of inactivity (stale session cleanup)

If you need persistent state, consider using a different storage mechanism outside of session management.

---

## Troubleshooting

### Enable Debug Logging

```bash
export CLAUDE_DEBUG_LEVEL=DEBUG
# Restart Claude Code
```

Logs will now include DEBUG level messages:

```bash
tail -f /tmp/claude-session-$$.log | grep DEBUG
```

### View Hook Execution Trace

```bash
export CLAUDE_DEBUG_HOOKS=1
# Restart Claude Code
```

This adds verbose hook execution trace to logs.

### Preserve Logs After Session

```bash
export CLAUDE_SAVE_LOGS=1
# Logs will be archived to ~/.claude/logs/YYYY-MM-DD/
```

### View Error Journal

```bash
# All errors
cat /tmp/claude-errors-$$.jsonl | jq .

# Filter by plugin
cat /tmp/claude-errors-$$.jsonl | jq 'select(.plugin == "your-plugin")'

# Filter by error code
cat /tmp/claude-errors-$$.jsonl | jq 'select(.code == "FILE_NOT_FOUND")'

# Error summary
cat /tmp/claude-errors-$$.jsonl | jq -r '.code' | sort | uniq -c
```

### Inspect Session State

```bash
# Full session state
cat /tmp/claude-session-$$.json | jq .

# Your plugin state
cat /tmp/claude-session-$$.json | jq '.plugins."your-plugin"'

# Recommendations shown
cat /tmp/claude-session-$$.json | jq '.plugins."your-plugin".recommendations_shown'
```

### Test Hook Manually

```bash
# Create test input
cat > /tmp/test-input.json <<EOF
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/tmp/test.ts",
    "content": "console.log('test')"
  }
}
EOF

# Run hook manually
cat /tmp/test-input.json | bash hooks/scripts/your-hook.sh

# Check logs
tail -20 /tmp/claude-session-$$.log
```

### Compare Before/After Behavior

```bash
# Run old implementation
cat test-input.json | bash hooks/scripts.old/your-hook.sh > old-output.json

# Run new implementation
cat test-input.json | bash hooks/scripts/your-hook.sh > new-output.json

# Compare outputs
diff -u old-output.json new-output.json

# Should show minimal differences (e.g., only response format changes)
```

### Check for Race Conditions

```bash
# Simulate concurrent hooks
for i in {1..10}; do
  (cat test-input.json | bash hooks/scripts/your-hook.sh &)
done

# Wait for completion
wait

# Verify session file is valid
cat /tmp/claude-session-$$.json | jq . >/dev/null && echo "✅ No corruption"
```

### Verify Cleanup

```bash
# List session files before exit
ls -la /tmp/claude-session-*.json

# Exit Claude Code

# List session files after exit
ls -la /tmp/claude-session-*.json
# Should be empty (or only stale sessions from other processes)
```

---

## Next Steps

After successful migration:

1. **Remove old code:**
   ```bash
   rm -rf hooks/scripts.old
   ```

2. **Update documentation:**
   - Update plugin README with new hook behavior
   - Document any plugin-specific session state
   - Add debugging instructions

3. **Commit changes:**
   ```bash
   git add hooks/scripts
   git commit -m "migrate: upgrade to Session Management v2

   - Use centralized session management
   - Add comprehensive logging
   - Add structured error reporting
   - Improve platform compatibility
   - Add file locking for concurrent hooks"
   ```

4. **Monitor for issues:**
   - Enable `CLAUDE_SAVE_LOGS=1` for first few sessions
   - Review logs for unexpected errors
   - Monitor performance (hook execution time)
   - Check error journal for patterns

5. **Share feedback:**
   - Report any issues or edge cases
   - Suggest improvements to utilities
   - Contribute fixes upstream

---

## Additional Resources

- [Session Management v2 Design Document](./SESSION-MANAGEMENT-V2-DESIGN.md)
- [Hook Development Guide](./HOOK-DEVELOPMENT.md)
- [Debugging Guide](./DEBUGGING.md)
- [Architecture Documentation](./ARCHITECTURE.md)
- [Official Claude Code Hooks Reference](https://docs.anthropic.com/en/docs/build-with-claude/hooks-reference)

---

**Questions or Issues?**

If you encounter problems during migration:
1. Check the [Common Issues](#common-issues) section
2. Enable debug logging (`CLAUDE_DEBUG_LEVEL=DEBUG`)
3. Review error journal (`/tmp/claude-errors-$$.jsonl`)
4. Create an issue with logs and error details

---

**Migration completed successfully?** Share your experience and help improve this guide!
